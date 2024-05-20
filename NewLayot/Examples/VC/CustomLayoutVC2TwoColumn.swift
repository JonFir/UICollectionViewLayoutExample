import UIKit

func CustomLayoutVC2TwoColumn() -> UIViewController {
    CustomLayoutVC()
}

private class CustomLayoutVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    private func setupView() {
        let layout = CustomLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ExampleCell.self, forCellWithReuseIdentifier: ExampleCell.id)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
        ])
    }


}

extension CustomLayoutVC: CustomLayoutDelegate, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExampleCell.id, for: indexPath) as! ExampleCell
        cell.configure(style: .init(indexPath: indexPath))
        return cell
    }

    func getSectionConfig(sectionIndex: Int) -> SectionConfiguration {
        SectionConfiguration(
            itemSize: .init(width: 100, height: 100),
            itemPadding: .init(top: 5, left: 5, bottom: 5, right: 5),
            numberOfCollumn: 2
        )
    }

}

private struct SectionConfiguration {
    let itemSize: CGSize
    let itemPadding: UIEdgeInsets
    let numberOfCollumn: Int
}

extension SectionConfiguration {

    var itemFullSize: CGSize {
        let width = itemSize.width
            + itemPadding.left
            + itemPadding.right

        let height = itemSize.height
            + itemPadding.top
            + itemPadding.bottom

        return CGSize(width: width, height: height)
    }

}

private protocol CustomLayoutDelegate: UICollectionViewDelegate {

    func getSectionConfig(sectionIndex: Int) -> SectionConfiguration
}


private class CustomLayout: UICollectionViewLayout {
    var delegate: CustomLayoutDelegate? { collectionView?.delegate as? CustomLayoutDelegate }

    override var collectionViewContentSize: CGSize {
        guard let collectionView, let delegate else { return .zero }
        let numberOfItems = collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0) ?? 0
        let configuration = delegate.getSectionConfig(sectionIndex: 0)
        let numberOfRows = numberOfItems / configuration.numberOfCollumn
        let itemFullSize = configuration.itemFullSize
        return CGSize(
            width: collectionView.frame.width,
            height: itemFullSize.height * Double(numberOfRows)
        )
    }

    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        guard let delegate else { return [] }
        let configuration = delegate.getSectionConfig(sectionIndex: 0)
        let itemFullSize = configuration.itemFullSize
        let rowHeight = Int(itemFullSize.height)
        let firstRow = Int(rect.minY) / rowHeight
        let lastRow = Int(rect.maxY) / rowHeight
        let firstItem = firstRow * configuration.numberOfCollumn
        let lastItem = lastRow * configuration.numberOfCollumn + configuration.numberOfCollumn - 1

        return (firstItem...lastItem)
            .map { IndexPath(item: $0, section: 0) }
            .compactMap(layoutAttributesForItem)
    }

    override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard let collectionView, let delegate else { return nil }
        let configuration = delegate.getSectionConfig(sectionIndex: 0)
        let itemFullSize = configuration.itemFullSize
        let row = indexPath.item / configuration.numberOfCollumn
        let index = indexPath.item % configuration.numberOfCollumn

        let itemWidth = (collectionView.frame.width - Double(configuration.numberOfCollumn) * (configuration.itemPadding.left + configuration.itemPadding.right)) / Double(configuration.numberOfCollumn)

        let itemsVerticalPadding = Double(row) * itemFullSize.height + configuration.itemPadding.top
        let itemsHorisontalPadding = Double(index) * itemWidth + Double(index) * (configuration.itemPadding.left + configuration.itemPadding.right) + configuration.itemPadding.left

        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        attributes.frame = CGRect(
            origin: .init(x: itemsHorisontalPadding, y: itemsVerticalPadding),
            size: CGSize(width: itemWidth, height: configuration.itemSize.height)
        )
        return attributes
    }

}
