import SwiftUI
import SwiftData

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var userProgress: UserProgress

    @State private var selectedPlan: PricingPlan = .yearly
    @State private var isProcessing = false
    @State private var showSuccess = false

    enum PricingPlan: String, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"

        var price: String {
            switch self {
            case .monthly: return "$4.99"
            case .yearly: return "$29.99"
            }
        }

        var period: String {
            switch self {
            case .monthly: return "/month"
            case .yearly: return "/year"
            }
        }

        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save 50%"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Features
                        featuresSection

                        // Pricing
                        pricingSection

                        // Subscribe Button
                        subscribeButton

                        // Terms
                        termsSection

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.warning)

            Text("GRE Vocab Pro")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("Unlock your full vocabulary potential")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(icon: "infinity", text: "Unlimited word learning")
            FeatureRow(icon: "chart.bar.fill", text: "Advanced statistics")
            FeatureRow(icon: "bell.fill", text: "Smart reminders")
            FeatureRow(icon: "star.fill", text: "All difficulty levels")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.surface)
        )
    }

    // MARK: - Pricing
    private var pricingSection: some View {
        VStack(spacing: 12) {
            ForEach(PricingPlan.allCases, id: \.self) { plan in
                PlanButton(
                    plan: plan,
                    isSelected: selectedPlan == plan
                ) {
                    selectedPlan = plan
                }
            }
        }
    }

    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        Button {
            // In a real app, this would trigger StoreKit purchase
            isProcessing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isProcessing = false
                showSuccess = true
            }
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe Now")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.Colors.accent)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(isProcessing)
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for subscribing!")
        }
    }

    // MARK: - Terms
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Cancel anytime. Subscription auto-renews.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textTertiary)

            HStack(spacing: 16) {
                Button("Terms") {}
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.accent)

                Button("Privacy") {}
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.accent)

                Button("Restore") {}
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.accent)
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.success)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.Colors.success)
        }
    }
}

// MARK: - Plan Button
struct PlanButton: View {
    let plan: PaywallView.PricingPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan == .monthly ? "Monthly" : "Yearly")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        if let savings = plan.savings {
                            Text(savings)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.success)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.Colors.success.opacity(0.15))
                                )
                        }
                    }

                    Text("\(plan.price)\(plan.period)")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.surfaceHighlight, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

#Preview {
    PaywallView(userProgress: UserProgress())
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self], inMemory: true)
}
