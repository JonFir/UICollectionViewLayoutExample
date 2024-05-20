import UIKit

func makeCompositionalLayoutVC() -> UIViewController {
    CompositionalLayoutVC()
}

private class CompositionalLayoutVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    private func setupView() {
        let item = {
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .fractionalWidth(0.5)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top:5, leading: 5, bottom: 5, trailing: 5)
            return item
        }()

        let group = {
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(0.5)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            return group
        }()

        let section = {
            let decorationItems = NSCollectionLayoutDecorationItem.background(elementKind: ExampleSectionBackgroundDecorationView.kind)
            decorationItems.contentInsets =  NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

            let section = NSCollectionLayoutSection(group: group)
            section.decorationItems = [decorationItems]
            section.contentInsets = .init(top:20, leading: 20, bottom: 20, trailing: 20)

            let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerItemSize,
                elementKind: ExampleHeader.kind,
                alignment: .top
            )
            headerItem.zIndex = 999
            headerItem.pinToVisibleBounds = true
            section.boundarySupplementaryItems = [headerItem]

            return section
        }()

        let layout = {
            let layout = UICollectionViewCompositionalLayout(section: section)
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

extension CompositionalLayoutVC: UICollectionViewDataSource {

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

}
