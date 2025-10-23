import SwiftUI

/// Generic score card for Recovery, Sleep, Strain, etc.
/// Fully composable using atomic components
/// Usage: ScoreCard(config: .recovery(score: 92))
struct ScoreCard: View {
    let config: Configuration
    let onTap: (() -> Void)?
    
    struct Configuration {
        let title: String
        let subtitle: String?
        let score: Int
        let label: String
        let icon: String
        let color: Color
        let badgeText: String
        let badgeStyle: VRBadge.Style
        let footerText: String?
        let change: CardMetric.Change?
        
        // MARK: - Convenience Initializers
        
        /// Recovery Score configuration
        static func recovery(
            score: Int,
            band: RecoveryBand,
            change: CardMetric.Change? = nil,
            footerText: String? = "Updated recently"
        ) -> Configuration {
            Configuration(
                title: CommonContent.recovery.title,
                subtitle: "Based on HRV, RHR, Sleep",
                score: score,
                label: band.rawValue,
                icon: "arrow.clockwise",
                color: band.colorToken,
                badgeText: band.rawValue.uppercased(),
                badgeStyle: band.badgeStyle,
                footerText: footerText,
                change: change
            )
        }
        
        /// Sleep Score configuration
        static func sleep(
            score: Int,
            band: SleepBand,
            change: CardMetric.Change? = nil,
            footerText: String? = "From Apple Health"
        ) -> Configuration {
            Configuration(
                title: CommonContent.sleep.title,
                subtitle: "Quality, Duration, Consistency",
                score: score,
                label: band.rawValue,
                icon: "bed.double.fill",
                color: band.colorToken,
                badgeText: band.rawValue.uppercased(),
                badgeStyle: band.badgeStyle,
                footerText: footerText,
                change: change
            )
        }
        
        /// Strain Score configuration
        static func strain(
            score: Double,
            footerText: String? = "Today's training load"
        ) -> Configuration {
            let band = StrainBand.fromScore(score)
            return Configuration(
                title: CommonContent.strain.title,
                subtitle: "Training Load",
                score: Int(score),
                label: band.rawValue,
                icon: "flame.fill",
                color: band.colorToken,
                badgeText: band.rawValue.uppercased(),
                badgeStyle: band.badgeStyle,
                footerText: footerText,
                change: nil
            )
        }
    }
    
    init(config: Configuration, onTap: (() -> Void)? = nil) {
        self.config = config
        self.onTap = onTap
    }
    
    var body: some View {
        if let onTap = onTap {
            Button(action: onTap) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            cardContent
        }
    }
    
    private var cardContent: some View {
        CardContainer(
            header: CardHeader(
                title: config.title,
                subtitle: config.subtitle,
                badge: .init(text: config.badgeText, style: config.badgeStyle),
                action: onTap != nil ? .init(icon: Icons.System.chevronRight, action: onTap!) : nil
            ),
            footer: config.footerText != nil ? CardFooter(text: config.footerText) : nil
        ) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: config.icon)
                    .font(.system(size: 36))
                    .foregroundColor(config.color)
                
                CardMetric(
                    value: "\(config.score)",
                    label: config.label,
                    change: config.change,
                    size: .large
                )
            }
        }
    }
}

// MARK: - Band Extensions

extension RecoveryBand {
    var badgeStyle: VRBadge.Style {
        switch self {
        case .optimal: return .success
        case .good: return .info
        case .fair: return .warning
        case .poor: return .error
        }
    }
}

extension SleepBand {
    var badgeStyle: VRBadge.Style {
        switch self {
        case .optimal: return .success
        case .good: return .info
        case .fair: return .warning
        case .poor: return .error
        }
    }
}

extension StrainBand {
    var badgeStyle: VRBadge.Style {
        switch self {
        case .veryLow, .low: return .success
        case .moderate: return .info
        case .high: return .warning
        case .veryHigh: return .error
        }
    }
    
    static func fromScore(_ score: Double) -> StrainBand {
        if score >= 18 { return .veryHigh }
        if score >= 14 { return .high }
        if score >= 10 { return .moderate }
        if score >= 5 { return .low }
        return .veryLow
    }
}

// MARK: - Preview

#Preview("Recovery Score") {
    VStack(spacing: 20) {
        ScoreCard(
            config: .recovery(
                score: 92,
                band: .optimal,
                change: .init(value: "+5", direction: .up)
            ),
            onTap: {}
        )
        
        ScoreCard(
            config: .recovery(
                score: 65,
                band: .fair,
                change: .init(value: "-8", direction: .down)
            ),
            onTap: {}
        )
    }
    .padding()
}

#Preview("Sleep Score") {
    VStack(spacing: 20) {
        ScoreCard(
            config: .sleep(
                score: 96,
                band: .optimal,
                change: .init(value: "+4", direction: .up)
            ),
            onTap: {}
        )
        
        ScoreCard(
            config: .sleep(
                score: 72,
                band: .good
            ),
            onTap: {}
        )
    }
    .padding()
}

#Preview("Strain Score") {
    VStack(spacing: 20) {
        ScoreCard(
            config: .strain(score: 15.5),
            onTap: {}
        )
        
        ScoreCard(
            config: .strain(score: 8.2),
            onTap: {}
        )
    }
    .padding()
}

#Preview("All Scores") {
    ScrollView {
        VStack(spacing: 20) {
            ScoreCard(
                config: .recovery(
                    score: 92,
                    band: .optimal,
                    change: .init(value: "+5", direction: .up)
                ),
                onTap: {}
            )
            
            ScoreCard(
                config: .sleep(
                    score: 88,
                    band: .good,
                    change: .init(value: "-3", direction: .down)
                ),
                onTap: {}
            )
            
            ScoreCard(
                config: .strain(score: 12.5),
                onTap: {}
            )
        }
        .padding()
    }
}

#Preview("Without Action") {
    VStack(spacing: 20) {
        ScoreCard(
            config: .recovery(score: 85, band: .good)
        )
        
        ScoreCard(
            config: .sleep(score: 92, band: .optimal)
        )
    }
    .padding()
}
