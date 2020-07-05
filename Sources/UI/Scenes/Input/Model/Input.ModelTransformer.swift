import Foundation
import UIKit

// MARK: Constants

private struct Constant {
    static var ignoredFields: [IgnoredFields] { [
        .init(networkCode: "SEPADD", inputElementName: "bic")
    ] }

    static var registrationCheckboxLocalizationKey: String { "autoRegistrationLabel" }
    static var recurrenceCheckboxLocalizationKey: String { "allowRecurrenceLabel" }
}

// MARK: - Transformer

extension Input {
    class ModelTransformer {
        /// Transformed verification code fields.
        /// - Note: we need it to set a placeholder suffix delegate after transformation
        fileprivate(set) var verificationCodeFields = [Input.Field.VerificationCode]()
        fileprivate let inputFieldFactory = InputFieldFactory()

        init() {}
    }
}

extension Input.ModelTransformer {
    func transform(registeredAccount: RegisteredAccount) -> Input.Network {
        let logo = registeredAccount.logo?.value
        let inputElements = registeredAccount.apiModel.localizedInputElements ?? [InputElement]()

        let modelToTransform = InputFieldFactory.TransformableModel(inputElements: inputElements, networkCode: registeredAccount.apiModel.code, networkMethod: nil, translator: registeredAccount.translation)

        let inputFields = inputFieldFactory.makeInputFields(for: modelToTransform)
        self.verificationCodeFields = inputFieldFactory.verificationCodeFields

        let submitButton = Input.Field.Button(label: registeredAccount.submitButtonLabel)

        return .init(networkCode: registeredAccount.apiModel.code, translator: registeredAccount.translation, label: registeredAccount.networkLabel, logo: logo, inputFields: inputFields, separatedCheckboxes: [], submitButton: submitButton, switchRule: nil)
    }

    func transform(paymentNetwork: PaymentNetwork) -> Input.Network {
        let logo = paymentNetwork.logo?.value

        let inputElements = paymentNetwork.applicableNetwork.localizedInputElements ?? [InputElement]()

        // Input fields
        let modelToTransform = InputFieldFactory.TransformableModel(inputElements: inputElements, networkCode: paymentNetwork.applicableNetwork.code, networkMethod: paymentNetwork.applicableNetwork.method, translator: paymentNetwork.translation)
        let inputFields = inputFieldFactory.makeInputFields(for: modelToTransform)
        self.verificationCodeFields = inputFieldFactory.verificationCodeFields

        // Switch rule
        let smartSwitchRule = switchRule(forNetworkCode: paymentNetwork.applicableNetwork.code)

        // Checkboxes
        let checkboxFactory = CheckboxFactory(translator: paymentNetwork.translation)
        
        let registrationCheckbox = ApplicableNetworkCheckbox(type: .registration, requirement: paymentNetwork.applicableNetwork.registrationRequirement)
        let recurrenceCheckbox = ApplicableNetworkCheckbox(type: .recurrence, requirement: paymentNetwork.applicableNetwork.recurrenceRequirement)
        
        let checkboxes = [
            checkboxFactory.makeInternalModel(from: registrationCheckbox),
            checkboxFactory.makeInternalModel(from: recurrenceCheckbox)
            ].compactMap { $0 }

        let submitButton = Input.Field.Button(label: paymentNetwork.submitButtonLabel)

        return .init(networkCode: paymentNetwork.applicableNetwork.code, translator: paymentNetwork.translation, label: paymentNetwork.label, logo: logo, inputFields: inputFields, separatedCheckboxes: checkboxes, submitButton: submitButton, switchRule: smartSwitchRule)
    }

    // MARK: Smart Switch

    /// Get SmartSwitch rule for a network
    private func switchRule(forNetworkCode networkCode: String) -> Input.SmartSwitch.Rule? {
        do {
            let switchProvider = Input.SmartSwitch.Provider()
            return try switchProvider.getRules().first(withCode: networkCode)
        } catch {
            let internalError = InternalError(description: "Unable to decode smart switch rules: %@", objects: error)
            internalError.log()

            return nil
        }
    }
}

private class InputFieldFactory {
    /// Transformed verification code fields.
    /// - Note: we need it to set a placeholder suffix delegate after transformation
    fileprivate(set) var verificationCodeFields = [Input.Field.VerificationCode]()

    /// Used as input for `makeInputFields(for:)` method
    fileprivate struct TransformableModel {
        var inputElements: [InputElement]
        var networkCode: String
        var networkMethod: String?
        var translator: TranslationProvider
    }

    fileprivate func makeInputFields(for model: TransformableModel) -> [CellRepresentable & InputField] {
        // Get validation rules
        let validationProvider: Input.Field.Validation.Provider?

        do {
            validationProvider = try .init()
        } catch {
            if let internalError = error as? InternalError {
                internalError.log()
            } else {
                let getRulesError = InternalError(description: "Failed to get validation rules: %@", objects: error)
                getRulesError.log()
            }
            validationProvider = nil
        }

        // Transform input fields
        var inputFields = model.inputElements.compactMap { inputElement -> (InputField & CellRepresentable)? in
            for ignored in Constant.ignoredFields {
                if model.networkCode == ignored.networkCode && inputElement.name == ignored.inputElementName { return nil }
            }

            let validationRule = validationProvider?.getRule(forNetworkCode: model.networkCode, withInputElementName: inputElement.name)
            return transform(inputElement: inputElement, translateUsing: model.translator, validationRule: validationRule, networkMethod: model.networkMethod)
        }
        
        let transformationResult = ExpirationDateManager().removeExpiryFields(in: inputFields)

        // If fields have expiry month and year, replace them with expiry date
        if transformationResult.hadExpirationDate, let expiryDateElementIndex = transformationResult.removedIndexes.first {
            inputFields = transformationResult.fieldsWithoutDateElements
            let expiryDate = Input.Field.ExpiryDate(translator: model.translator)
            inputFields.insert(expiryDate, at: expiryDateElementIndex)
        }

        return inputFields
    }

    /// Transform `InputElement` to `InputField`
    private func transform(inputElement: InputElement, translateUsing translator: TranslationProvider, validationRule: Input.Field.Validation.Rule?, networkMethod: String?) -> InputField & CellRepresentable {
        switch inputElement.name {
        case "number":
            return Input.Field.AccountNumber(from: inputElement, translator: translator, validationRule: validationRule, networkMethod: networkMethod)
        case "iban":
            return Input.Field.IBAN(from: inputElement, translator: translator, validationRule: validationRule)
        case "holderName":
            return Input.Field.HolderName(from: inputElement, translator: translator, validationRule: validationRule)
        case "verificationCode":
            let field = Input.Field.VerificationCode(from: inputElement, translator: translator, validationRule: validationRule)
            verificationCodeFields.append(field)
            return field
        case "bankCode":
            return Input.Field.BankCode(from: inputElement, translator: translator, validationRule: validationRule)
        case "bic":
            return Input.Field.BIC(from: inputElement, translator: translator, validationRule: validationRule)
        default:
            return Input.Field.Generic(from: inputElement, translator: translator, validationRule: validationRule)
        }
    }
}

private struct IgnoredFields {
    let networkCode: String
    let inputElementName: String
}

// MARK: - Expiry date

private class ExpirationDateManager {
    private let expiryMonthElementName = "expiryMonth"
    private let expiryYearElementName = "expiryYear"
    
    struct RemovalResult {
        let fieldsWithoutDateElements: [InputField & CellRepresentable]
        let removedIndexes: [Int]
        
        /// Both expiration year and month were present
        let hadExpirationDate: Bool
    }

    func removeExpiryFields(in inputFields: [InputField & CellRepresentable]) -> RemovalResult {
        var hasExpiryYear = false
        var hasExpiryMonth = false
        var fieldsWithoutDateElements = [InputField & CellRepresentable]()
        var removedIndexes = [Int]()
        
        for inputElement in inputFields.enumerated() {
            switch inputElement.element.name {
            case expiryMonthElementName:
                hasExpiryMonth = true
                removedIndexes.append(inputElement.offset)
            case expiryYearElementName:
                hasExpiryYear = true
                removedIndexes.append(inputElement.offset)
            default:
                fieldsWithoutDateElements.append(inputElement.element)
            }
        }
        
        return .init(
            fieldsWithoutDateElements: fieldsWithoutDateElements,
            removedIndexes: removedIndexes,
            hadExpirationDate: hasExpiryMonth && hasExpiryYear
        )
    }
}

// MARK: - Checkboxes

/// Factory responsible for making internal model checkboxes from backend (network) models
private class CheckboxFactory {
    let translator: TranslationProvider
    
    init(translator: TranslationProvider) {
        self.translator = translator
    }
    
    func makeInternalModel(from backendCheckbox: ApplicableNetworkCheckbox) -> InputField {
        let isOn: Bool
        
        switch backendCheckbox.requirement {
        case .OPTIONAL: isOn = false
        case .OPTIONAL_PRESELECTED: isOn = true
        case .FORCED_DISPLAYED:
            let translationKey = localizationKey(for: backendCheckbox)
            return Input.Field.Label(label: translator.translation(forKey: translationKey), name: backendCheckbox.type.name, value: true.stringValue)
        case .FORCED:
            return Input.Field.Hidden(name: backendCheckbox.type.name, value: true.stringValue)
        case .NONE:
            return Input.Field.Hidden(name: backendCheckbox.type.name, value: false.stringValue)
        }

        let translationKey = localizationKey(for: backendCheckbox)
        return Input.Field.Checkbox(name: backendCheckbox.type.name, isOn: isOn, translationKey: translationKey, translator: translator)
    }
    
    /// Localization key rules are declared in [PCX-728](https://optile.atlassian.net/browse/PCX-728).
    /// - Returns: localization key, `nil` if requirement is `NONE`
    private func localizationKey(for backendCheckbox: ApplicableNetworkCheckbox) -> String {
        var localizationKey = "networks."
        
        switch backendCheckbox.type {
        case .registration: localizationKey += "registration."
        case .recurrence: localizationKey += "recurrence."
        }
        
        switch backendCheckbox.requirement {
        case .OPTIONAL, .OPTIONAL_PRESELECTED: localizationKey += "optional."
        case .FORCED, .FORCED_DISPLAYED: localizationKey += "forced."
        case .NONE:
            assertionFailure("Programmatic error, shouldn't call that function with NONE requirement type")
            return String()
        }

        localizationKey += "label"
        
        return localizationKey
    }
}

private struct ApplicableNetworkCheckbox {
    enum CheckboxType {
        case recurrence
        case registration
        
        var name: String {
            switch self {
            case .recurrence: return Input.Field.Checkbox.Constant.allowRecurrence
            case .registration: return Input.Field.Checkbox.Constant.allowRegistration
            }
        }
    }

    let type: CheckboxType
    let requirement: ApplicableNetwork.Requirement

    init(type: ApplicableNetworkCheckbox.CheckboxType, requirement: ApplicableNetwork.Requirement?) {
        self.type = type
        self.requirement = requirement ?? .NONE
    }
}
