import UIKit

/// Ralli hides the system navigation bar for its own editorial headers, which also turns off
/// the edge swipe to go back. This restores the swipe everywhere a page was pushed,
/// except while a practice session is running (so a stray swipe on court can't leave it).
enum SwipeBack {
    @MainActor static var isBlocked = false
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === interactivePopGestureRecognizer else { return true }
        return viewControllers.count > 1 && !SwipeBack.isBlocked
    }
}
