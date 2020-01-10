#if canImport(UIKit)
import UIKit

struct DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {

    // MARK: -- Private API

    private struct Section {
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
    }

    private var layout: [Section] = []

    internal func item(for indexPath: IndexPath) -> ItemIdentifierType {
        return layout[indexPath.section][indexPath.row]
    }

    // MARK: -- Public API

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
