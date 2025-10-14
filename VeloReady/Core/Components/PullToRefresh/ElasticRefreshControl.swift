import UIKit
import SwiftUI

/// Custom UIRefreshControl with elastic physics and full control
class ElasticRefreshControl: UIControl {
    
    // MARK: - Configuration
    
    private let config = PullToRefreshConfig()
    private var refreshState: PullToRefreshState = .idle {
        didSet {
            if oldValue != refreshState {
                updateIndicator()
                triggerHaptics(oldValue: oldValue, newValue: refreshState)
                announceStateChange()
            }
        }
    }
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    private let indicatorView = UIView()
    private let progressLayer = CAShapeLayer()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let checkmarkImageView = UIImageView()
    private let statusLabel = UILabel()
    
    // MARK: - State
    
    private var pullDistance: CGFloat = 0
    private var isRefreshing = false
    private var onRefresh: (() async -> Void)?
    
    // MARK: - Haptics
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let successHaptic = UINotificationFeedbackGenerator()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Container
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Indicator view
        containerView.addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress circle layer
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.lineWidth = 2
        progressLayer.lineCap = .round
        indicatorView.layer.addSublayer(progressLayer)
        
        // Spinner
        spinner.color = .systemBlue
        spinner.hidesWhenStopped = true
        indicatorView.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        // Checkmark
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = .white
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.alpha = 0
        indicatorView.addSubview(checkmarkImageView)
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Status label
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.alpha = 0
        containerView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            indicatorView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            indicatorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            indicatorView.widthAnchor.constraint(equalToConstant: 32),
            indicatorView.heightAnchor.constraint(equalToConstant: 32),
            
            spinner.centerXAnchor.constraint(equalTo: indicatorView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: indicatorView.centerYAnchor),
            
            checkmarkImageView.centerXAnchor.constraint(equalTo: indicatorView.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: indicatorView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 16),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 16),
            
            statusLabel.topAnchor.constraint(equalTo: indicatorView.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
        
        // Initial state
        alpha = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateProgressCircle()
    }
    
    // MARK: - Public API
    
    func configure(onRefresh: @escaping () async -> Void) {
        self.onRefresh = onRefresh
    }
    
    func updatePull(distance: CGFloat, velocity: CGFloat) {
        guard !isRefreshing else { return }
        
        pullDistance = distance
        let progress = config.progress(for: distance)
        
        // Update refreshState
        if distance <= 0 {
            if refreshState.isPulling {
                // Released
                if progress >= 1.0 {
                    beginRefreshing()
                } else {
                    resetToIdle()
                }
            }
        } else {
            // Pulling
            if progress >= 1.0 {
                if case .armed = refreshState {
                    // Already armed
                } else {
                    refreshState = .armed
                }
            } else {
                refreshState = .pulling(progress: progress)
            }
            
            // Update UI
            alpha = min(1.0, progress * 2)
            updateProgressCircle()
        }
    }
    
    func beginRefreshing() {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshState = .refreshing
        
        // Execute refresh
        Task {
            await onRefresh?()
            await MainActor.run {
                endRefreshing()
            }
        }
    }
    
    func endRefreshing() {
        isRefreshing = false
        
        // Show completion
        refreshState = .completed
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.resetToIdle()
        }
    }
    
    private func resetToIdle() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            self.alpha = 0
        } completion: { _ in
            self.refreshState = .idle
            self.pullDistance = 0
        }
    }
    
    // MARK: - UI Updates
    
    private func updateIndicator() {
        switch refreshState {
        case .idle:
            progressLayer.isHidden = true
            spinner.stopAnimating()
            checkmarkImageView.alpha = 0
            statusLabel.alpha = 0
            
        case .pulling(let progress):
            progressLayer.isHidden = false
            progressLayer.strokeEnd = progress
            spinner.stopAnimating()
            checkmarkImageView.alpha = 0
            statusLabel.text = progress < 0.9 ? "Pull to refresh" : "Release to refresh"
            statusLabel.alpha = 1
            
        case .armed:
            progressLayer.isHidden = false
            progressLayer.strokeEnd = 1.0
            progressLayer.fillColor = UIColor.systemBlue.cgColor
            spinner.stopAnimating()
            checkmarkImageView.alpha = 0
            statusLabel.text = "Release to refresh"
            statusLabel.alpha = 1
            
        case .refreshing:
            progressLayer.isHidden = true
            spinner.startAnimating()
            checkmarkImageView.alpha = 0
            statusLabel.text = "Refreshing…"
            statusLabel.alpha = 1
            
        case .completed:
            progressLayer.isHidden = true
            spinner.stopAnimating()
            
            // Animate checkmark
            checkmarkImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0) {
                self.checkmarkImageView.alpha = 1
                self.checkmarkImageView.transform = .identity
            }
            
            statusLabel.text = "Updated"
            statusLabel.alpha = 1
        }
    }
    
    private func updateProgressCircle() {
        let center = CGPoint(x: indicatorView.bounds.midX, y: indicatorView.bounds.midY)
        let radius: CGFloat = 12
        
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )
        
        progressLayer.path = path.cgPath
        progressLayer.frame = indicatorView.bounds
    }
    
    // MARK: - Haptics
    
    private func triggerHaptics(oldValue: PullToRefreshState, newValue: PullToRefreshState) {
        if case .armed = newValue, case .pulling = oldValue {
            lightHaptic.impactOccurred(intensity: 0.5)
        } else if case .pulling = newValue, case .armed = oldValue {
            lightHaptic.impactOccurred(intensity: 0.3)
        } else if case .completed = newValue {
            successHaptic.notificationOccurred(.success)
        }
    }
    
    // MARK: - Accessibility
    
    private func announceStateChange() {
        let announcement: String
        switch refreshState {
        case .idle:
            return
        case .pulling(let progress):
            announcement = progress < 0.9 ? "Pull to refresh" : "Release to refresh"
        case .armed:
            announcement = "Release to refresh"
        case .refreshing:
            announcement = "Refreshing"
        case .completed:
            announcement = "Refreshed"
        }
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}
