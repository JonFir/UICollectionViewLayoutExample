import UIKit

func makeCompositionalLayoutSectionProviderVC() -> UIViewController {
    CompositionalLayoutSectionProviderVC()
}

private class CompositionalLayoutSectionProviderVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    private func setupView() {
        let sectionProvider = { (sectionIndex: Int, environment: any NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let numberOfColumn = sectionIndex == 1 ? 3 : 2
            let size = 1.0 / Double(numberOfColumn)
            let item = {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(size),
                    heightDimension: .fractionalWidth(size)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = .init(top:5, leading: 5, bottom: 5, trailing: 5)
                return item
            }()

            let group = {
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalWidth(size)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                return group
            }()

            let section = NSCollectionLayoutSection(group: group)

            let decorationItems = {
                let decorationItems = NSCollectionLayoutDecorationItem.background(elementKind: ExampleSectionBackgroundDecorationView.kind)
                decorationItems.contentInsets =  NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                return decorationItems
            }()
            section.decorationItems = [decorationItems]

            section.contentInsets = .init(top:20, leading: 20, bottom: 20, trailing: 20)

            if sectionIndex == 1 {
                let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerItemSize,
                    elementKind: ExampleHeader.kind,
                    alignment: .top
                )
                headerItem.zIndex = 999
                headerItem.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [headerItem]
            }

            return section
        }

        let layout = {
            let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
            layout.register(
                ExampleSectionBackgroundDecorationView.self,
                forDecorationViewOfKind: ExampleSectionBackgroundDecorationView.kind
            )
            return layout
        }()

        let collectionView = {
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.dataSource = self
            collectionView.register(ExampleCell.self, forCellWithReuseIdentifier: ExampleCell.id)
            collectionView.register(
                ExampleHeader.self,
                forSupplementaryViewOfKind: ExampleHeader.kind,
                withReuseIdentifier: ExampleHeader.id
            )
            return collectionView
        }()

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

extension CompositionalLayoutSectionProviderVC: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        10
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExampleCell.id, for: indexPath) as! ExampleCell
        cell.configure(style: .init(indexPath: indexPath))
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if kind == ExampleHeader.kind && indexPath.section == 1 {
            return collectionView.dequeueReusableSupplementaryView(ofKind: ExampleHeader.kind, withReuseIdentifier: ExampleHeader.id, for: indexPath)
        } else {
            fatalError()
        }
    }

}
