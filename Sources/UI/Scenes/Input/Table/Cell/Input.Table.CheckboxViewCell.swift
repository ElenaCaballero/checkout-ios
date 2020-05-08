#if canImport(UIKit)
import UIKit

private struct UIConstant {
    static let defaultSpacing: CGFloat = 8
}

extension Input.Table {
    /// Cell that represents a checkbox (UISwitch).
    /// Upon some actions calls `delegate`, don't forget to set it.
    ///
    /// - Warning: after initialization before using you have to set `indexPath` to cell's indexPath
    class CheckboxViewCell: UITableViewCell, DequeueableTableCell {
        weak var delegate: InputCellDelegate?

        private let label: UILabel
        let checkbox: UISwitch
        var indexPath: IndexPath!

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            label = .init(frame: .zero)
            checkbox = .init(frame: .zero)

            super.init(style: style, reuseIdentifier: reuseIdentifier)

            // Configure label
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
            label.textColor = .text

            // Configure checkbox
            checkbox.addTarget(self, action: #selector(checkboxValueChanged), for: .valueChanged)

            // Layout
            contentView.addSubview(label)
            contentView.addSubview(checkbox)

            label.translatesAutoresizingMaskIntoConstraints = false
            checkbox.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: checkbox.leadingAnchor, constant: -UIConstant.defaultSpacing),
                label.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
                label.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),

                checkbox.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                checkbox.centerYAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerYAnchor)
            ])
        }

        @objc private func checkboxValueChanged(_ sender: UISwitch) {
            delegate?.inputCellValueDidChange(to: checkbox.isOn.stringValue, at: indexPath)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: - Cell configuration

extension Input.Table.CheckboxViewCell {
    func configure(with model: Input.Field.Checkbox) {
        label.text = model.name
        checkbox.isOn = model.isOn
        checkbox.isHidden = model.isHidden
        checkbox.isEnabled = model.isEnabled
        checkbox.onTintColor = self.tintColor
    }
}

extension Input.Table.CheckboxViewCell: ContainsInputCellDelegate {}
#endif