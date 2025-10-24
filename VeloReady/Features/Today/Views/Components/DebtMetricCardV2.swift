import SwiftUI

/// Debt metric card using atomic components
/// Shows recovery debt or sleep debt with clear visualization
struct DebtMetricCardV2: View {
    enum DebtType {
        case recovery(RecoveryDebt)
        case sleep(SleepDebt)
        
        var title: String {
            switch self {
            case .recovery: return TodayContent.DebtMetrics.recoveryDebt
            case .sleep: return TodayContent.DebtMetrics.sleepDebt
            }
        }
        
        var icon: String {
            switch self {
            case .recovery: return "bolt.heart.fill"
            case .sleep: return "moon.zzz.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .recovery(let debt): return debt.band.colorToken
            case .sleep(let debt): return debt.band.colorToken
            }
        }
        
        var bandName: String {
            switch self {
            case .recovery(let debt): return debt.band.rawValue
            case .sleep(let debt): return debt.band.rawValue
            }
        }
        
        var badgeStyle: VRBadge.Style {
            // Map severity to badge style
            let band = bandName.lowercased()
            if band.contains("high") || band.contains("accumulat") {
                return .error
            } else if band.contains("moderate") {
                return .warning
            } else if band.contains("low") || band.contains("manag") {
                return .info
            }
            return .neutral
        }
        
        var description: String {
            switch self {
            case .recovery(let debt): return debt.band.description
            case .sleep(let debt): return debt.band.description
            }
        }
        
        var primaryValue: String {
            switch self {
            case .recovery(let debt): return "\(debt.consecutiveDays) \(TodayContent.DebtMetrics.daysLabel)"
            case .sleep(let debt): return String(format: "%.1fh", debt.totalDebtHours)
            }
        }
        
        var recommendation: String {
            switch self {
            case .recovery(let debt): return debt.band.recommendation
            case .sleep(let debt): return debt.band.recommendation
            }
        }
    }
    
    let debtType: DebtType
    let onTap: () -> Void
    
    var body: some View {
        CardContainer(
            header: CardHeader(
                title: debtType.title,
                subtitle: debtType.description,
                badge: .init(text: debtType.bandName.uppercased(), style: debtType.badgeStyle)
            ),
            style: .compact
        ) {
                HStack(spacing: Spacing.md) {
                    // Icon
                    Image(systemName: debtType.icon)
                        .font(.title2)
                        .foregroundColor(debtType.color)
                        .frame(width: 40, height: 40)
                        .background(debtType.color.opacity(0.15))
                        .cornerRadius(10)
                    
                    // Value
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        VRText(debtType.primaryValue, style: .title2, color: debtType.color)
                        VRText(debtType.recommendation, style: .caption, color: Color.text.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
            }
    }
}

// MARK: - Preview

#Preview("Recovery Debt") {
    let recoveryDebt = RecoveryDebt(
        consecutiveDays: 3,
        band: .accumulating,
        averageRecoveryScore: 55.0,
        calculatedAt: Date()
    )
    
    DebtMetricCardV2(debtType: .recovery(recoveryDebt), onTap: {})
        .padding()
}

#Preview("Sleep Debt") {
    let sleepDebt = SleepDebt(
        totalDebtHours: 3.5,
        band: .moderate,
        averageSleepDuration: 6.5,
        sleepNeed: 7.0,
        calculatedAt: Date()
    )
    
    DebtMetricCardV2(debtType: .sleep(sleepDebt), onTap: {})
        .padding()
}

#Preview("Both") {
    VStack(spacing: Spacing.md) {
        let recoveryDebt = RecoveryDebt(
            consecutiveDays: 3,
            band: .accumulating,
            averageRecoveryScore: 55.0,
            calculatedAt: Date()
        )
        
        let sleepDebt = SleepDebt(
            totalDebtHours: 3.5,
            band: .moderate,
            averageSleepDuration: 6.5,
            sleepNeed: 7.0,
            calculatedAt: Date()
        )
        
        DebtMetricCardV2(debtType: .recovery(recoveryDebt), onTap: {})
        DebtMetricCardV2(debtType: .sleep(sleepDebt), onTap: {})
    }
    .padding()
}
