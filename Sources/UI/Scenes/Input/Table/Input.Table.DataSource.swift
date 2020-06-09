import UIKit

extension Input.Table {
    class DataSource: NSObject {
        weak var inputCellDelegate: InputCellDelegate?
        fileprivate(set) var model: [[CellRepresentable]] = .init()
        
        func setModel(network: Input.Network, header: CellRepresentable) {
            model = Self.arrangeBySections(network: network, header: header)
        }
        
        func isLastTextField(at indexPath: IndexPath) -> Bool {
            var lastTextFieldRow: Int?
            
            let rowsInSection = model[indexPath.section]
            for rowIndex in indexPath.row...rowsInSection.count - 1 {
                let element = rowsInSection[rowIndex]
                guard let _ = element as? TextInputField else { continue }
                lastTextFieldRow = rowIndex
            }
            
            if lastTextFieldRow == nil { return true }
            if lastTextFieldRow == indexPath.row { return true }
            
            return false
        }
        
        /// Set enabled state for all datasource items
        func setEnabled(_ enabled: Bool, collectionView: UICollectionView) {
            for cellRepresentable in model.flatMap({ $0 }) {
                cellRepresentable.isEnabled = enabled
            }
            
            collectionView.reloadData()
        }
        
        var inputFields: [InputField] {
            model.flatMap {
                $0.compactMap { $0 as? InputField }
            }
        }
        
        /// Arrange models by sections
        private static func arrangeBySections(network: Input.Network, header: CellRepresentable) -> [[CellRepresentable]] {
            var sections = [[CellRepresentable]]()
            
            // Header
            sections += [[header]]
            
            // Input Fields
            let inputFields = network.inputFields.filter {
                if $0.isHidden { return false }
                return true
            }
            sections += [inputFields]
            
            // Checkboxes
            var checkboxes = [CellRepresentable]()
            for field in network.separatedCheckboxes where !field.isHidden {
                checkboxes.append(field)
            }
            
            sections += [checkboxes]
            
            // Submit
            sections += [[network.submitButton]]
            
            let dataSource = sections.filter { !$0.isEmpty }
            
            return dataSource
        }
    }
}

// MARK: - UICollectionViewDataSource

extension Input.Table.DataSource: UICollectionViewDataSource {    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return model.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellModel = model[indexPath.section][indexPath.row]
        let cell = cellModel.dequeueCell(for: collectionView, indexPath: indexPath)
        cell.tintColor = collectionView.tintColor

        do {
            try cellModel.configure(cell: cell)
        } catch {
            log(error)
        }
        
        if let cell = cell as? ContainsInputCellDelegate {
            cell.delegate = inputCellDelegate
        }
        
        if let cell = cell as? SupportsPrimaryAction {
            let isLastRow = isLastTextField(at: indexPath)
            let action: PrimaryAction = isLastRow ? .done : .next
            cell.setPrimaryAction(to: action)
        }
        
        return cell
    }
}

// MARK: - Input.Table.DataSource.Diff

extension Input.Table.DataSource {
    struct Diff {
        var old: [[CellRepresentable]]
        var new: [[CellRepresentable]]
    }
}

extension Input.Table.DataSource.Diff {
    func applyChanges(for collectionView: UICollectionView) {
        for oldSectionIndex in 0 ..< old.count {
            // Ensure that old section is still will be present in a new model or delete old one
            guard oldSectionIndex < new.count else {
                collectionView.deleteSections([oldSectionIndex])
                continue
            }
            
            reload(section: oldSectionIndex, in: collectionView)
        }
        
        // If a new model has more sections insert new ones
        if new.count > old.count {
            for index in old.count - 1 ..< new.count - 1 {
                collectionView.insertSections([index])
            }
        }
    }
    
    private func reload(section: Int, in collectionView: UICollectionView) {
        // If number of cells in section are not equal reload a whole section
        guard old[section].count == new[section].count else {
            collectionView.reloadSections([section])
            return
        }
        
        for rowIndex in 0 ..< old.count {
            let indexPath = IndexPath(row: rowIndex, section: section)
            
            guard let cell = collectionView.cellForItem(at: indexPath) else { continue }
            
            let model = new[section][rowIndex]
            do {
                // Configure old cell with a new model
                try model.configure(cell: cell)
                cell.layoutIfNeeded()
            } catch {
                // New model is not compatible with old cell type, reload that cell
                collectionView.reloadItems(at: [indexPath])
            }
        }
    }
}
