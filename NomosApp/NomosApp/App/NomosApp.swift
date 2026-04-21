import SwiftUI

@main
struct NomosApp: App {
    @StateObject private var portfolioVM = PortfolioViewModel()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(portfolioVM)
                .environmentObject(themeManager)
        }
    }
}
