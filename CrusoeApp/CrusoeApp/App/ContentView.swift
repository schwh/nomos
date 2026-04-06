import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var portfolioVM: PortfolioViewModel

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }

            HoldingsView()
                .tabItem {
                    Label("Holdings", systemImage: "list.bullet.rectangle.portrait")
                }

            TransactionListView()
                .tabItem {
                    Label("Activity", systemImage: "clock.arrow.circlepath")
                }
        }
        .task {
            await portfolioVM.loadInitialData()
        }
    }
}
