import SwiftUI

/// Empty state view shown when no data sources are connected
struct EmptyDataSourceState: View {
    let dataType: DataType
    let onConnectTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: iconForDataType)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            // Message
            VStack(spacing: 8) {
                Text(titleForDataType)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(messageForDataType)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Connect button
            Button(action: onConnectTapped) {
                HStack {
                    Image(systemName: "link")
                    Text("Connect Data Source")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // Available sources
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Sources:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(sourcesForDataType, id: \.self) { source in
                    HStack(spacing: 8) {
                        Image(systemName: source.icon)
                            .foregroundColor(source.color)
                            .frame(width: 20)
                        Text(source.displayName)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
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
        case .activities, .workouts: return "No Activities Yet"
        case .wellness: return "No Wellness Data"
        case .zones: return "No Training Zones"
        case .metrics: return "No Performance Metrics"
        }
    }
    
    private var messageForDataType: String {
        switch dataType {
        case .activities, .workouts:
            return "Connect a data source to view your rides and track your progress"
        case .wellness:
            return "Connect Apple Health or another source to track sleep, HRV, and recovery"
        case .zones:
            return "Connect a training platform to sync your power and heart rate zones"
        case .metrics:
            return "Connect a data source to see detailed performance analytics"
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
