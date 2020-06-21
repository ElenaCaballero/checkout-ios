#if canImport(UIKit)
import UIKit

extension Input.Table {
    /// Cell that represents a label.
    class LabelViewCell: FullWidthCollectionViewCell, DequeueableCell {
        fileprivate let label: UILabel

        override init(frame: CGRect) {
            label = .init(frame: .zero)

            super.init(frame: frame)

            // Configure label
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
            label.textColor = .text
            label.font = UIFont.preferredFont(forTextStyle: .body)

            // Layout
            contentView.addSubview(label)

            label.translatesAutoresizingMaskIntoConstraints = false
            
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            
            let bottomLabelConstraint = label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            bottomLabelConstraint.priority = .defaultHigh
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                bottomLabelConstraint,
                label.topAnchor.constraint(equalTo: contentView.topAnchor),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: - Cell configuration

extension Input.Table.LabelViewCell {
    func configure(with model: Input.Field.Label) {
        label.text = model.label
    }
}
#endif
