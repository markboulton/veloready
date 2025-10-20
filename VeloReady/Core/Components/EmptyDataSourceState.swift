import SwiftUI

/// Empty state view shown when no data sources are connected
struct EmptyDataSourceState: View {
    let dataType: DataType
    let onConnectTapped: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.xxl) {
            // Icon
            Image(systemName: iconForDataType)
                .font(TypeScale.font(size: TypeScale.xxl + 12))
                .foregroundColor(ColorPalette.labelSecondary.opacity(0.5))
            
            // Message
            VStack(spacing: Spacing.sm) {
                Text(titleForDataType)
                    .font(TypeScale.font(size: TypeScale.mlg, weight: .semibold))
                    .foregroundColor(ColorPalette.labelPrimary)
                
                Text(messageForDataType)
                    .font(TypeScale.font(size: TypeScale.md))
                    .foregroundColor(ColorPalette.labelSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            // Connect button
            Button(action: onConnectTapped) {
                HStack {
                    Image(systemName: "link")
                    Text(CommonContent.EmptyStates.connectButton)
                }
                .font(.headline)
                .foregroundColor(ColorPalette.labelPrimary)
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.md)
                .background(ColorPalette.blue)
                .cornerRadius(Spacing.md)
            }
            
            // Available sources
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(CommonContent.EmptyStates.availableSources)
                    .font(TypeScale.font(size: TypeScale.xs))
                    .foregroundColor(ColorPalette.labelSecondary)
                
                ForEach(sourcesForDataType, id: \.self) { source in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: source.icon)
                            .foregroundColor(source.color)
                            .frame(width: 20)
                        Text(source.displayName)
                            .font(TypeScale.font(size: TypeScale.xs))
                    }
                }
            }
            .padding(Spacing.lg)
            .background(ColorPalette.labelSecondary.opacity(0.1))
            .cornerRadius(Spacing.md)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var iconForDataType: String {
        switch dataType {
        case .activities, .workouts: return "figure.outdoor.cycle"
        case .wellness: return "heart.text.square"
        case .zones: return "gauge.with.dots.needle.bottom.50percent"
        case .metrics: return "chart.xyaxis.line"
        }
    }
    
    private var titleForDataType: String {
        switch dataType {
        case .activities, .workouts: return CommonContent.EmptyStates.noActivities
        case .wellness: return CommonContent.EmptyStates.noWellnessData
        case .zones: return CommonContent.EmptyStates.noTrainingZones
        case .metrics: return CommonContent.EmptyStates.noMetrics
        }
    }
    
    private var messageForDataType: String {
        switch dataType {
        case .activities, .workouts:
            return CommonContent.EmptyStates.noActivitiesMessage
        case .wellness:
            return CommonContent.EmptyStates.noWellnessDataMessage
        case .zones:
            return CommonContent.EmptyStates.noTrainingZonesMessage
        case .metrics:
            return CommonContent.EmptyStates.noMetricsMessage
        }
    }
    
    private var sourcesForDataType: [DataSource] {
        DataSource.allCases.filter { $0.providedDataTypes.contains(dataType) }
    }
}

// MARK: - Preview

struct EmptyDataSourceState_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            EmptyDataSourceState(dataType: .activities) { }
            EmptyDataSourceState(dataType: .wellness) { }
        }
    }
}
