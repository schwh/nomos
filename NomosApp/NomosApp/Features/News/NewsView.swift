import SwiftUI

struct NewsView: View {
    @StateObject private var vm = NewsViewModel()
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                
                if vm.isLoading && vm.articles.isEmpty {
                    LoadingView(message: "Curating latest signals...")
                        .frame(height: 200)
                } else if let error = vm.errorMessage, vm.articles.isEmpty {
                    Text(error)
                        .font(.bodyMd)
                        .foregroundStyle(Color.appError)
                        .padding()
                } else {
                    feed
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // space above tab bar
        }
        .scrollIndicators(.hidden)
        .refreshable { await vm.manualRefresh() }
        .task {
            await vm.fetchNews()
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Signals")
                    .font(.displayMd)
                    .foregroundStyle(theme.current.accent)
                Text("High conviction market updates.")
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)
            }
            Spacer()
        }
        .padding(.top, 16)
    }

    private var feed: some View {
        VStack(spacing: 16) {
            ForEach(vm.articles) { article in
                NewsArticleCard(article: article)
            }
        }
    }
}

// MARK: - Article Card (Non Noisy Design)

private struct NewsArticleCard: View {
    let article: NewsArticle
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        GlassCard(cornerRadius: 16, showGlow: false, padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                // Metadata row
                HStack {
                    Text(article.source.uppercased())
                        .font(.labelCaps)
                        .foregroundStyle(theme.current.accent)
                    Spacer()
                    Text(article.formattedDate)
                        .font(.labelCaps)
                        .foregroundStyle(Color.secondaryText)
                }
                
                // Headline
                Text(article.headline)
                    .font(.titleMd)
                    .foregroundStyle(Color.onSurface)
                
                // Summary
                Text(article.summary)
                    .font(.bodyMd)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NewsView()
        .preferredColorScheme(.dark)
}
