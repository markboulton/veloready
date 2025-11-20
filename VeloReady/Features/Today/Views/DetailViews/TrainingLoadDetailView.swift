import SwiftUI

/// Detailed training load view with CTL/ATL/TSB trends and activity history
/// Uses MVVM pattern with TrainingLoadDetailViewModel for data fetching
struct TrainingLoadDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TrainingLoadDetailViewModel()
    @ObservedObject var proConfig = ProFeatureConfig.shared

    var body: some View {
        ZStack(alignment: .top) {
            // Adaptive background (light grey in light mode, black in dark mode)
            Color.background.app
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Header section with current CTL/ATL/TSB
                    headerSection
                        .padding(.top, 60)

                    // CTL Trend Chart (Pro)
                    ctlTrendSection

                    // Metrics explanation card
                    metricsExplanationSection

                    // Recent activities with load
                    activitiesSection
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 120)
            }
            .refreshable {
                await viewModel.loadData()
            }

            // Navigation gradient mask
            NavigationGradientMask()
        }
        .navigationTitle(TrainingLoadContent.title)
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveToolbarBackground(.hidden, for: .navigationBar)
        .adaptiveToolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        StandardCard {
            VStack(spacing: Spacing.lg) {
                // Title
                HStack {
                    Image(systemName: Icons.DataSource.intervalsICU)
                        .foregroundColor(Color.text.secondary)
                        .font(.system(size: TypeScale.xs))

                    Text("Current Training Load")
                        .font(.system(size: TypeScale.md, weight: .semibold))

                    Spacer()
                }

                // CTL/ATL/TSB values in a row
                HStack(spacing: Spacing.xl) {
                    loadMetric(
                        label: TrainingLoadContent.Metrics.ctl,
                        value: viewModel.currentCTL,
                        color: ColorScale.blueAccent,
                        icon: "arrow.up.right"
                    )

                    loadMetric(
                        label: TrainingLoadContent.Metrics.atl,
                        value: viewModel.currentATL,
                        color: ColorScale.amberAccent,
                        icon: "bolt.fill"
                    )

                    loadMetric(
                        label: TrainingLoadContent.Metrics.tsb,
                        value: viewModel.currentTSB,
                        color: tsbColor(viewModel.currentTSB),
                        icon: "heart.fill"
                    )
                }

                // TSB description
                if let tsb = viewModel.currentTSB {
                    Text(tsbDescription(tsb))
                        .font(.system(size: TypeScale.xs))
                        .foregroundColor(Color.text.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xs)
                }
            }
        }
    }

    // MARK: - CTL Trend Section (Pro)

    private var ctlTrendSection: some View {
        StandardCard {
            ProFeatureGate(
                upgradeContent: .weeklyRecoveryTrend,
                isEnabled: proConfig.canViewWeeklyTrends,
                showBenefits: true
            ) {
                TrendChart(
                    title: "Chronic Training Load (CTL)",
                    getData: { period in viewModel.loadTrendData.filter { point in
                        let calendar = Calendar.current
                        let endDate = calendar.startOfDay(for: Date())
                        let startDate = calendar.date(byAdding: .day, value: -(period.days - 1), to: endDate) ?? endDate
                        return point.date >= startDate
                    }},
                    chartType: .area,
                    unit: "",
                    showProBadge: true,
                    useAdaptiveYAxis: true
                )
            }
        }
    }

    // MARK: - Metrics Explanation Section

    private var metricsExplanationSection: some View {
        StandardCard(title: "Understanding Training Load") {
            VStack(alignment: .leading, spacing: Spacing.md) {
                explanationRow(
                    title: "CTL (Chronic Training Load)",
                    description: "Your long-term fitness. 42-day weighted average of training stress. Higher = more fit.",
                    color: ColorScale.blueAccent
                )

                Divider()

                explanationRow(
                    title: "ATL (Acute Training Load)",
                    description: "Your short-term fatigue. 7-day weighted average of training stress. Higher = more tired.",
                    color: ColorScale.amberAccent
                )

                Divider()

                explanationRow(
                    title: "TSB (Training Stress Balance)",
                    description: "Your form (CTL - ATL). Negative = fatigued, positive = fresh. Optimal race form is +5 to +25.",
                    color: ColorScale.greenAccent
                )
            }
        }
    }

    // MARK: - Activities Section

    private var activitiesSection: some View {
        StandardCard(title: "Recent Activities") {
            if viewModel.activitiesWithLoad.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "figure.outdoor.cycle")
                        .font(.system(size: 40))
                        .foregroundColor(Color.text.tertiary)

                    VRText("No activities with training load", style: .body, color: Color.text.secondary)
                    VRText("Track rides with power to build load history", style: .caption, color: Color.text.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.activitiesWithLoad.prefix(10)) { activity in
                        activityRow(activity)

                        if activity.id != viewModel.activitiesWithLoad.prefix(10).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private func loadMetric(label: String, value: Double?, color: Color, icon: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: TypeScale.sm))
                .foregroundColor(color)

            if let value = value {
                Text(String(format: "%.0f", value))
                    .font(.system(size: TypeScale.xl, weight: .bold))
                    .foregroundColor(Color.text.primary)
            } else {
                Text("--")
                    .font(.system(size: TypeScale.xl, weight: .bold))
                    .foregroundColor(Color.text.tertiary)
            }

            Text(label)
                .font(.system(size: TypeScale.xxs))
                .foregroundColor(Color.text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func explanationRow(title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.system(size: TypeScale.sm, weight: .semibold))
                    .foregroundColor(Color.text.primary)

                Text(description)
                    .font(.system(size: TypeScale.xs))
                    .foregroundColor(Color.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func activityRow(_ activity: Activity) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                Text(activity.name ?? "Untitled Activity")
                    .font(.system(size: TypeScale.sm, weight: .medium))
                    .foregroundColor(Color.text.primary)

                if let date = parseActivityDate(activity.startDateLocal) {
                    Text(date, style: .date)
                        .font(.system(size: TypeScale.xs))
                        .foregroundColor(Color.text.secondary)
                }
            }

            Spacer()

            // TSS value
            if let tss = activity.tss {
                VStack(alignment: .trailing, spacing: Spacing.xs / 2) {
                    Text("\(Int(tss))")
                        .font(.system(size: TypeScale.sm, weight: .bold))
                        .foregroundColor(Color.text.primary)

                    Text("TSS")
                        .font(.system(size: TypeScale.xxs))
                        .foregroundColor(Color.text.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.xs / 2)
    }

    // MARK: - Helper Functions

    private func tsbColor(_ tsb: Double?) -> Color {
        guard let tsb = tsb else { return ColorScale.greenAccent }

        if tsb < -30 {
            return ColorScale.redAccent
        } else if tsb < -10 {
            return ColorScale.amberAccent
        } else if tsb < 25 {
            return ColorScale.greenAccent
        } else {
            return ColorScale.blueAccent
        }
    }

    private func tsbDescription(_ tsb: Double) -> String {
        if tsb < -30 {
            return TrainingLoadContent.TSBDescriptions.heavilyFatigued
        } else if tsb < -10 {
            return TrainingLoadContent.TSBDescriptions.fatigued
        } else if tsb < 25 {
            return TrainingLoadContent.TSBDescriptions.balanced
        } else {
            return TrainingLoadContent.TSBDescriptions.fresh
        }
    }

    private func parseActivityDate(_ dateString: String) -> Date? {
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrainingLoadDetailView()
    }
}
