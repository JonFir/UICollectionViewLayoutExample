import UIKit

final class ExampleSectionBackgroundDecorationView: UICollectionReusableView {

    static let kind = "background-element-kind"

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func setup() {
        backgroundColor = .red
        layer.cornerRadius = 10
    }
}

