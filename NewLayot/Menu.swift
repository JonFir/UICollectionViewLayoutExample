import SwiftUI

struct Menu: View {
    var body: some View {
        NavigationStack {
            List {
                link("FlowLayoutVC", makeFlowLayoutVC)
                link("CompositionalLayoutVC", makeCompositionalLayoutVC)
                link("CompositionalLayoutSectionProviderVC", makeCompositionalLayoutSectionProviderVC)
                link("custom layout minimal", makeCustomLayoutVC1Minimal)
                link("custom layout two column", CustomLayoutVC2TwoColumn)
                link("custom layout different cell size", makeDifferentCellSize)
                link("custom layout prepare", makeCustomLayoutVC4Prepare)
                link("custom layout section bg", makeCustomLayoutVC5SectionBG)
                link("custom layout float header", makeCustomLayoutVCFloatHeader)
                link("custom layout state machine", makeCustomLayoutVC6StateMachine)
                link("custom layout insert delete", makeCustomLayoutVC8InsertDelete)
                link("custom layout scroll to insert", CustomLayoutVC9ScrollToInsert)
                link("custom layout animations", CustomLayoutVC10Animations)
            }
        }
    }

    private func link(_ label: String, _ f: @escaping () -> UIViewController) -> NavigationLink<Text, VCPresenter> {
        NavigationLink(label) {
            VCPresenter(f)
        }
    }
}
