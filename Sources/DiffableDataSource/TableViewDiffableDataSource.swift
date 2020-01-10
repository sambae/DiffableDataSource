#if canImport(UIKit)

class TableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> : NSObject where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {

    typealias CellProvider = (UITableView, IndexPath, ItemIdentifierType) -> UITableViewCell?
}

#endif
