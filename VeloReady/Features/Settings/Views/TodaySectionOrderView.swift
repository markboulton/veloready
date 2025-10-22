import SwiftUI

/// Settings view for reordering Today page sections
struct TodaySectionOrderView: View {
    @State private var sectionOrder: TodaySectionOrder
    @State private var hasChanges = false
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    @Environment(\.dismiss) private var dismiss
    
    init() {
        _sectionOrder = State(initialValue: TodaySectionOrder.load())
    }
    
    var body: some View {
        List {
            Section {
                Text("Customize the order of sections on your Today page. Drag to reorder.")
                    .font(.subheadline)
                    .foregroundStyle(Color.text.secondary)
            }
            
            Section {
                ForEach(sectionOrder.movableSections) { section in
                    SectionRow(section: section, isPro: proConfig.hasProAccess)
                }
                .onMove(perform: moveSection)
            } header: {
                Text("Movable Sections")
            } footer: {
                Text("Fixed sections (Recovery Metrics) always appear at the top")
                    .font(.caption)
            }
            
            Section {
                Button(action: resetToDefault) {
                    HStack {
                        Image(systemName: Icons.Arrow.counterclockwise)
                        Text("Reset to Default Order")
                    }
                    .foregroundStyle(ColorScale.blueAccent)
                }
            }
        }
        .navigationTitle("Today Page Layout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!hasChanges)
            }
        }
    }
    
    // MARK: - Actions
    
    private func moveSection(from source: IndexSet, to destination: Int) {
        sectionOrder.movableSections.move(fromOffsets: source, toOffset: destination)
        hasChanges = true
    }
    
    private func resetToDefault() {
        sectionOrder = TodaySectionOrder.defaultOrder
        sectionOrder.save()
        hasChanges = false
        
        // Post notification to refresh Today page
        NotificationCenter.default.post(name: .todaySectionOrderChanged, object: nil)
        
        dismiss()
    }
    
    private func saveChanges() {
        sectionOrder.save()
        hasChanges = false
        
        // Post notification to refresh Today page
        NotificationCenter.default.post(name: .todaySectionOrderChanged, object: nil)
        
        dismiss()
    }
}

// MARK: - Section Row

struct SectionRow: View {
    let section: TodaySection
    let isPro: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: section.icon)
                .foregroundStyle(iconColor)
                .font(.system(size: 20))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(section.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.text.primary)
                    
                    if section.requiresPro {
                        Image(systemName: Icons.Feature.pro)
                            .font(.caption2)
                            .foregroundStyle(ColorScale.amberAccent)
                    }
                }
                
                Text(section.description)
                    .font(.caption)
                    .foregroundStyle(Color.text.secondary)
            }
            
            Spacer()
            
            // Show lock icon if PRO required and user doesn't have PRO
            if section.requiresPro && !isPro {
                Image(systemName: Icons.System.lock)
                    .font(.caption)
                    .foregroundStyle(Color.text.tertiary)
            }
        }
        .padding(.vertical, Spacing.xs)
        .opacity(section.requiresPro && !isPro ? 0.5 : 1.0)
    }
    
    private var iconColor: Color {
        if section.requiresPro && !isPro {
            return Color.text.tertiary
        }
        
        switch section {
        case .veloAI:
            return ColorScale.blueAccent
        case .dailyBrief:
            return ColorScale.greenAccent
        case .latestActivity:
            return ColorScale.amberAccent
        case .steps:
            return Color.blue
        case .calories:
            return Color.orange
        case .stepsAndCalories:
            return Color.text.secondary
        case .recentActivities:
            return Color.text.secondary
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let todaySectionOrderChanged = Notification.Name("todaySectionOrderChanged")
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TodaySectionOrderView()
    }
}
