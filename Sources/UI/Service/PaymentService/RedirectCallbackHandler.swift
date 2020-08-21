import Foundation

private extension String {
    static var interactionCodeKey: String { "interactionCode" }
    static var interactionReasonKey: String { "interactionReason" }
}

class RedirectCallbackHandler {
    weak var delegate: PaymentServiceDelegate?
    
    func subscribeForNotification() {
        var receivePaymentNotificationToken: NSObjectProtocol?
        receivePaymentNotificationToken = NotificationCenter.default.addObserver(forName: .didReceivePaymentResultURL, object: nil, queue: .main) { notification in
            guard let url = notification.object as? URL else { return }
            self.handle(receivedURL: url)
            NotificationCenter.default.removeObserver(receivePaymentNotificationToken!)
        }
        
        var failedPaymentNotificationToken: NSObjectProtocol?
        failedPaymentNotificationToken = NotificationCenter.default.addObserver(forName: .didFailReceivingPaymentResultURL, object: nil, queue: .main, using: { notification in
            guard let operationType = notification.object as? ListResult.OperationType else { return }
            self.didReceiveFailureNotification(operationType: operationType)
            NotificationCenter.default.removeObserver(failedPaymentNotificationToken!)
        })
    }
    
    private func didReceiveFailureNotification(operationType: ListResult.OperationType) {
        let code: Interaction.Code
        switch operationType {
        case .PRESET, .UPDATE: code = .ABORT
        case .CHARGE, .PAYOUT: code = .VERIFY
        }
        
        let interaction = Interaction(code: code, reason: .COMMUNICATION_FAILURE)
        let operationResult = OperationResult(resultInfo: "Missing OperationResult after client-side redirect", interaction: interaction, redirect: nil)

        let result = PaymentResult(operationResult: operationResult, interaction: interaction, error: nil)
        
        delegate?.paymentService(didReceivePaymentResult: result)
    }
    
    private func handle(receivedURL: URL) {
        guard let components = URLComponents(url: receivedURL, resolvingAgainstBaseURL: false),
            var queryItems = components.queryItems?.asDictionary,
            let interactionCode = queryItems[.interactionCodeKey],
            let interactionReason = queryItems[.interactionReasonKey] else {
                // Couldn't form payment result, send an error
                let errorInteraction = Interaction(code: .VERIFY, reason: .COMMUNICATION_FAILURE)
                let error = InternalError(description: "Callback URL doesn't contain interaction code or reason. URL: %@", receivedURL.absoluteString)
                let result = PaymentResult(operationResult: nil, interaction: errorInteraction, error: error)
                delegate?.paymentService(didReceivePaymentResult: result)
                return
        }
        
        queryItems.removeValue(forKey: .interactionCodeKey)
        queryItems.removeValue(forKey: .interactionReasonKey)
        
        let interaction = Interaction(code: interactionCode, reason: interactionReason)
        let parameters: [Parameter] = queryItems.map { .init(name: $0.key, value: $0.value) }
        let redirect = Redirect(url: receivedURL, method: .GET, parameters: parameters)

        let operationResult = OperationResult(resultInfo: "OperationResult received from the mobile-redirect webapp", interaction: interaction, redirect: redirect)
        let result = PaymentResult(operationResult: operationResult, interaction: interaction, error: nil)
        
        delegate?.paymentService(didReceivePaymentResult: result)
    }
}

private extension Sequence where Element == URLQueryItem {
    var asDictionary: [String: String] {
        var dict = [String: String]()
        for queryItem in self {
            guard let value = queryItem.value else { continue }
            dict[queryItem.name] = value
        }
        
        return dict
    }
}

public extension NSNotification.Name {
    static let didReceivePaymentResultURL = NSNotification.Name(rawValue: "BasicPaymentServiceDidReceivePaymentResultURL")
    internal static let didFailReceivingPaymentResultURL = NSNotification.Name(rawValue: "BasicPaymentServiceDidFailReceivingPaymentResultURL")
}
