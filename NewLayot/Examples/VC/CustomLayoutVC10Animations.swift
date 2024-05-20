import UIKit

func CustomLayoutVC10Animations() -> UIViewController {
    CustomLayoutVC()
}

private class CustomLayoutVC: UIViewController {

    var texts = (0..<1000).map { _ in makeTexts(lenght: 10) }
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
        collectionView.register(
            ExampleHeader.self,
            forSupplementaryViewOfKind: ExampleHeader.kind,
            withReuseIdentifier: ExampleHeader.id
        )

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
        texts.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return texts[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExampleTextCell.id, for: indexPath) as! ExampleTextCell
        let text = texts[indexPath.section][indexPath.item]
        cell.configure(text: text, style: .init(indexPath: indexPath))
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if kind == ExampleHeader.kind {
            return collectionView.dequeueReusableSupplementaryView(ofKind: ExampleHeader.kind, withReuseIdentifier: ExampleHeader.id, for: indexPath)
        } else {
            fatalError()
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if indexPath.item == texts[indexPath.section].count - 1 {
            let index = texts[indexPath.section].count
            texts[indexPath.section].append(makeText())
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: [IndexPath(item: index, section: indexPath.section)])
            }
        } else {
            texts[indexPath.section].remove(at: indexPath.item)
            collectionView.performBatchUpdates {
                collectionView.deleteItems(at: [indexPath])
            }
        }
        return false
    }

    func getSectionConfig(sectionIndex: Int) -> SectionConfiguration {
        let header: SectionConfiguration.Header?
        if sectionIndex == 1 {
            header = .init(
                height: 50,
                padding: .init(top: 10, left: 0, bottom: 20, right: 0)
            )
        } else {
            header = nil
        }
        return SectionConfiguration(
            itemPadding: .init(top: 5, left: 5, bottom: 5, right: 5),
            padding: .init(top: 10, left: 10, bottom: 10, right: 10),
            margin: .init(top: 20, left: 20, bottom: 20, right: 20),
            numberOfCollumn: 2,
            header: header
        )
    }

    func getCellConfig(
        indexPath: IndexPath,
        width: Double
    ) -> CellConfiguration {
        let text = texts[indexPath.section][indexPath.item]
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
    let header: Header?

    struct Header {
        let height: Double
        let padding: UIEdgeInsets
    }
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
    private var delegate: CustomLayoutDelegate? { collectionView?.delegate as? CustomLayoutDelegate }
    private let state = CustomLayoutState()
    private var prepareActions: PrepareActions = []
    // Used to prevent a collection view bug / animation issue that occurs when off-screen batch
    // updates cause changes to the elements in the visible region. See comment in
    // `layoutAttributesForElementsInRect:` for more details.
    private var hasDataSourceCountInvalidationBeforeReceivingUpdateItems = false
    private var cachedCollectionViewWidth: CGFloat?
    private var currentBounds: CGRect {
        collectionView?.bounds ?? .zero
    }
    private var scale: CGFloat {
        collectionView?.traitCollection.nonZeroDisplayScale ?? 1
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView else { return .zero }

        let with = collectionView.frame.width
        let numberOfSections = state.currentSections.count
        let height: CGFloat
        if numberOfSections <= 0 {
            height = 0
        } else {
            height = state.currentSections[numberOfSections - 1].frameWithMargin().maxY
        }
        return CGSize(width: with, height: height)
    }

    // MARK: - Нужно ли инвалидировать

    override func shouldInvalidateLayout(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> Bool {
        false
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    // MARK: - контекст

    override class var invalidationContextClass: AnyClass { CustomInvalidationContext.self }

    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let defaultContext = super.invalidationContext(forBoundsChange: newBounds)

        guard let invalidationContext = defaultContext as? CustomInvalidationContext else {
            fatalError("`context` must be an instance of `CustomInvalidationContext`")
        }

        invalidationContext.contentSizeAdjustment = CGSize(
            width: newBounds.width - currentBounds.width,
            height: newBounds.height - currentBounds.height
        )
        invalidationContext.invalidateLayoutMetrics = false

        return invalidationContext
    }

    override func invalidationContext(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutInvalidationContext {
        super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
    }

    override func invalidationContext(
        forInteractivelyMovingItems targetIndexPaths: [IndexPath],
        withTargetPosition targetPosition: CGPoint,
        previousIndexPaths: [IndexPath],
        previousPosition: CGPoint
    ) -> UICollectionViewLayoutInvalidationContext {
        super.invalidationContext(
            forInteractivelyMovingItems: targetIndexPaths,
            withTargetPosition: targetPosition,
            previousIndexPaths: previousIndexPaths,
            previousPosition: previousPosition
        )
    }

    override func invalidationContextForEndingInteractiveMovementOfItems(
        toFinalIndexPaths indexPaths: [IndexPath],
        previousIndexPaths: [IndexPath],
        movementCancelled: Bool
    ) -> UICollectionViewLayoutInvalidationContext {
        super.invalidationContextForEndingInteractiveMovementOfItems(
            toFinalIndexPaths: indexPaths,
            previousIndexPaths: previousIndexPaths,
            movementCancelled: movementCancelled
        )
    }

    // MARK: - Инвалидация

    override func invalidateLayout() {
        super.invalidateLayout()
    }

    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        guard let context = context as? CustomInvalidationContext else {
            fatalError("`context` must be an instance of `CustomInvalidationContext`")
        }

        let shouldInvalidateLayoutMetrics = !context.invalidateEverything && !context.invalidateDataSourceCounts

        if context.invalidateEverything {
            prepareActions.formUnion([.recreateSectionModels])
        }

        // Checking `cachedCollectionViewWidth != collectionView?.bounds.size.width` is necessary
        // because the collection view's width can change without a `contentSizeAdjustment` occurring.
        let isContentWidthAdjustmentZero = context.contentSizeAdjustment.width.isEqual(
            to: 0,
            threshold: 1 / scale
        )
        let isSameWidth = collectionView?.bounds.size.width.isEqual(
            to: cachedCollectionViewWidth ?? -.greatestFiniteMagnitude,
            threshold: 1 / scale
        ) ?? false
        if !isContentWidthAdjustmentZero || !isSameWidth {
            prepareActions.formUnion([.cachePreviousWidth])
        }

        if context.invalidateLayoutMetrics && shouldInvalidateLayoutMetrics {
            prepareActions.formUnion([.recreateSectionModels])
        }

        hasDataSourceCountInvalidationBeforeReceivingUpdateItems = context.invalidateDataSourceCounts && !context.invalidateEverything

        super.invalidateLayout(with: context)
    }

    // MARK: - подготовка к изменениям

    override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        super.prepare(forAnimatedBoundsChange: oldBounds)
    }

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        defer {
            super.prepare(forCollectionViewUpdates: updateItems)
        }
        guard
            let collectionView = collectionView,
            let delegate = delegate
        else { return }

        let contentWidth = collectionView.frame.width

        var updates = [ViewUpdate]()

        for updateItem in updateItems {
            let updateAction = updateItem.updateAction
            let indexPathBeforeUpdate = updateItem.indexPathBeforeUpdate
            let indexPathAfterUpdate = updateItem.indexPathAfterUpdate

            switch (updateAction, indexPathBeforeUpdate, indexPathAfterUpdate) {
            case (.delete, let indexPath?, _) where indexPath.item != NSNotFound:
                updates.append(.itemDelete(itemIndexPath: indexPath))
            case (.insert, _, let indexPath?) where indexPath.item != NSNotFound:
                let sectionConfiguration = delegate.getSectionConfig(sectionIndex: indexPath.section)
                let sectionWidth = contentWidth - sectionConfiguration.margin.left - sectionConfiguration.margin.right
                let sectionContentWidth = sectionWidth - sectionConfiguration.padding.left - sectionConfiguration.padding.right
                let item = makeItem(indexPath: indexPath, sectionContentWidth: sectionContentWidth, sectionConfiguration: sectionConfiguration, delegate: delegate)
                updates.append(.itemInsert(itemIndexPath: indexPath, newItem: item))
            default:
                break
            }
        }
        state.applyUpdates(updates: updates, contentWidth: contentWidth)
        hasDataSourceCountInvalidationBeforeReceivingUpdateItems = false
    }

    override func prepareForTransition(from oldLayout: UICollectionViewLayout) {
        super.prepareForTransition(from: oldLayout)
    }

    override func prepareForTransition(to newLayout: UICollectionViewLayout) {
        super.prepareForTransition(to: newLayout)
    }

    override func prepare() {
        super.prepare()

        guard let collectionView, let delegate, !prepareActions.isEmpty else { return }

        // Save the previous collection view width if necessary
        if prepareActions.contains(.cachePreviousWidth) {
            cachedCollectionViewWidth = currentBounds.width
        }

        if prepareActions.contains(.recreateSectionModels) {
            let contentWidth = collectionView.frame.width
            let sections = makeSections(view: collectionView, delegate: delegate, contentWidth: contentWidth)
            state.currentSections = sections
            state.rebuildFrames(contentWidth: contentWidth)
        }

        prepareActions = []
    }

    // MARK: - финализация изменений

    override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
    }

    override func finalizeCollectionViewUpdates() {
        state.clearInProgressBatchUpdateState()

        super.finalizeCollectionViewUpdates()
    }

    override func finalizeLayoutTransition() {
        super.finalizeLayoutTransition()
    }

    // MARK: - Атрибуты для элементов

    override class var layoutAttributesClass: AnyClass { CustomLayoutAttributes.self }

    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        guard !hasDataSourceCountInvalidationBeforeReceivingUpdateItems else { return nil }

        var layoutAttributesInRect = [UICollectionViewLayoutAttributes]()

        let items = state.items(inRect: rect)

        layoutAttributesInRect.append(contentsOf: items.sections.compactMap(sectionBackgroundAttributes))
        layoutAttributesInRect.append(contentsOf: items.sections.compactMap(headerLayoutAttributes))
        layoutAttributesInRect.append(contentsOf: items.items.compactMap(itemsLayoutAttributes))

        return layoutAttributesInRect
    }

    override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard !hasDataSourceCountInvalidationBeforeReceivingUpdateItems else { return nil }

        return itemsLayoutAttributes(indexPath: indexPath)
    }

    override func layoutAttributesForDecorationView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard !hasDataSourceCountInvalidationBeforeReceivingUpdateItems else { return nil }

        if elementKind == ExampleSectionBackgroundDecorationView.kind {
            return sectionBackgroundAttributes(section: indexPath.section)
        } else {
            return nil
        }

    }

    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard !hasDataSourceCountInvalidationBeforeReceivingUpdateItems else { return nil }

        if elementKind == ExampleHeader.kind {
            return headerLayoutAttributes(section: indexPath.section)
        } else {
            return nil
        }
    }

    override func layoutAttributesForInteractivelyMovingItem(
        at indexPath: IndexPath,
        withTargetPosition position: CGPoint
    ) -> UICollectionViewLayoutAttributes {
        super.layoutAttributesForInteractivelyMovingItem(at: indexPath, withTargetPosition: position)
    }

    // MARK: - Начальные атрибуты для элементов

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard state.itemIndexPathsToInsert.contains(itemIndexPath) else {
            return super.layoutAttributesForItem(at: itemIndexPath)
        }

        let attributes = layoutAttributesForItem(at: itemIndexPath)?.copy() as? CustomLayoutAttributes
        attributes?.frame.size.height = 0.0
        return attributes
    }

    override func initialLayoutAttributesForAppearingDecorationElement(
        ofKind elementKind: String,
        at decorationIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        super.initialLayoutAttributesForAppearingDecorationElement(ofKind: elementKind, at: decorationIndexPath)
    }

    override func initialLayoutAttributesForAppearingSupplementaryElement(
        ofKind elementKind: String,
        at elementIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        super.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath)
    }

    // MARK: - Финальные атрибуты для элементов

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard state.itemIndexPathsToDelete.contains(itemIndexPath) else {
            return super.layoutAttributesForItem(at: itemIndexPath)
        }

        let attributes = layoutAttributesForItem(at: itemIndexPath)?.copy() as? CustomLayoutAttributes
        attributes?.frame.size.height = 0.0
        return attributes
    }

    override func finalLayoutAttributesForDisappearingDecorationElement(
        ofKind elementKind: String,
        at decorationIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        super.finalLayoutAttributesForDisappearingDecorationElement(ofKind: elementKind, at: decorationIndexPath)
    }

    override func finalLayoutAttributesForDisappearingSupplementaryElement(
        ofKind elementKind: String,
        at elementIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        super.finalLayoutAttributesForDisappearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath)
    }

    // MARK: - Вставка декоративных элементов

    override func indexPathsToInsertForDecorationView(ofKind elementKind: String) -> [IndexPath] {
        super.indexPathsToInsertForDecorationView(ofKind: elementKind)
    }

    override func indexPathsToInsertForSupplementaryView(ofKind elementKind: String) -> [IndexPath] {
        super.indexPathsToInsertForSupplementaryView(ofKind: elementKind)
    }

    // MARK: - Удаление декоративных элементов

    override func indexPathsToDeleteForDecorationView(ofKind elementKind: String) -> [IndexPath] {
        super.indexPathsToDeleteForDecorationView(ofKind: elementKind)
    }

    override func indexPathsToDeleteForSupplementaryView(ofKind elementKind: String) -> [IndexPath] {
        super.indexPathsToDeleteForSupplementaryView(ofKind: elementKind)
    }

    override func targetIndexPath(forInteractivelyMovingItem previousIndexPath: IndexPath, withPosition position: CGPoint) -> IndexPath {
        super.targetIndexPath(forInteractivelyMovingItem: previousIndexPath, withPosition: position)
    }

    // MARK: - Изменение targetContentOffset

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        let defualtOffset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        guard let collectionView, let indexPath = state.itemIndexPathsToInsert.sorted().first else { return defualtOffset }

        let attributes = layoutAttributesForItem(at: indexPath)
        var offset = (attributes?.frame.maxY ?? 0) - collectionView.frame.height + state.currentSections[indexPath.section].configuration.itemPadding.bottom
        if indexPath.item == state.currentSections[indexPath.section].items.count - 1 {
            offset += state.currentSections[indexPath.section].configuration.margin.bottom + state.currentSections[indexPath.section].configuration.padding.bottom
        }
        if proposedContentOffset.y < offset {
            return CGPoint(x: defualtOffset.x, y: offset)
        } else {
            return defualtOffset
        }

    }

    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }

    // MARK: - Сборка секций для состояний

    private func makeSections(
        view: UICollectionView,
        delegate: CustomLayoutDelegate,
        contentWidth: Double
    ) -> [Section] {
        guard view.numberOfSections > 0 else { return [] }

        var sections: [Section] = []

        for sectionIndex in 0..<view.numberOfSections {
            let sectionConfiguration = delegate.getSectionConfig(sectionIndex: sectionIndex)
            let sectionWidth = contentWidth - sectionConfiguration.margin.left - sectionConfiguration.margin.right
            let sectionContentWidth = sectionWidth - sectionConfiguration.padding.left - sectionConfiguration.padding.right

            var items: [CustomLayoutAttributes] = []
            for itemIndex in 0..<view.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                let item = makeItem(
                    indexPath: indexPath,
                    sectionContentWidth: sectionContentWidth,
                    sectionConfiguration: sectionConfiguration,
                    delegate: delegate
                )

                items.append(item)
            }

            let headerAttributes: CustomLayoutAttributes?
            if let header = sectionConfiguration.header {
                headerAttributes = CustomLayoutAttributes(
                    forSupplementaryViewOfKind: ExampleHeader.kind,
                    with: IndexPath(item: 0, section: sectionIndex)
                )
                headerAttributes?.framInSection = CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: contentWidth - header.padding.left,
                        height: header.height
                    )
                )
            } else {
                headerAttributes = nil
            }


            let section = Section(
                items: items,
                header: headerAttributes,
                background: CustomLayoutAttributes(
                    forDecorationViewOfKind: ExampleSectionBackgroundDecorationView.kind,
                    with: IndexPath(item: 0, section: sectionIndex)
                ),
                configuration: sectionConfiguration
            )
            sections.append(section)
        }

        return sections
    }

    private func makeItem(
        indexPath: IndexPath,
        sectionContentWidth: Double,
        sectionConfiguration: SectionConfiguration,
        delegate: CustomLayoutDelegate
    ) -> CustomLayoutAttributes {
        let item = CustomLayoutAttributes(forCellWith: indexPath)
        let itemWidth = (sectionContentWidth - Double(sectionConfiguration.numberOfCollumn) * (sectionConfiguration.itemPadding.left + sectionConfiguration.itemPadding.right)) / Double(sectionConfiguration.numberOfCollumn)
        let itemConfiguration = delegate.getCellConfig(indexPath: indexPath, width: itemWidth)
        item.framInSection.size = CGSize(
            width: itemWidth,
            height: itemConfiguration.itemSize.height
        )
        return item
    }

    // MARK: - Сборка атрибутов

    private func sectionBackgroundAttributes(section: Int) -> UICollectionViewLayoutAttributes? {
        guard section < state.currentSections.count  else { return nil }

        let layoutAttributes = state.currentSections[section].background
        layoutAttributes.frame = state.currentSections[section].frame
        layoutAttributes.zIndex = -1

        return layoutAttributes
    }

    private func headerLayoutAttributes(section: Int) -> UICollectionViewLayoutAttributes? {
        guard
            let collectionView,
            section < state.currentSections.count,
            let padding = state.currentSections[section].configuration.header?.padding,
            let header = state.currentSections[section].header
        else { return nil }
        header.frame = header.framInSection
        header.frame.origin.x = state.currentSections[section].frame.origin.x + header.framInSection.origin.x
        header.frame.origin.y = state.currentSections[section].frame.origin.y + header.framInSection.origin.y

        if header.frame.origin.y + padding.top < collectionView.contentOffset.y {
            header.frame.origin.y = collectionView.contentOffset.y + padding.top
            let maxY = state.currentSections[section].frame.maxY - (header.frame.height + padding.bottom)
            header.frame.origin.y = min(header.frame.origin.y, maxY)
        }
        header.zIndex = state.currentSections[section].items.count + 1

        return header
    }

    private func itemsLayoutAttributes(indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard
            indexPath.section < state.currentSections.count,
            indexPath.item < state.currentSections[indexPath.section].items.count
        else { return nil }

        let layoutAttributes = state.currentSections[indexPath.section].items[indexPath.item]
        layoutAttributes.frame = layoutAttributes.framInSection


        layoutAttributes.frame.origin.x = state.currentSections[indexPath.section].frame.origin.x + layoutAttributes.framInSection.origin.x
        layoutAttributes.frame.origin.y = state.currentSections[indexPath.section].frame.origin.y + layoutAttributes.framInSection.origin.y

        layoutAttributes.zIndex = state.currentSections[indexPath.section].items.count - indexPath.item

        return layoutAttributes
    }

}

private class CustomInvalidationContext: UICollectionViewLayoutInvalidationContext {
    var invalidateLayoutMetrics = true
}


private class CustomLayoutAttributes: UICollectionViewLayoutAttributes {
    var framInSection: CGRect = .zero
}


private class CustomLayoutState {
    fileprivate var currentSections: [Section] = []
    private(set) var isPerformingBatchUpdates: Bool = false
    private(set) var itemIndexPathsToInsert = Set<IndexPath>()
    private(set) var itemIndexPathsToDelete = Set<IndexPath>()

    func rebuildFrames(contentWidth: Double) {
        currentSections.indices.forEach { rebuildSectionFrame(sectionIndex: $0, startAtItemIndex: 0, contentWidth: contentWidth) }
    }

    private func rebuildSectionFrame(
        sectionIndex: Int,
        startAtItemIndex startItemIndex: Int,
        contentWidth: Double
    ) {

        let sectionConfiguration = currentSections[sectionIndex].configuration
        let startItemIndex = startItemIndex / sectionConfiguration.numberOfCollumn * sectionConfiguration.numberOfCollumn
        let rowIndex = startItemIndex / sectionConfiguration.numberOfCollumn
        let sectionWidth = contentWidth - sectionConfiguration.margin.left - sectionConfiguration.margin.right
        let sectionContentWidth = sectionWidth - sectionConfiguration.padding.left - sectionConfiguration.padding.right

        if rowIndex == 0 {
            rebuildInitialFrame()
            currentSections[sectionIndex].appendHeight(sectionConfiguration.padding.top)
            rebuildHeader()
        } else {
            shrinkHeightTo(rowIndex)
        }

        var rowVericalOffset = 0.0
        for itemIndex in startItemIndex..<currentSections[sectionIndex].items.count {
            let indexInRow = itemIndex % sectionConfiguration.numberOfCollumn

            let itemWidth = currentSections[sectionIndex].items[itemIndex].framInSection.width

            if indexInRow == 0 {
                currentSections[sectionIndex].appendHeight(sectionConfiguration.itemPadding.top)
            }

            let itemsHorisontalPadding = Double(indexInRow) * itemWidth + Double(indexInRow) * (sectionConfiguration.itemPadding.left + sectionConfiguration.itemPadding.right) + sectionConfiguration.itemPadding.left + sectionConfiguration.padding.left

            currentSections[sectionIndex].items[itemIndex].framInSection.origin = CGPoint(
                x: itemsHorisontalPadding,
                y: currentSections[sectionIndex].verticalOffset
            )
            currentSections[sectionIndex].items[itemIndex].indexPath.item = itemIndex
            rowVericalOffset = max(currentSections[sectionIndex].items[itemIndex].framInSection.height, rowVericalOffset)
            if indexInRow == sectionConfiguration.numberOfCollumn - 1 || itemIndex == currentSections[sectionIndex].items.count - 1 {
                currentSections[sectionIndex].appendHeight(rowVericalOffset + sectionConfiguration.itemPadding.bottom)
                rowVericalOffset = 0.0
            }
        }

        currentSections[sectionIndex].appendHeight(sectionConfiguration.padding.bottom)

        func rebuildInitialFrame() {
            rebuildSectionOrigin(sectionIndex: sectionIndex)

            currentSections[sectionIndex].frame.size.height = 0
            currentSections[sectionIndex].frame.size.width = sectionWidth
        }

        func rebuildHeader() {
            guard let header = currentSections[sectionIndex].configuration.header else { return }

            currentSections[sectionIndex].appendHeight(header.padding.top)
            currentSections[sectionIndex].header?.framInSection = CGRect(
                x: currentSections[sectionIndex].configuration.padding.left + header.padding.left,
                y: currentSections[sectionIndex].verticalOffset,
                width: sectionContentWidth - header.padding.left - header.padding.right,
                height: header.height
            )

            currentSections[sectionIndex].appendHeight(header.height + header.padding.bottom)
        }

        func shrinkHeightTo(_ rowIndex: Int) {
            guard rowIndex > 0 else { fatalError() }
            let rowIndex = rowIndex - 1
            let rowIndexGap = rowIndex * currentSections[sectionIndex].configuration.numberOfCollumn
            let rowHeight = (0..<currentSections[sectionIndex].configuration.numberOfCollumn)
                .map { rowIndexGap + $0 }
                .map { currentSections[sectionIndex].items[$0].framInSection.maxY }
                .max() ?? 0
            let height = rowHeight + currentSections[sectionIndex].configuration.itemPadding.bottom

            currentSections[sectionIndex].frame.size.height = height
        }
    }

    private func rebuildSectionOrigin(sectionIndex: Int) {

        let previousFrameWithMargin = currentSections.safeElement(sectionIndex - 1)?.frameWithMargin() ?? .zero

        currentSections[sectionIndex].frame.origin = CGPoint(
            x: currentSections[sectionIndex].configuration.margin.left,
            y: previousFrameWithMargin.maxY + currentSections[sectionIndex].configuration.margin.top
        )
    }

    // MARK: - update elements

    func applyUpdates(
        updates: [ViewUpdate],
        contentWidth: Double
    ) {


        typealias ItemWithIndex = (item: CustomLayoutAttributes, index: IndexPath)

        isPerformingBatchUpdates = true

        var itemIndexPathsToDelete = [IndexPath]()
        var itemModelInsertIndexPathPairs = [ItemWithIndex]()

        for update in updates {
            switch update {
            case let .itemDelete(itemIndexPath):
                itemIndexPathsToDelete.append(itemIndexPath)
                self.itemIndexPathsToDelete.insert(itemIndexPath)
            case let .itemInsert(itemIndexPath, newItem):
                itemModelInsertIndexPathPairs.append((newItem, itemIndexPath))
                itemIndexPathsToInsert.insert(itemIndexPath)
            }
        }

        var updateTracker = UpdateTracker()

        for itemIndex in itemIndexPathsToDelete.sorted(by: { $0 > $1 }) {
            currentSections[itemIndex.section].items.remove(at: itemIndex.item)
            updateTracker.add(itemIndex: itemIndex)
        }

        for update in itemModelInsertIndexPathPairs.sorted(by: { $0.index < $1.index }) {
            currentSections[update.index.section].items.insert(update.item, at: update.index.item)
            updateTracker.add(itemIndex: update.index)
        }

        for itemIndex in updateTracker.minItemsToRebuild() {
            rebuildSectionFrame(sectionIndex: itemIndex.section, startAtItemIndex: itemIndex.item, contentWidth: contentWidth)
        }

        if
            let sectionIndex = updateTracker.minSectionToRebuild(),
            sectionIndex < currentSections.count
        {
            (sectionIndex..<currentSections.count).forEach(rebuildSectionOrigin)
        }
    }

    func clearInProgressBatchUpdateState() {
        itemIndexPathsToInsert.removeAll()
        itemIndexPathsToDelete.removeAll()

        isPerformingBatchUpdates = false
    }

    // MARK: - Find elements by rect

    func items(
        inRect rect: CGRect
    ) -> ItemIndexesInRect {

        var itemIndexesInRect = ItemIndexesInRect()

        let sectionIndexes = sections(inRect: rect)
        itemIndexesInRect.sections = sectionIndexes

        if sectionIndexes.count > 2 {
            let itemIndexes = sectionIndexes[1..<sectionIndexes.count-1].flatMap { section in currentSections[section].items.indices.map { item in IndexPath(row: item, section: section) } }
            itemIndexesInRect.items.append(contentsOf: itemIndexes)
        }

        if
            sectionIndexes.count > 1,
            let sectionIndex = sectionIndexes.last,
            let rectInSection = rectInSection(sectionIndex: sectionIndex, rect: rect),
            let lastIndex = currentSections[sectionIndex].items.lastIndex(where: { $0.framInSection.minY < rectInSection.maxY })
        {
            let itemIndexes = (0...lastIndex).map { IndexPath(item: $0, section: sectionIndex) }
            itemIndexesInRect.items.append(contentsOf: itemIndexes)
        }

        if
            let sectionIndex = sectionIndexes.first,
            let rectInSection = rectInSection(sectionIndex: sectionIndex, rect: rect),
            let firstIndex = currentSections[sectionIndex].items.firstIndex(where: { $0.framInSection.maxY > rectInSection.minY })
        {
            let itemIndexes = (firstIndex..<currentSections[sectionIndex].items.count).map { IndexPath(item: $0, section: sectionIndex) }
            itemIndexesInRect.items.append(contentsOf: itemIndexes)
        }

        return itemIndexesInRect
    }

    private func rectInSection(sectionIndex: Int, rect: CGRect) -> CGRect? {
        let sectionFrame = currentSections[sectionIndex].frame
        var intersectionsRect = rect.intersection(sectionFrame)

        if rect.origin.y > sectionFrame.origin.y {
            intersectionsRect.origin.y = rect.origin.y - sectionFrame.origin.y
        } else {
            intersectionsRect.origin.y = 0
        }
        return intersectionsRect
    }

    private func sections(inRect rect: CGRect) -> [Int] {
        guard let firstFoundSection = indexOfFirstFoundSection(in: rect) else { return [] }

        var sections: [Int] = []
        sections.reserveCapacity(currentSections.count)

        for sectionIndex in stride(from: firstFoundSection - 1, through: 0, by: -1) {
            let frame = currentSections[sectionIndex].frame
            if frame.maxY > rect.minY {
                sections.append(sectionIndex)
            } else {
                break
            }
        }

        sections.reverse()

        for sectionIndex in firstFoundSection..<currentSections.count {
            let frame = currentSections[sectionIndex].frame
            if frame.minY < rect.maxY {
                sections.append(sectionIndex)
            } else {
                break
            }
        }

        return sections
    }

    private func indexOfFirstFoundSection(
        in rect: CGRect
    ) -> Int? {
        var lowerBound = 0
        var upperBound = currentSections.count - 1

        while lowerBound <= upperBound {
            let sectionIndex = (lowerBound + upperBound) / 2

            let sectionFrame = currentSections[sectionIndex].frame
            if sectionFrame.maxY <= rect.minY {
                lowerBound = sectionIndex + 1
            } else if sectionFrame.minY >= rect.maxY {
                upperBound = sectionIndex - 1
            } else {
                return sectionIndex
            }
        }

        return nil
    }

}

private struct Section {
    var items: [CustomLayoutAttributes]
    var header: CustomLayoutAttributes?
    var background: CustomLayoutAttributes
    var frame: CGRect = .zero
    let configuration: SectionConfiguration

    var verticalOffset: Double { frame.height }

    func frameWithMargin() -> CGRect {
        frame
            .inset(
                by: UIEdgeInsets(
                    top: -configuration.margin.top,
                    left: -configuration.margin.left,
                    bottom: -configuration.margin.bottom,
                    right: -configuration.margin.right
                )
            )
    }

    mutating func appendHeight(_ height: Double) {
        frame.size.height += height
    }
}


private struct PrepareActions: OptionSet {
    let rawValue: UInt

    static let recreateSectionModels = PrepareActions(rawValue: 1 << 0)
    static let cachePreviousWidth = PrepareActions(rawValue: 1 << 1)
}

private extension CGFloat {

    /// Rounds `self` so that it's aligned on a pixel boundary for a screen with the provided scale.
    func alignedToPixel(forScreenWithScale scale: CGFloat) -> CGFloat {
        (self * scale).rounded() / scale
    }

    /// Tests `self` for approximate equality using the threshold value. For example, 1.48 equals 1.52 if the threshold is 0.05.
    /// `threshold` will be treated as a positive value by taking its absolute value.
    func isEqual(to rhs: CGFloat, threshold: CGFloat) -> Bool {
        abs(self - rhs) <= abs(threshold)
    }

}

private extension UITraitCollection {

    // The documentation mentions that 0 is a possible value, so we guard against this.
    // It's unclear whether values between 0 and 1 are possible, otherwise `max(scale, 1)` would
    // suffice.
    var nonZeroDisplayScale: CGFloat {
        displayScale > 0 ? displayScale : 1
    }

}

private struct ItemIndexesInRect {
    var sections: [Int] = []
    var items: [IndexPath] = []
}


private enum ViewUpdate {

    case itemDelete(itemIndexPath: IndexPath)
    case itemInsert(itemIndexPath: IndexPath, newItem: CustomLayoutAttributes)

}

private struct UpdateTracker {

    private var minItemIndexes: [Int: Int] = [:]

    mutating func add(itemIndex: IndexPath) {
        switch minItemIndexes[itemIndex.section] {
        case .none:
            minItemIndexes[itemIndex.section] = itemIndex.item
        case let currentMinItemIndex? where itemIndex.item < currentMinItemIndex:
            minItemIndexes[itemIndex.section] = itemIndex.item
        default:
            break
        }
    }

    func minSectionToRebuild() -> Int? {
        minItemIndexes.keys.min()
    }

    func minItemsToRebuild() -> [IndexPath] {
        minItemIndexes.keys.sorted().map { IndexPath(item: minItemIndexes[$0]!, section: $0) }
    }

}
