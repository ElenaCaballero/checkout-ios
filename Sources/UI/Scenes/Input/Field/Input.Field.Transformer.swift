import Foundation
import UIKit

extension Input.Field {
    class Transformer {
        /// Transformed verification code fields.
        /// - Note: we need it to set a placholder suffix delegate after transformation
        fileprivate(set) var verificationCodeFields = [Input.Field.VerificationCode]()
        fileprivate var expiryMonth: ExpiryMonth?
        fileprivate var expiryYear: ExpiryYear?
        
        init() {}
    }
}

extension Input.Field.Transformer {
    private var ignoredFields: [IgnoredFields] {[
        .init(networkCode: "SEPADD", inputElementName: "bic")
    ]}
    
    func transform(registeredAccount: RegisteredAccount) -> Input.Network {
        let logoData = registeredAccount.logo?.value
        let inputElements = registeredAccount.apiModel.localizedInputElements ?? [InputElement]()
        return transform(logoData: logoData, inputElements: inputElements, networkCode: registeredAccount.apiModel.code, networkMethod: nil, label: registeredAccount.networkLabel, translator: registeredAccount.translation)
    }
    
    func transform(paymentNetwork: PaymentNetwork) -> Input.Network {
        let logoData: Data?
        
        // FIXME: Use refactored method
        // Was loading started? Was loading completed? Was it completed successfully?
        if case let .some(.loaded(.success(imageData))) = paymentNetwork.logo {
            logoData = imageData
        } else {
            logoData = nil
        }
        
        let inputElements = paymentNetwork.applicableNetwork.localizedInputElements ?? [InputElement]()
        
        return transform(logoData: logoData, inputElements: inputElements, networkCode: paymentNetwork.applicableNetwork.code, networkMethod: paymentNetwork.applicableNetwork.method, label: paymentNetwork.label, translator: paymentNetwork.translation)
    }
    
    /// Transform `PaymentNetwork` to `Input.Network`
    private func transform(logoData: Data?, inputElements: [InputElement], networkCode: String, networkMethod: String?, label: String, translator: TranslationProvider) -> Input.Network {
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
        let inputFields = inputElements.compactMap { inputElement -> (InputField & CellRepresentable)? in
            for ignored in ignoredFields {
                if networkCode == ignored.networkCode && inputElement.name == ignored.inputElementName { return nil }
            }
            
            let validationRule = validationProvider?.getRule(forNetworkCode: networkCode, withInputElementName: inputElement.name)
            
            return transform(inputElement: inputElement, translateUsing: translator, validationRule: validationRule, networkMethod: networkMethod)
        }
        
        // Link month and year fields
        expiryYear?.expiryMonthField = expiryMonth
        expiryMonth?.expiryYearField = expiryYear

        // Get SmartSwitch rules for a network
        let switchRule: Input.SmartSwitch.Rule?
        do {
            let switchProvider = Input.SmartSwitch.Provider()
            switchRule = try switchProvider.getRules().first(withCode: networkCode)
        } catch {
            let internalError = InternalError(description: "Unable to decode smart switch rules: %@", objects: error)
            internalError.log()
            
            switchRule = nil
        }
        
        return .init(
            networkCode: networkCode,
            translator: translator,
            label: label,
            logoData: logoData,
            inputFields: inputFields,
            switchRule: switchRule
        )
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
        case "expiryMonth":
            let field = Input.Field.ExpiryMonth(from: inputElement, translator: translator)
            self.expiryMonth = field
            return field
        case "expiryYear":
            let field = Input.Field.ExpiryYear(from: inputElement, translator: translator)
            self.expiryYear = field
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

extension Input.Field.Transformer {
    fileprivate struct IgnoredFields {
        let networkCode: String
        let inputElementName: String
    }
}
