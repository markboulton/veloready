import SwiftUI

/// Screen 3: Sport Ranking - Critical for AI personalization
struct SportRankingStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var selectedSports: Set<SportPreferences.Sport> = []
    @State private var sportOrder: [SportPreferences.Sport] = []
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
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
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            
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
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Helper text - above button
            if selectedSports.isEmpty {
                Text("Select at least one sport to continue")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
            }
            
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
                    .cornerRadius(12)
            }
            .disabled(selectedSports.isEmpty)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
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
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue)
                    .clipShape(Circle())
                
                // Content - Fixed width to prevent wrapping
                VStack(alignment: .leading, spacing: 4) {
                    Text(sport.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(sport.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                // Rank Badge
                if let rank = rank {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 32, height: 32)
                        
                        Text("\(rank)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
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
