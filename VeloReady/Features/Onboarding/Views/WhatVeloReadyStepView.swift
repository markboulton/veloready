import SwiftUI

/// Screen 2: What VeloReady Does - Focus on riding, intelligence, health, and recovery
struct WhatVeloReadyStepView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "bicycle.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("What VeloReady Does")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Built for athletes who value data-driven training")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Content Cards
            ScrollView {
                VStack(spacing: 20) {
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
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                onboardingManager.nextStep()
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
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
                .font(.title)
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    WhatVeloReadyStepView()
}
