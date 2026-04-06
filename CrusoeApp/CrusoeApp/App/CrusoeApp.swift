import SwiftUI

@main
struct CrusoeApp: App {
    @StateObject private var portfolioVM = PortfolioViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(portfolioVM)
        }
    }
}
