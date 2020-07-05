import UIKit

extension Input {
    class Network {
        let translation: TranslationProvider

        let label: String
        let logo: UIImage?
        let inputFields: [InputField]

        /// Checkboxes that must be arranged in another section (used for recurrence and registration)
        let separatedCheckboxes: [InputField]

        let submitButton: Input.Field.Button

        let switchRule: SmartSwitch.Rule?
        let networkCode: String

        init(networkCode: String, translator: TranslationProvider, label: String, logo: UIImage?, inputFields: [InputField], separatedCheckboxes: [InputField], submitButton: Field.Button, switchRule: SmartSwitch.Rule?) {
            self.networkCode = networkCode
            self.translation = translator

            self.label = label
            self.logo = logo
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
