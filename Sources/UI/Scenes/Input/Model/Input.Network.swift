import Foundation

extension Input {
    class Network {
        let operationURL: URL
        
        /// Indicates payment method this network belongs to.
        let paymentMethod: String?
        
        let translation: TranslationProvider

        let label: String
        let logoData: Data?
        let inputFields: [InputField]

        /// Checkboxes that must be arranged in another section (used for recurrence and registration)
        let separatedCheckboxes: [InputField]

        let submitButton: Input.Field.Button

        let switchRule: SmartSwitch.Rule?
        let networkCode: String

        init(operationURL: URL, paymentMethod: String?, networkCode: String, translator: TranslationProvider, label: String, logoData: Data?, inputFields: [InputField & CellRepresentable], separatedCheckboxes: [InputField], submitButton: Field.Button, switchRule: SmartSwitch.Rule?) {
            self.operationURL = operationURL
            self.paymentMethod = paymentMethod
            
            self.networkCode = networkCode
            self.translation = translator

            self.label = label
            self.logoData = logoData
            self.inputFields = inputFields
            self.separatedCheckboxes = separatedCheckboxes
            self.submitButton = submitButton
            self.switchRule = switchRule
        }
    }
}

extension Input.Network: Equatable {
    static func == (lhs: Input.Network, rhs: Input.Network) -> Bool {
        return (lhs.networkCode == rhs.networkCode) && (lhs.label == rhs.label)
    }
}

#if canImport(UIKit)
import UIKit

extension Input.Network {
    var logo: UIImage? {
        guard let data = self.logoData else { return nil }
        return UIImage(data: data)
    }
}
#endif
