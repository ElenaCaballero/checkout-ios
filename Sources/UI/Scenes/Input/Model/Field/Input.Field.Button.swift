import UIKit
import Foundation

extension Input.Field {
    final class Button {
        let label: String

        var buttonDidTap: ((Button) -> Void)?

        init(label: String) {
            self.label = label
        }
    }
}

extension Input.Field.Button: CellRepresentable {
    func configure(cell: UICollectionViewCell) {
        guard let cell = cell as? Input.Table.ButtonCell else {
            assertionFailure("Called configure(cell:) from unexpected UITableViewCell")
            return
        }
        cell.configure(with: self)
    }

    func dequeueCell(for view: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return view.dequeueReusableCell(Input.Table.ButtonCell.self, for: indexPath)
    }
}
