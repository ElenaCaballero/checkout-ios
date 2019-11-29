#if canImport(UIKit)
import UIKit

/// Could be represented as a table cell
protocol CellRepresentable {
    func dequeueConfiguredCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell & ContainsInputCellDelegate
}

// If model is `TextInputField` & `DefinesKeyboardStyle`
extension CellRepresentable where Self: DefinesKeyboardStyle {
    func dequeueConfiguredCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell & ContainsInputCellDelegate {
        let cell = tableView.dequeueReusableCell(Input.TextFieldViewCell.self, for: indexPath)
        cell.indexPath = indexPath
        cell.configure(with: self)
        return cell
    }
}
#endif
