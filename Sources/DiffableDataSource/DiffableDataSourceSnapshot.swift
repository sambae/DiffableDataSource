#if canImport(UIKit)
import UIKit

struct DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {

    // MARK: Private API

    private struct DiffableWrapper: Hashable, DiffAware {
        let item: AnyHashable
    }

    internal struct SectionChanges {
        let deletions: IndexSet
        let insertions: IndexSet
    }

    internal struct RowChanges {
        let deletions: [IndexPath]
        let insertions: [IndexPath]
    }

    private struct Section: Hashable, DiffAware {
        static func == (lhs: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>.Section, rhs: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>.Section) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        var diffId: Int { id.hashValue }

        var id: SectionIdentifierType
        var rows: [ItemIdentifierType] = []
        var numberOfRows: Int { rows.count }

        subscript(index: Int) -> ItemIdentifierType { rows[index] }

        mutating func append(_ item: ItemIdentifierType) {
            rows.append(item)
        }

        mutating func append(_ items: [ItemIdentifierType]) {
            rows.append(contentsOf: items)
        }

        mutating func remove(at index: Int) {
            rows.remove(at: index)
        }

        mutating func insert(_ item: ItemIdentifierType, at index: Int) {
            rows.insert(item, at: index)
        }
    }

    private var layout: [Section] = []

    internal func item(for indexPath: IndexPath) -> ItemIdentifierType {
        return layout[indexPath.section][indexPath.row]
    }

    mutating internal func sectionDiff(from snapshot: DiffableDataSourceSnapshot) -> SectionChanges {
        let changes = diff(old: layout, new: snapshot.layout)

        var deletions: [Delete<Section>] = []
        var insertions: [Insert<Section>] = []

        changes.forEach { change in
            switch change {
            case .delete(let deletion): deletions.append(deletion)
            case .insert(let insertion): insertions.append(insertion)
            case .replace, .move: break
            }
        }

        deletions.forEach {
            layout.remove(at: $0.index)
        }
        insertions.forEach {
            layout.insert($0.item, at: $0.index)
        }

        let deletionSet = IndexSet(deletions.map { $0.index })
        let insertionSet = IndexSet(insertions.map { $0.index })

        return SectionChanges(deletions: deletionSet, insertions: insertionSet)
    }

    mutating internal func rowDiff(from snapshot: DiffableDataSourceSnapshot) -> RowChanges {
        var allDeletions: [IndexPath] = []
        var allInsertions: [IndexPath] = []

        zip(layout, snapshot.layout).enumerated().forEach { sectionIndex, zip in
            var deletions: [Delete<DiffableWrapper>] = []
            var insertions: [Insert<DiffableWrapper>] = []

            let oldRows = zip.0.rows.map { DiffableWrapper(item: $0)}
            let newRows = zip.1.rows.map { DiffableWrapper(item: $0)}

            let changes = diff(old: oldRows, new: newRows)

            changes.forEach { change in
                switch change {
                case .delete(let deletion): deletions.append(deletion)
                case .insert(let insertion): insertions.append(insertion)
                case .replace, .move: break
                }
            }

            deletions.forEach {
                guard let item = $0.item.item as? ItemIdentifierType else { return }

                layout[sectionIndex].insert(item, at: $0.index)
                allInsertions.append(IndexPath(row: $0.index, section: sectionIndex))
            }
            insertions.forEach {
                layout[sectionIndex].remove(at: $0.index)
                allDeletions.append(IndexPath(row: $0.index, section: sectionIndex))
            }
        }

        return RowChanges(deletions: allDeletions, insertions: allInsertions)
    }

    // MARK: Public API

    var itemIdentifiers: [ItemIdentifierType] { layout.flatMap { $0.rows } }
    var sectionIdentifiers: [SectionIdentifierType] { layout.map { $0.id } }
    var numberOfItems: Int { itemIdentifiers.count }
    var numberOfSections: Int { sectionIdentifiers.count }

    mutating func appendItems(_ identifiers: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType? = nil) {
        guard numberOfSections > 0 else {
            fatalError("There are no sections in the snapshot")
        }

        guard let sectionId = sectionIdentifier else {
            return layout[0].append(identifiers)
        }

        guard let section = layout.first(where: { $0.id == sectionId }) else {
            fatalError("The snapshot does not contain section \(String(describing: sectionIdentifier))")
        }

        var mutableSection = section
        mutableSection.append(identifiers)
    }

    mutating func appendSections(_ identifiers: [SectionIdentifierType]) {
        let sections = identifiers.map { Section(id: $0) }
        layout.append(contentsOf: sections)
    }

    func numberOfItems(inSection section: Int) -> Int {
        return layout[section].numberOfRows
    }
}
#endif
