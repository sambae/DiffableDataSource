#if canImport(UIKit)
import UIKit

class TableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: NSObject, UITableViewDataSource where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {

    typealias CellProvider = (UITableView, IndexPath, ItemIdentifierType) -> UITableViewCell?

    private weak var tableView: UITableView?

    private var cellProvider: CellProvider
    private var snapshot = DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()

    init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        self.tableView = tableView
        self.cellProvider = cellProvider
    }

    func apply(_ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {

        let sectionChanges = self.snapshot.sectionDiff(from: snapshot)
        let rowChanges = self.snapshot.rowDiff(from: snapshot)

        tableView?.performBatchUpdates({
            tableView?.deleteSections(sectionChanges.deletions, with: .automatic)
            tableView?.insertSections(sectionChanges.insertions, with: .automatic)
            tableView?.deleteRows(at: rowChanges.deletions, with: .automatic)
            tableView?.insertRows(at: rowChanges.insertions, with: .automatic)
        }, completion: { _ in
            completion?()
        })
    }

    // MARK: -- UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return snapshot.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return snapshot.numberOfItems(inSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = snapshot.item(for: indexPath)

        guard let cell = cellProvider(tableView, indexPath, item) else {
            fatalError("Could not dequeue cell")
        }

        return cell
    }
}

#endif
