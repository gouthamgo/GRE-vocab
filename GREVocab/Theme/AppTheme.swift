import SwiftUI

enum AppTheme {
    enum Colors {
        static let background = Color("Background")
        static let surface = Color("Surface")
        static let surfaceElevated = Color("SurfaceElevated")
        static let surfaceHighlight = Color("SurfaceHighlight")

        static let accent = Color("Accent")
        static let accentMuted = Color("AccentMuted")

        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let textTertiary = Color("TextTertiary")
        // Higher contrast variant for better accessibility (WCAG AA compliant)
        static let textTertiaryAccessible = Color(white: 0.55)

        static let success = Color("Success")
        static let warning = Color("Warning")
        static let error = Color("Error")

        static let secondary = Color("Secondary")
        static let tertiary = Color("Tertiary")
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    enum Radius {
        static let xs: CGFloat = 6   // For smaller elements like badges
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: - Shadow Presets
    enum Shadow {
        static func sm(color: Color = .black.opacity(0.1)) -> some View {
            EmptyView().shadow(color: color, radius: 4, x: 0, y: 2)
        }

        static func md(color: Color = .black.opacity(0.15)) -> some View {
            EmptyView().shadow(color: color, radius: 8, x: 0, y: 4)
        }

        static func lg(color: Color = .black.opacity(0.2)) -> some View {
            EmptyView().shadow(color: color, radius: 16, x: 0, y: 8)
        }
    }

    // MARK: - Animation Presets
    enum Motion {
        static let quick = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let standard = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let slow = Animation.spring(response: 0.8, dampingFraction: 0.7)
        static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.5)
    }

    // MARK: - Tap Target
    static let minTapTarget: CGFloat = 44
    
    enum Typography {
        static func displayLarge(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 57, weight: weight)
        }
        static func displayMedium(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 45, weight: weight)
        }
        static func displaySmall(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 36, weight: weight)
        }
        
        static func headlineLarge(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 32, weight: weight)
        }
        static func headlineMedium(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 28, weight: weight)
        }
        static func headlineSmall(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 24, weight: weight)
        }

        static func bodyLarge(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 16, weight: weight)
        }
        static func bodyMedium(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 14, weight: weight)
        }
        static func bodySmall(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 12, weight: weight)
        }
        
        static func labelLarge(_ weight: Font.Weight = .medium) -> Font {
            .system(size: 14, weight: weight)
        }
        static func labelMedium(_ weight: Font.Weight = .medium) -> Font {
            .system(size: 12, weight: weight)
        }
        static func labelSmall(_ weight: Font.Weight = .medium) -> Font {
            .system(size: 11, weight: weight)
        }
    }

    struct CustomTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Colors.surfaceHighlight, lineWidth: 1)
                        )
                )
        }
    }
}