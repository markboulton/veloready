import SwiftUI
import UIKit

/// UIScrollView wrapper with elastic pull-to-refresh
struct ElasticScrollView<Content: View>: UIViewControllerRepresentable {
    let content: Content
    let onRefresh: () async -> Void
    
    init(onRefresh: @escaping () async -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onRefresh = onRefresh
    }
    
    func makeUIViewController(context: Context) -> ElasticScrollViewController<Content> {
        let controller = ElasticScrollViewController(
            content: content,
            onRefresh: onRefresh
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ElasticScrollViewController<Content>, context: Context) {
        uiViewController.updateContent(content)
    }
}

/// View controller managing the scroll view and refresh control
class ElasticScrollViewController<Content: View>: UIViewController, UIScrollViewDelegate {
    
    private let scrollView = UIScrollView()
    private let refreshControl = ElasticRefreshControl()
    private var hostingController: UIHostingController<Content>!
    private let onRefresh: () async -> Void
    
    private let config = PullToRefreshConfig()
    private var isTracking = false
    private var initialContentOffset: CGFloat = 0
    
    init(content: Content, onRefresh: @escaping () async -> Void) {
        self.onRefresh = onRefresh
        super.init(nibName: nil, bundle: nil)
        
        // Setup hosting controller
        hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupRefreshControl()
        setupContent()
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.backgroundColor = .clear
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupRefreshControl() {
        refreshControl.configure(onRefresh: onRefresh)
        refreshControl.frame = CGRect(x: 0, y: -100, width: view.bounds.width, height: 100)
        scrollView.addSubview(refreshControl)
    }
    
    private func setupContent() {
        addChild(hostingController)
        scrollView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        // Force layout to calculate proper content size
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update hosting controller size
        let targetSize = CGSize(width: scrollView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = hostingController.sizeThatFits(in: targetSize)
        
        // Update content size if needed
        if scrollView.contentSize.height != size.height {
            scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: size.height)
        }
    }
    
    func updateContent(_ content: Content) {
        hostingController.rootView = content
        view.setNeedsLayout()
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isTracking = true
        initialContentOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isTracking else { return }
        
        let offsetY = scrollView.contentOffset.y
        let pullDistance = max(0, -offsetY - scrollView.adjustedContentInset.top)
        
        // Only update if pulling from top
        if offsetY < -scrollView.adjustedContentInset.top {
            // Calculate elastic offset
            let elasticOffset = config.elasticOffset(for: pullDistance)
            
            // Update refresh control
            refreshControl.updatePull(distance: pullDistance, velocity: 0)
            
            // Position refresh control
            let refreshY = -elasticOffset - 100
            refreshControl.frame.origin.y = refreshY
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        isTracking = false
        
        let offsetY = scrollView.contentOffset.y
        let pullDistance = max(0, -offsetY - scrollView.adjustedContentInset.top)
        let progress = config.progress(for: pullDistance)
        
        if progress >= 1.0 {
            // Trigger refresh - lock position
            targetContentOffset.pointee.y = -scrollView.adjustedContentInset.top - config.triggerThreshold
            
            // Add overshoot animation
            let overshootOffset = -scrollView.adjustedContentInset.top - config.triggerThreshold - config.overshootDistance
            
            UIView.animate(
                withDuration: 0.15,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0,
                options: [.curveEaseOut]
            ) {
                scrollView.contentOffset.y = overshootOffset
            } completion: { _ in
                // Settle to refresh position
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    usingSpringWithDamping: 0.75,
                    initialSpringVelocity: 0
                ) {
                    scrollView.contentOffset.y = -scrollView.adjustedContentInset.top - self.config.triggerThreshold
                }
                
                self.refreshControl.beginRefreshing()
            }
        } else {
            // Snap back
            refreshControl.updatePull(distance: 0, velocity: velocity.y)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isTracking = false
    }
}
