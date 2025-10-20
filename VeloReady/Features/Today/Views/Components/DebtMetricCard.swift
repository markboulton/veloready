import SwiftUI

/// Compact card view for debt metrics (Recovery Debt, Sleep Debt)
struct DebtMetricCard: View {
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
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: debtType.icon)
                    .font(.title2)
                    .foregroundColor(debtType.color)
                    .frame(width: 40, height: 40)
                    .background(debtType.color.opacity(0.15))
                    .cornerRadius(10)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(debtType.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Text(debtType.primaryValue)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(debtType.color)
                        
                        Text(debtType.bandName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(debtType.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(debtType.color.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    Text(debtType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct DebtMetricCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
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
            
            DebtMetricCard(debtType: .recovery(recoveryDebt), onTap: {})
            DebtMetricCard(debtType: .sleep(sleepDebt), onTap: {})
        }
        .padding()
    }
}
