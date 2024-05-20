import LoremSwiftum


func makeTexts(lenght: Int) -> [String] {
    (0..<lenght).map { _ in Lorem.words(Int.random(in: 1..<10)) }
}

func makeText() -> String {
    Lorem.words(Int.random(in: 1..<10))
}

/*
 // Запуск

 invalidateLayout()
 invalidateLayout(with context: UICollectionViewLayoutInvalidationContext)
 prepare()
 collectionViewContentSize

 override func shouldInvalidateLayout(
         forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
         withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
     )
 ---------
 // скрол

 shouldInvalidateLayout(forBoundsChange newBounds: CGRect)
 invalidationContext(forBoundsChange newBounds: CGRect)
 invalidateLayout()
 invalidateLayout(with context: UICollectionViewLayoutInvalidationContext)
 prepare()
 collectionViewContentSize

 ---------
 // поворот

 invalidateLayout(with context: UICollectionViewLayoutInvalidationContext)
 prepare()
 collectionViewContentSize
 prepare(forAnimatedBoundsChange oldBounds: CGRect)
 targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint)
 collectionViewContentSize
 shouldInvalidateLayout(
     forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
     withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
 )
 finalizeAnimatedBoundsChange()

 ---------
 // вставка

 invalidateLayout()
 invalidateLayout(with context: UICollectionViewLayoutInvalidationContext)
 prepare()
 collectionViewContentSize
 prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem])
 indexPathsToDeleteForDecorationView(ofKind elementKind: String)
 indexPathsToInsertForDecorationView(ofKind elementKind: String)
 collectionViewContentSize
 targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint)
 initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath)
 shouldInvalidateLayout(
     forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
     withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
 )
 finalizeCollectionViewUpdates()
 collectionViewContentSize
 shouldInvalidateLayout(
     forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
     withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
 )
 */
