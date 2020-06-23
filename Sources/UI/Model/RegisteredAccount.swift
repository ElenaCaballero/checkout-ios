import UIKit

final class RegisteredAccount {
    let apiModel: AccountRegistration
    let translation: TranslationProvider

    let networkLabel: String
    let submitButtonLabel: String
    var logo: Loadable<UIImage>?

    init(from apiModel: AccountRegistration, submitButtonLocalizationKey: String, localizeUsing localizer: TranslationProvider) {
        self.apiModel = apiModel
        self.translation = localizer

        self.networkLabel = localizer.translation(forKey: "network.label")
        self.submitButtonLabel = localizer.translation(forKey: submitButtonLocalizationKey)

        if let logoURL = apiModel.links["logo"] {
            logo = .notLoaded(logoURL)
        } else {
            logo = nil
        }
    }

}
