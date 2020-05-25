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
        let logoData = registeredAccount.logo?.value
        let inputElements = registeredAccount.apiModel.localizedInputElements ?? [InputElement]()

        let modelToTransform = InputFieldFactory.TransformableModel(inputElements: inputElements, networkCode: registeredAccount.apiModel.code, networkMethod: nil, translator: registeredAccount.translation)

        let inputFields = inputFieldFactory.makeInputFields(for: modelToTransform)
        self.verificationCodeFields = inputFieldFactory.verificationCodeFields

        let submitButton = Input.Field.Button(label: registeredAccount.submitButtonLabel)

        return .init(networkCode: registeredAccount.apiModel.code, translator: registeredAccount.translation, label: registeredAccount.networkLabel, logoData: logoData, inputFields: inputFields, separatedCheckboxes: [], submitButton: submitButton, switchRule: nil)
    }

    func transform(paymentNetwork: PaymentNetwork) -> Input.Network {
        let logoData = paymentNetwork.logo?.value

        let inputElements = paymentNetwork.applicableNetwork.localizedInputElements ?? [InputElement]()

        // Input fields
        let modelToTransform = InputFieldFactory.TransformableModel(inputElements: inputElements, networkCode: paymentNetwork.applicableNetwork.code, networkMethod: paymentNetwork.applicableNetwork.method, translator: paymentNetwork.translation)
        let inputFields = inputFieldFactory.makeInputFields(for: modelToTransform)
        self.verificationCodeFields = inputFieldFactory.verificationCodeFields

        // Switch rule
        let smartSwitchRule = switchRule(forNetworkCode: paymentNetwork.applicableNetwork.code)

        // Checkboxes
        let checkboxes = [
            checkbox(translationKey: Constant.registrationCheckboxLocalizationKey, requirement: paymentNetwork.applicableNetwork.registrationRequirement, translator: paymentNetwork.translation),
            checkbox(translationKey: Constant.recurrenceCheckboxLocalizationKey, requirement: paymentNetwork.applicableNetwork.recurrenceRequirement, translator: paymentNetwork.translation)
            ].compactMap { $0 }

        let submitButton = Input.Field.Button(label: paymentNetwork.submitButtonLabel)

        return .init(networkCode: paymentNetwork.applicableNetwork.code, translator: paymentNetwork.translation, label: paymentNetwork.label, logoData: logoData, inputFields: inputFields, separatedCheckboxes: checkboxes, submitButton: submitButton, switchRule: smartSwitchRule)
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

    // MARK: Checkboxes

    private func checkbox(translationKey: String, requirement: ApplicableNetwork.Requirement?, translator: TranslationProvider) -> Input.Field.Checkbox? {
        let isOn: Bool
        let isEnabled: Bool = true
        var isHidden: Bool = false

        switch requirement {
        case .OPTIONAL: isOn = false
        case .OPTIONAL_PRESELECTED: isOn = true
        case .FORCED, .FORCED_DISPLAYED:
            isOn = true
            isHidden = true
        default:
            return nil
        }

        return Input.Field.Checkbox(isOn: isOn, isEnabled: isEnabled, isHidden: isHidden, translationKey: translationKey, translator: translator)
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
        let inputFields = model.inputElements.compactMap { inputElement -> (InputField & CellRepresentable)? in
            for ignored in Constant.ignoredFields {
                if model.networkCode == ignored.networkCode && inputElement.name == ignored.inputElementName { return nil }
            }

            let validationRule = validationProvider?.getRule(forNetworkCode: model.networkCode, withInputElementName: inputElement.name)
            return transform(inputElement: inputElement, translateUsing: model.translator, validationRule: validationRule, networkMethod: model.networkMethod)
        }
        
        let tuple = removeExpiryFields(in: inputFields)
        var inputElements = tuple.sequence

        // If tuple contains indexes of removed expiration month & year, insert expiry date on that index
        if let expiryDateElementIndex = tuple.removedIndexes.first {
            let expiryDate = Input.Field.ExpiryDate(translator: model.translator)
            inputElements.insert(expiryDate, at: expiryDateElementIndex)
        }

        return inputElements
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

private extension InputFieldFactory {
    private var expiryMonthElementName: String { return "expiryMonth" }
    private var expiryYearElementName: String { return "expiryYear" }
    
    /// - Returns: tuple containing sequence without expiry fields and positions of removed elements
    func removeExpiryFields(in inputFields: [InputField & CellRepresentable]) -> (sequence: [InputField & CellRepresentable], removedIndexes: [Int]) {
        var sequenceWithoutExpiryFields = [InputField & CellRepresentable]()
        var removedIndexes = [Int]()
        
        for inputElement in inputFields.enumerated() {
            let name = inputElement.element.name
            if name == expiryMonthElementName || name == expiryYearElementName {
                removedIndexes.append(inputElement.offset)
                continue
            }
            
            sequenceWithoutExpiryFields.append(inputElement.element)
        }
        
        return (sequenceWithoutExpiryFields, removedIndexes)
    }
}
