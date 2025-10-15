import SwiftUI

/// Screen 3: Sport Ranking - Critical for AI personalization
struct SportRankingStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var selectedSports: Set<SportPreferences.Sport> = []
    @State private var sportOrder: [SportPreferences.Sport] = []
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "list.number.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Choose Your Sports")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Select your sports in order of preference. This helps us personalize your coaching.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            
            // Sport Selection Cards
            VStack(spacing: 16) {
                ForEach(SportPreferences.Sport.allCases) { sport in
                    SportSelectionCard(
                        sport: sport,
                        isSelected: selectedSports.contains(sport),
                        rank: getRank(for: sport),
                        onTap: {
                            toggleSport(sport)
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                saveSportPreferences()
                onboardingManager.nextStep()
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedSports.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(16)
            }
            .disabled(selectedSports.isEmpty)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            
            // Helper text
            if selectedSports.isEmpty {
                Text("Select at least one sport to continue")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func toggleSport(_ sport: SportPreferences.Sport) {
        if selectedSports.contains(sport) {
            // Remove sport
            selectedSports.remove(sport)
            sportOrder.removeAll { $0 == sport }
            
            // Recalculate rankings
            updateRankings()
        } else {
            // Add sport
            selectedSports.insert(sport)
            sportOrder.append(sport)
            
            // Update rankings
            updateRankings()
        }
    }
    
    private func getRank(for sport: SportPreferences.Sport) -> Int? {
        guard let index = sportOrder.firstIndex(of: sport) else { return nil }
        return index + 1
    }
    
    private func updateRankings() {
        onboardingManager.selectedSports = sportOrder
        onboardingManager.sportRankings = [:]
        
        for (index, sport) in sportOrder.enumerated() {
            onboardingManager.sportRankings[sport] = index + 1
        }
    }
    
    private func saveSportPreferences() {
        onboardingManager.saveSportPreferences()
    }
}

// MARK: - Sport Selection Card

struct SportSelectionCard: View {
    let sport: SportPreferences.Sport
    let isSelected: Bool
    let rank: Int?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: sport.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(sport.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(sport.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Rank Badge
                if let rank = rank {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                        
                        Text("\(rank)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    SportRankingStepView()
}
