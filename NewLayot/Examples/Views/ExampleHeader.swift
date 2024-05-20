import UIKit

final class ExampleHeader: UICollectionReusableView {

    static let id = "ExmapleHeaderId"
    static let kind = "section-header-element-kind"

    private let title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: centerXAnchor),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        title.text = "Заголовок"
        title.textColor = .white
        backgroundColor = .blue
    }

}
