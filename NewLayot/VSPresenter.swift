import SwiftUI

struct VCPresenter: UIViewControllerRepresentable {
    let vcFactiry: () -> UIViewController

    init(_ vcFactiry: @escaping () -> UIViewController) {
        self.vcFactiry = vcFactiry
    }

    func makeUIViewController(context: Context) -> UIViewController {
        vcFactiry()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
