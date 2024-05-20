import UIKit

func makeDifferentCellSize() -> UIViewController {
    CustomLayoutVC()
}

private class CustomLayoutVC: UIViewController {

    let texts = makeTexts(lenght: 3000)
    let cellTemplate = ExampleTextCell(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    private func setupView() {
        let layout = CustomLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ExampleTextCell.self, forCellWithReuseIdentifier: ExampleTextCell.id)

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
        return texts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExampleTextCell.id, for: indexPath) as! ExampleTextCell
        let text = texts[indexPath.item]
        cell.configure(text: text, style: .init(indexPath: indexPath))
        return cell
    }

    func getSectionConfig(sectionIndex: Int) -> SectionConfiguration {
        SectionConfiguration(
            itemPadding: .init(top: 5, left: 5, bottom: 5, right: 5),
            numberOfCollumn: 2
        )
    }

    func getCellConfig(
        indexPath: IndexPath,
        width: Double
    ) -> CellConfiguration {
        let text = texts[indexPath.item]
        cellTemplate.configure(text: text, style: .init(indexPath: indexPath))
        let size = cellTemplate.contentView.systemLayoutSizeFitting(
            .init(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )
        return CellConfiguration(itemSize: size)
    }

}

private struct SectionConfiguration {
    let itemPadding: UIEdgeInsets
    let numberOfCollumn: Int
}

private struct CellConfiguration {
    let itemSize: CGSize
}

private protocol CustomLayoutDelegate: UICollectionViewDelegate {

    func getSectionConfig(sectionIndex: Int) -> SectionConfiguration
    func getCellConfig(
        indexPath: IndexPath,
        width: Double
    ) -> CellConfiguration
}


private class CustomLayout: UICollectionViewLayout {
    var delegate: CustomLayoutDelegate? { collectionView?.delegate as? CustomLayoutDelegate }

    override var collectionViewContentSize: CGSize {
        guard let collectionView, let delegate else { return .zero }

        let sectionConfiguration = delegate.getSectionConfig(sectionIndex: 0)
        let attributes = makeAttributes()

        let heigth = (attributes.last?.frame.maxY ?? 0) + sectionConfiguration.itemPadding.bottom
        let with = collectionView.frame.width
        return CGSize(width: with, height: heigth)
    }

    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        let attributes = makeAttributes()
        return attributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        let attributes = makeAttributes()
        return attributes[indexPath.item]
    }

    func makeAttributes() -> [UICollectionViewLayoutAttributes] {
        guard let collectionView, let delegate else { return [] }

        let sectionIndex = 0
        let sectionConfiguration = delegate.getSectionConfig(sectionIndex: sectionIndex)
        let collectionWith = collectionView.frame.width
        let itemWidth = (collectionWith - Double(sectionConfiguration.numberOfCollumn) * (sectionConfiguration.itemPadding.left + sectionConfiguration.itemPadding.right)) / Double(sectionConfiguration.numberOfCollumn)

        var totalVericalOffset = 0.0
        var rowVericalOffset = 0.0

        var attributesList: [UICollectionViewLayoutAttributes] = []

        for itemIndex in 0..<collectionView.numberOfItems(inSection: sectionIndex) {
            let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
            let index = indexPath.item % sectionConfiguration.numberOfCollumn

            let itemConfiguration = delegate.getCellConfig(indexPath: indexPath, width: itemWidth)

            if index == 0 {
                totalVericalOffset += sectionConfiguration.itemPadding.top
            }

            let itemsHorisontalPadding = Double(index) * itemWidth + Double(index) * (sectionConfiguration.itemPadding.left + sectionConfiguration.itemPadding.right) + sectionConfiguration.itemPadding.left

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

            attributes.frame = CGRect(
                origin: .init(x: itemsHorisontalPadding, y: totalVericalOffset),
                size: CGSize(width: itemWidth, height: itemConfiguration.itemSize.height)
            )
            rowVericalOffset = max(attributes.bounds.maxY, rowVericalOffset)
            attributesList.append(attributes)
            
            if index == sectionConfiguration.numberOfCollumn - 1 {
                totalVericalOffset += rowVericalOffset + sectionConfiguration.itemPadding.bottom
                rowVericalOffset = 0.0
            }

        }
        return attributesList
    }

}
