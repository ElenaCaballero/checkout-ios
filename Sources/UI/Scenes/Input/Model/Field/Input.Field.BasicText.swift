import Foundation

extension Input.Field {
    /// Abstract class for most text fields.
    /// - Note: We need a separate abstract class to make subclasses' protocol extensions work (that's why that class doesn't implement any input field protocols).
    class BasicText: InputElementModel {
        let inputElement: InputElement

        let translator: TranslationProvider

        let validationRule: Validation.Rule?
        var validationErrorText: String?

        var isEnabled: Bool = true
        var value: String = ""

        init(from inputElement: InputElement, translator: TranslationProvider, validationRule: Validation.Rule?) {
            self.inputElement = inputElement
            self.translator = translator
            self.validationRule = validationRule
        }
    }
}
