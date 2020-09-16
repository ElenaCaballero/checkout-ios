import UIKit

extension Input.ViewController {
    class StateManager {
        unowned let vc: Input.ViewController

        var state: UIState = .inputFieldsPresentation {
            didSet { self.changeState(to: self.state, from: oldValue) }
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
        case .error(let error):
            present(error: error)
        default: break
        }
    }

    private func setPaymentSubmission(isActive: Bool) {
        if #available(iOS 13.0, *) {
            vc.isModalInPresentation = isActive
        }
        vc.navigationItem.leftBarButtonItem?.isEnabled = !isActive

        vc.tableController.dataSource.setEnabled(!isActive)
        vc.tableController.dataSource.setPaymentButtonState(isLoading: isActive)

        vc.collectionView.reloadData()
    }

    private func present(error: Error) {
        let translator = vc.smartSwitch.selected.network.translation

        let alertController: UIAlertController
        
        if let uiPreparedError = error as? UIAlertController.PreparedError {
            alertController = uiPreparedError.makeAlertController(translator: translator)
        } else {
            let error = UIAlertController.PreparedError(for: error, translator: translator)
            alertController = error.makeAlertController(translator: translator)
        }

        vc.present(alertController, animated: true, completion: {
            self.state = .inputFieldsPresentation
        })
    }
}

extension Input.ViewController.StateManager {
    enum UIState {
        case inputFieldsPresentation
        case paymentSubmission
        case error(Error)
    }
}
