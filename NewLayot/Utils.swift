import Foundation

extension Collection where Index == Int {

    func safeElement(_ index: Index) -> Element? {
        index >= 0 && index < count ? self[index] : nil
    }

}
