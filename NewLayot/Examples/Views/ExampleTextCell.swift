import UIKit

final class ExampleTextCell: UICollectionViewCell {

    static let id = "ExampleTextCell"

    enum Style {
        case odd
        case even

        init(indexPath: IndexPath) {
            self = indexPath.section % 2 == 0 ? .odd : .even
        }
    }

    private let title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(text: String, style: Style) {
        title.text = text
        switch style {
        case .odd:
            contentView.backgroundColor = .orange
        case .even:
            contentView.backgroundColor = .green
        }
    }

    private func setup() {
        contentView.addSubview(title)
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false
        title.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        title.setContentHuggingPriority(.defaultLow, for: .vertical)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

}

