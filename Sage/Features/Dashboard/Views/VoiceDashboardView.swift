// VoiceDashboardView.swift
// Sage Voice Dashboard - Placeholder for Longitudinal Data
//
// Note: The comprehensive voice analysis content has been moved to HomeView
// This dashboard will display longitudinal voice tracking over time

import SwiftUI

struct VoiceDashboardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: SageSpacing.xLarge) {
                dashboardHeader
                placeholderContent
            }
            .padding(.horizontal, SageSpacing.large)
            .padding(.top, SageSpacing.xLarge)
            .padding(.bottom, 24)
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .background(sageBackground)
        .navigationTitle("Voice Dashboard")
    }
    
    // MARK: - UI Components
    
    private var sageBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [SageColors.fogWhite, SageColors.sandstone.opacity(0.5)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var dashboardHeader: some View {
        VStack(spacing: SageSpacing.small) {
            Text("Voice Trends Dashboard")
                .font(SageTypography.title)
                .foregroundColor(SageColors.espressoBrown)
            
            Text("Track your voice patterns over time")
                .font(SageTypography.body)
                .foregroundColor(SageColors.earthClay)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, SageSpacing.medium)
    }
    
    private var placeholderContent: some View {
        VStack(spacing: SageSpacing.xLarge) {
            Spacer()
            
            SageCard {
                VStack(spacing: SageSpacing.large) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 64))
                        .foregroundColor(SageColors.sageTeal.opacity(0.6))
                    
                    VStack(spacing: SageSpacing.medium) {
                        Text("Longitudinal Voice Analysis")
                            .font(SageTypography.headline)
                            .foregroundColor(SageColors.espressoBrown)
                        
                        Text("This dashboard will display your voice patterns and trends over time once you have multiple voice recordings.")
                            .font(SageTypography.body)
                            .foregroundColor(SageColors.earthClay)
                            .multilineTextAlignment(.center)
                        
                        Text("• Voice stability trends across menstrual cycles")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.cinnamonBark)
                        Text("• F0 patterns during hormonal fluctuations")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.cinnamonBark)
                        Text("• Voice quality correlations with PMDD/PCOS symptoms")
                            .font(SageTypography.caption)
                            .foregroundColor(SageColors.cinnamonBark)
                    }
                    
                    Text("For today's voice analysis, check the Home tab")
                        .font(SageTypography.caption)
                        .foregroundColor(SageColors.softTaupe)
                        .italic()
                }
            }
            .frame(maxWidth: 400)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct VoiceDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceDashboardView()
    }
} 