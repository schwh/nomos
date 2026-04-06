import Vapor
import Fluent

struct AnalysisController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.grouped("portfolios", ":portfolioID")
            .get("analysis", use: analyse)
    }

    // GET /api/v1/portfolios/:portfolioID/analysis
    func analyse(req: Request) async throws -> PortfolioAnalysisResponse {
        guard let portfolioID = req.parameters.get("portfolioID", as: UUID.self),
              let portfolio = try await Portfolio.find(portfolioID, on: req.db) else {
            throw Abort(.notFound, reason: "Portfolio not found")
        }

        let holdings = try await Holding.query(on: req.db)
            .filter(\.$portfolio.$id == portfolioID)
            .all()

        guard !holdings.isEmpty else {
            // Return an empty but valid response rather than an error
            return PortfolioAnalysisResponse(
                portfolioID: portfolio.id!.uuidString,
                sectorExposure: [],
                geographicBreakdown: [],
                volatility: VolatilityScore(label: "N/A", beta: 0, description: "No holdings to evaluate"),
                marketDynamics: [],
                suggestions: [OptimizationSuggestion(
                    title: "Get Started",
                    message: "Add holdings to your portfolio to see personalised analysis.",
                    severity: "info"
                )],
                generatedAt: Date()
            )
        }

        // Fetch live quotes for all holdings concurrently
        let marketService = MarketDataService(client: req.client)
        let symbols = holdings.map { (symbol: $0.symbol, source: $0.dataSource) }
        let quotes = try await marketService.quotes(for: symbols)

        let engine = AnalysisEngine()
        return engine.buildAnalysis(
            portfolioID: portfolio.id!.uuidString,
            holdings: holdings,
            quotes: quotes
        )
    }
}
