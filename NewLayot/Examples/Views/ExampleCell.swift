import UIKit

final class ExampleCell: UICollectionViewCell {

    static let id = "ExampleCellId"

    enum Style {
        case odd
        case even

        init(indexPath: IndexPath) {
            self = indexPath.section % 2 == 0 ? .odd : .even
        }
    }

    func configure(style: Style) {
        switch style {
        case .odd:
            contentView.backgroundColor = .orange
        case .even:
            contentView.backgroundColor = .green
        }
    }

}
