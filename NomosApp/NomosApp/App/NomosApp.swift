import SwiftUI

@main
struct NomosApp: App {
    @StateObject private var portfolioVM = PortfolioViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(portfolioVM)
        }
    }
}
