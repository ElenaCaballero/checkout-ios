#if canImport(UIKit)
import UIKit
import MaterialComponents.MaterialTextFields

extension Input.Table {
    /// Cell that represents all text inputs, contains label and text field.
    /// Upon some actions calls `delegate`, don't forget to set it.
    ///
    /// - Warning: after initialization before using you have to set `indexPath` to cell's indexPath
    class TextFieldViewCell: UICollectionViewCell, DequeueableCell, ContainsInputCellDelegate {
        weak var delegate: InputCellDelegate?

        private(set) var model: (TextInputField & DefinesKeyboardStyle)!
        
        let textField = MDCTextField()

        fileprivate let textFieldController: TextFieldController

        override init(frame: CGRect) {
            textFieldController = .init(textField: textField)
            
            super.init(frame: frame)
            
            textFieldController.delegate = self

            contentView.addSubview(textField)

            textField.translatesAutoresizingMaskIntoConstraints = false

            let textFieldBottomAnchor = contentView.bottomAnchor.constraint(equalTo: textField.bottomAnchor)
            textFieldBottomAnchor.priority = .defaultHigh

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                textField.topAnchor.constraint(equalTo: contentView.topAnchor),
                textFieldBottomAnchor
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
            textField.tintColor = self.tintColor
            textFieldController.setTintColor(to: tintColor)
        }
        
        func configure(with model: CellRepresentable & TextInputField & DefinesKeyboardStyle) {
            self.model = model
            textFieldController.model = model
            showValidationResult(for: model)

        }
    }
}

// MARK: - Cell configuration

extension Input.Table.TextFieldViewCell {
    override var canBecomeFirstResponder: Bool { return true }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return textField.becomeFirstResponder()
    }
}

extension Input.Table.TextFieldViewCell: TextFieldControllerDelegate {
    func textFieldDidBeginEditing() {
        delegate?.inputCellBecameFirstResponder(cell: self)
    }
    
    func textFieldDidEndEditing() {
        delegate?.inputCellDidEndEditing(cell: self)
    }
    
    func textFieldPrimaryActionTriggered() {
        delegate?.inputCellPrimaryActionTriggered(cell: self)
    }
    
    func textFieldDidBecomeFirstResponder() {
        delegate?.inputCellBecameFirstResponder(cell: self)
    }
    
    func textField(didChangeValueTo value: String) {
        delegate?.inputCellValueDidChange(to: value, cell: self)
    }
}

// MARK: - Validation error label

extension Input.Table.TextFieldViewCell {
    func showValidationResult(for model: Any) {
        guard let model = model as? Validatable else { return }

        if let errorText = model.validationErrorText {
            showErrorLabel(withText: errorText)
        } else {
            removeErrorLabel()
        }
    }

    private func showErrorLabel(withText: String) {
        textFieldController.setErrorText(to: withText)
    }

    private func removeErrorLabel() {
        textFieldController.setErrorText(to: nil)
    }
}

// MARK: - SupportsPrimaryAction

extension Input.Table.TextFieldViewCell: SupportsPrimaryAction {
    func setPrimaryAction(to action: PrimaryAction) {
        textFieldController.setPrimaryAction(to: action)
    }
}
#endif
