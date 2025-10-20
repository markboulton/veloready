import SwiftUI

/// Screen 2: What VeloReady Does - Focus on riding, intelligence, health, and recovery
struct WhatVeloReadyStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Text(OnboardingContent.WhatVeloReady.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingContent.WhatVeloReady.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, 48)
            
            // Content Cards - Not scrollable
            VStack(spacing: 24) {
                // Riding First
                FeatureCard(
                    icon: "figure.outdoor.cycle",
                    iconColor: .blue,
                    title: "Riding First",
                    description: "Track power, heart rate, and training load. Connect with Strava, Intervals.icu, or Wahoo for seamless data sync."
                )
                
                // Intelligence Layer
                FeatureCard(
                    icon: "brain.filled.head.profile",
                    iconColor: .purple,
                    title: "Intelligence Layer",
                    description: "AI analyzes your data to provide daily coaching insights, workout recommendations, and recovery guidance."
                )
                
                // General Health
                FeatureCard(
                    icon: "heart.circle.fill",
                    iconColor: .red,
                    title: "General Health",
                    description: "Monitor HRV, resting heart rate, sleep quality, and overall wellness metrics from Apple Health."
                )
                
                // Recovery Focus
                FeatureCard(
                    icon: "bed.double.fill",
                    iconColor: .green,
                    title: "Recovery Focus",
                    description: "Balance training stress with recovery. Know when to push hard and when to back off to avoid burnout."
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                onboardingManager.nextStep()
            }) {
                Text(OnboardingContent.WhatVeloReady.continueButton)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(iconColor)
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    WhatVeloReadyStepView()
}
