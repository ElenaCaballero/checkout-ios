import UIKit
import Optile

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }

    @IBAction func sendRequest(_ sender: Any) {
        guard let text = textField.text, let url = URL(string: text) else {
            print("Invalid URL")
            textField.text = nil
            return
        }

        let viewController = List.ViewController(listResultURL: url)
        let navigationController = PaymentNavigationController(rootViewController: viewController)
        present(navigationController, animated: true, completion: nil)
    }
}
