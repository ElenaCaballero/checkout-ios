import UIKit

extension Input.ViewController {
    class StateManager {
        unowned let vc: Input.ViewController
        
        var state: UIState = .inputFieldsPresentation {
            willSet {
                DispatchQueue.main.async {
                    self.changeState(to: newValue, from: self.state)
                }
            }
        }
        
        init(viewController: Input.ViewController) {
            self.vc = viewController
        }
    }
}

extension Input.ViewController.StateManager {
    fileprivate func changeState(to newState: UIState, from oldState: UIState) {
        switch oldState {
        case .paymentSubmission:
            setPaymentSubmission(isActive: false)
        default: break
        }
        
        switch newState {
        case .paymentSubmission:
            setPaymentSubmission(isActive: true)
        case .paymentResultPresentation(let paymentResult):
            present(paymentResult: paymentResult)
        default: break
        }
    }
    
    private func setPaymentSubmission(isActive: Bool) {
        vc.tableController.dataSource.setEnabled(!isActive, collectionView: vc.collectionView)
    }
    
    private func present(paymentResult: PaymentResult) {
        let message = "\(paymentResult.operationResult.resultInfo)\nInteraction code: \(paymentResult.operationResult.interaction.code)"
        let alert = UIAlertController(title: "Payment result", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            self.state = .inputFieldsPresentation
        }
        alert.addAction(okAction)
        vc.present(alert, animated: true, completion: nil)
    }
}

extension Input.ViewController.StateManager {
    enum UIState {
        case inputFieldsPresentation
        case paymentSubmission
        case paymentResultPresentation(PaymentResult)
        case error(Error)
    }
}
