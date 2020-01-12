#if canImport(UIKit)

import Foundation
import UIKit

protocol ListTableControllerDelegate: class {
    func didSelect(paymentNetworks: [PaymentNetwork])
    func load(from url: URL, completion: @escaping (Result<Data, Error>) -> Void)
}

extension List.Table {
    final class Controller: NSObject {
        weak var tableView: UITableView?
        weak var delegate: ListTableControllerDelegate?

        let dataSource: List.Table.DataSource
        
        init(networks: [PaymentNetwork], translationProvider: SharedTranslationProvider) throws {
            guard let genericLogo = AssetProvider.iconCard else {
                throw InternalError(description: "Unable to load a credit card's generic icon")
            }
            
            dataSource = .init(networks: networks, translation: translationProvider, genericLogo: genericLogo)
        }
        
        func viewDidLayoutSubviews() {
            guard let tableView = self.tableView else { return }
            for cell in tableView.visibleCells {
                guard let paymentCell = cell as? List.Table.BorderedCell else { continue }
                paymentCell.viewDidLayoutSubviews()
            }
        }

        fileprivate func loadLogo(for indexPath: IndexPath) {
            let networks = dataSource.networks(for: indexPath)
            
            for network in networks {
                /// If logo was already downloaded
                guard case let .some(.notLoaded(url)) = network.logo else { continue }
                
                delegate?.load(from: url) { [weak self] result in
                    network.logo = .loaded(result)

                    // Don't reload rows if multiple networks (we don't show logos for now for them)
                    // TODO: Potential multiple updates for a single cell
                    DispatchQueue.main.async {
                        self?.tableView?.reloadRows(at: [indexPath], with: .fade)
                    }
                }
            }
        }
    }
}


extension List.Table.Controller: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            loadLogo(for: indexPath)
        }
    }
}

extension List.Table.Controller: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        loadLogo(for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedNetworks = dataSource.networks(for: indexPath)
        delegate?.didSelect(paymentNetworks: selectedNetworks)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = List.Table.SectionHeader(frame: .zero)
        view.textLabel?.text = tableView.dataSource?.tableView?(tableView, titleForHeaderInSection: section)
        return view
    }
}
#endif
