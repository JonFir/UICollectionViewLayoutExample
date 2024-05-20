import UIKit

func makeCustomLayoutVC5SectionBG() -> UIViewController {
    CustomLayoutVC()
}

private class CustomLayoutVC: UIViewController {

    var texts = makeTexts(lenght: 10000)
    let cellTemplate = ExampleTextCell(frame: .zero)
    var collectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    private func setupView() {
        let layout = CustomLayout()
        layout.register(
            ExampleSectionBackgroundDecorationView.self,
            forDecorationViewOfKind: ExampleSectionBackgroundDecorationView.kind
        )

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
        self.collectionView = collectionView
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
            padding: .init(top: 10, left: 10, bottom: 10, right: 10),
            margin: .init(top: 20, left: 20, bottom: 20, right: 20),
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
    let padding: UIEdgeInsets
    let margin: UIEdgeInsets
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
    var totalVericalOffset = 0.0
    var attributesList: [UICollectionViewLayoutAttributes] = []
    var decorationsList: [UICollectionViewLayoutAttributes] = []

    override var collectionViewContentSize: CGSize {
        guard let collectionView, let delegate else { return .zero }

        let sectionConfiguration = delegate.getSectionConfig(sectionIndex: 0)

        let with = collectionView.frame.width
        return CGSize(width: with, height: totalVericalOffset)
    }

    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        return attributesList.filter { $0.frame.intersects(rect) } 
            + decorationsList.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        return attributesList[indexPath.item]
    }

    override func layoutAttributesForDecorationView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        if elementKind == ExampleSectionBackgroundDecorationView.kind && indexPath.item == 0 {
            return decorationsList[indexPath.item]
        } else {
            return nil
        }
    }

    override func prepare() {
        super.prepare()

        guard let collectionView, let delegate else { return }

        let sectionIndex = 0
        let sectionConfiguration = delegate.getSectionConfig(sectionIndex: sectionIndex)
        let collectionWith = collectionView.frame.width
        let sectionWidth = collectionWith - sectionConfiguration.margin.left - sectionConfiguration.margin.right
        let sectionContentWidth = sectionWidth - sectionConfiguration.padding.left - sectionConfiguration.padding.right

        totalVericalOffset = 0.0
        attributesList.removeAll(keepingCapacity: true)
        decorationsList.removeAll(keepingCapacity: true)

        totalVericalOffset += sectionConfiguration.margin.top
        var backgroundFrame = CGRect(
            x: sectionConfiguration.margin.left,
            y: totalVericalOffset,
            width: sectionWidth,
            height: 0.0
        )
        totalVericalOffset += sectionConfiguration.padding.top
        var rowVericalOffset = totalVericalOffset

        for itemIndex in 0..<collectionView.numberOfItems(inSection: sectionIndex) {
            let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
            let index = indexPath.item % sectionConfiguration.numberOfCollumn

            let itemWidth = (sectionContentWidth - Double(sectionConfiguration.numberOfCollumn) * (sectionConfiguration.itemPadding.left + sectionConfiguration.itemPadding.right)) / Double(sectionConfiguration.numberOfCollumn)

            let itemConfiguration = delegate.getCellConfig(indexPath: indexPath, width: itemWidth)

            if index == 0 {
                totalVericalOffset += sectionConfiguration.itemPadding.top
            }

            let itemsHorisontalPadding = Double(index) * itemWidth + Double(index) * (sectionConfiguration.itemPadding.left + sectionConfiguration.itemPadding.right) + sectionConfiguration.itemPadding.left + sectionConfiguration.margin.left + sectionConfiguration.padding.left

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

            attributes.frame = CGRect(
                origin: .init(x: itemsHorisontalPadding, y: totalVericalOffset),
                size: CGSize(width: itemWidth, height: itemConfiguration.itemSize.height)
            )
            attributes.zIndex = itemIndex + 1
            rowVericalOffset = max(attributes.bounds.maxY, rowVericalOffset)
            attributesList.append(attributes)

            if index == sectionConfiguration.numberOfCollumn - 1 {
                totalVericalOffset += rowVericalOffset + sectionConfiguration.itemPadding.bottom
                rowVericalOffset = 0.0
            }

        }

        totalVericalOffset += sectionConfiguration.padding.bottom
        backgroundFrame.size.height = totalVericalOffset - backgroundFrame.minY
        totalVericalOffset += sectionConfiguration.margin.bottom

        let backgroundAttributes = UICollectionViewLayoutAttributes(
            forDecorationViewOfKind: ExampleSectionBackgroundDecorationView.kind,
            with: IndexPath(item: 0, section: 0)
        )

        backgroundAttributes.frame = backgroundFrame
        backgroundAttributes.zIndex = -2
        decorationsList.append(backgroundAttributes)
    }

}


