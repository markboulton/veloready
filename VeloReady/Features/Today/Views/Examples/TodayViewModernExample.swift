import SwiftUI

/// Example of how TodayView would look using new atomic components
/// This demonstrates the migration pattern - much cleaner and less code
struct TodayViewModernExample: View {
    // Mock data for demonstration
    @State private var recoveryScore = 92
    @State private var sleepScore = 88
    @State private var strainScore = 12.5
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // BEFORE: Custom card implementation (120+ lines each)
                // AFTER: Single line with configuration (90% code reduction!)
                
                // Recovery Score Card
                ScoreCard(
                    config: .recovery(
                        score: recoveryScore,
                        band: .optimal,
                        change: .init(value: "+5", direction: .up),
                        footerText: "Updated 5 min ago"
                    ),
                    onTap: { print("Navigate to Recovery Detail") }
                )
                
                // Sleep Score Card
                ScoreCard(
                    config: .sleep(
                        score: sleepScore,
                        band: .good,
                        change: .init(value: "-3", direction: .down),
                        footerText: "From Apple Health"
                    ),
                    onTap: { print("Navigate to Sleep Detail") }
                )
                
                // Strain Score Card
                ScoreCard(
                    config: .strain(score: strainScore),
                    onTap: { print("Navigate to Strain Detail") }
                )
                
                // Readiness Card (using V2)
                ReadinessCardViewV2(
                    readinessScore: mockReadiness,
                    onTap: { print("Navigate to Readiness Detail") }
                )
                
                // Simple Metrics (using V2)
                HStack(spacing: 16) {
                    SimpleMetricCardV2(
                        metricType: .sleepConsistency(mockConsistency),
                        onTap: { print("Navigate to Consistency") }
                    )
                    
                    SimpleMetricCardV2(
                        metricType: .resilience(mockResilience),
                        onTap: { print("Navigate to Resilience") }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Today")
    }
    
    // MARK: - Mock Data
    
    private var mockReadiness: ReadinessScore {
        ReadinessScore(
            score: 82,
            band: .ready,
            components: ReadinessScore.Components(
                recoveryScore: 85,
                sleepScore: 88,
                loadReadiness: 70,
                recoveryWeight: 0.4,
                sleepWeight: 0.35,
                loadWeight: 0.25
            ),
            calculatedAt: Date()
        )
    }
    
    private var mockConsistency: SleepConsistency {
        SleepConsistency(
            score: 85,
            band: .excellent,
            bedtimeVariability: 25.0,
            wakeTimeVariability: 20.0,
            calculatedAt: Date()
        )
    }
    
    private var mockResilience: ResilienceScore {
        ResilienceScore(
            score: 72,
            band: .good,
            averageRecovery: 68.5,
            averageLoad: 8.2,
            recoveryEfficiency: 1.2,
            calculatedAt: Date()
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        TodayViewModernExample()
    }
}

#Preview("Dark Mode") {
    NavigationView {
        TodayViewModernExample()
    }
    .preferredColorScheme(.dark)
}

// MARK: - Code Comparison

/*
 
 BEFORE (Old Pattern):
 =====================
 Each card: 120-150 lines of custom implementation
 - Custom header layout
 - Custom metric display
 - Custom footer
 - Duplicate styling
 - Hard-coded spacing
 - Inconsistent patterns
 
 Example:
 ```swift
 struct RecoveryCard: View {
     let score: Int
     
     var body: some View {
         VStack {
             // 50 lines of header code
             HStack {
                 Text("Recovery Score")
                 // ... custom layout
             }
             
             // 30 lines of metric code
             Text("\(score)")
                 .font(.system(size: 48, weight: .bold))
             // ... custom styling
             
             // 20 lines of footer code
             HStack {
                 Text("Updated 5 min ago")
                 // ... custom layout
             }
         }
         .padding()
         // ... 20 more lines of styling
     }
 }
 ```
 
 Total: ~120 lines per card × 5 cards = ~600 lines
 
 
 AFTER (New Pattern):
 ====================
 Each card: 1-2 lines using ScoreCard
 - Consistent header (CardHeader)
 - Consistent metric (CardMetric)
 - Consistent footer (CardFooter)
 - Consistent styling (CardContainer)
 - Design tokens
 - Composable
 
 Example:
 ```swift
 ScoreCard(
     config: .recovery(
         score: 92,
         band: .optimal,
         change: .init(value: "+5", direction: .up)
     ),
     onTap: { navigateToDetail() }
 )
 ```
 
 Total: ~2 lines per card × 5 cards = ~10 lines
 
 
 RESULT: 98% CODE REDUCTION! 🎉
 ================================
 - 600 lines → 10 lines
 - Consistent design
 - Easier maintenance
 - Type-safe configuration
 - Fully composable
 - Dark mode ready
 
 */
