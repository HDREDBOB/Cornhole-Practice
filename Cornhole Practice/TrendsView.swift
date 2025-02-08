import SwiftUI
import CoreData

struct Achievement {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    let progress: Double
}

enum AchievementType {
    case practiceStreak(days: Int)
    case totalSessions(count: Int)
    case fourBaggers(count: Int)
    case pprMilestone(score: Double)
    case inHolePercentage(percent: Double)
}

struct TrendsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavedPracticeSession.date, ascending: true)],
        animation: .default)
    private var sessions: FetchedResults<SavedPracticeSession>
    
    // MARK: - Performance Calculation Methods
    
    private var pprTrend: Double {
        guard sessions.count >= 4 else { return 0 }
        
        let recentSessions = Array(sessions.suffix(10))
        let weightedAverage = calculateWeightedAverage(sessions: recentSessions, keyPath: \.pointsPerRound)
        let olderAverage = calculateWeightedAverage(sessions: Array(recentSessions.prefix(recentSessions.count / 2)),
                                                    keyPath: \.pointsPerRound)
        
        return olderAverage > 0 ? ((weightedAverage - olderAverage) / olderAverage) * 100 : 0
    }
    
    private var fourBaggerTrend: Double {
        guard sessions.count >= 4 else { return 0 }
        
        let recentSessions = Array(sessions.suffix(10))
        let weightedAverage = calculateWeightedAverage(sessions: recentSessions, keyPath: \.fourBaggers)
        let olderAverage = calculateWeightedAverage(sessions: Array(recentSessions.prefix(recentSessions.count / 2)),
                                                    keyPath: \.fourBaggers)
        
        return olderAverage > 0 ? ((weightedAverage - olderAverage) / olderAverage) * 100 : 0
    }
    
    private func calculateWeightedAverage<T: Numeric>(sessions: [SavedPracticeSession],
                                                       keyPath: KeyPath<SavedPracticeSession, T>) -> Double {
        guard !sessions.isEmpty else { return 0 }
        
        let weightedSum = sessions.enumerated().reduce(0.0) { (result, enumerated) in
            let (index, session) = enumerated
            let weight = Double(index + 1) / Double(sessions.count)
            // Replace .intValue with Int(truncating:)
            return result + (Double(truncating: session[keyPath: keyPath] as! NSNumber) * weight)
        }
        
        return weightedSum
    }
    
    private var totalSessions: Int { sessions.count }
    
    private var averagePPR: Double {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0.0) { $0 + $1.pointsPerRound } / Double(sessions.count)
    }
    
    private var totalBagsThrown: Int16 {
        sessions.reduce(0) { $0 + $1.totalBagsInHole + $1.bagsOnBoard + $1.bagsOffBoard }
    }
    
    private var throwDistribution: (inHole: Double, onBoard: Double, offBoard: Double) {
        let inHole = Double(sessions.reduce(0) { $0 + $1.totalBagsInHole })
        let onBoard = Double(sessions.reduce(0) { $0 + $1.bagsOnBoard })
        let offBoard = Double(sessions.reduce(0) { $0 + $1.bagsOffBoard })
        
        let total = inHole + onBoard + offBoard
        guard total > 0 else { return (0, 0, 0) }
        
        return (
            (inHole / total) * 100,
            (onBoard / total) * 100,
            (offBoard / total) * 100
        )
    }
    
    private var fourBaggerRate: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.fourBaggers }) / Double(sessions.count)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PerformanceSummaryCard(
                        totalSessions: totalSessions,
                        averagePPR: averagePPR,
                        totalBagsThrown: totalBagsThrown,
                        fourBaggerRate: fourBaggerRate,
                        pprTrend: pprTrend,
                        fourBaggerTrend: fourBaggerTrend
                    )
                    
                    AnimatedPieChart(
                        inHolePercentage: throwDistribution.inHole,
                        onBoardPercentage: throwDistribution.onBoard,
                        offBoardPercentage: throwDistribution.offBoard
                    )
                    
                    PPRTrendChart(sessions: Array(sessions))
                    
                    DetailedInsightsCard(sessions: Array(sessions))
                }
                .padding()
            }
            .navigationTitle("Practice Trends")
        }
    }
}

struct PerformanceSummaryCard: View {
    let totalSessions: Int
    let averagePPR: Double
    let totalBagsThrown: Int16
    let fourBaggerRate: Double
    let pprTrend: Double
    let fourBaggerTrend: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("✨ Performance Overview")
                .font(.headline)
            
            HStack {
                StatBox(
                    label: "Total Sessions",
                    value: "\(totalSessions)",
                    trend: nil
                )
                StatBox(
                    label: "Avg PPR",
                    value: String(format: "%.1f", averagePPR),
                    trend: pprTrend
                )
            }
            
            HStack {
                StatBox(
                    label: "Total Bags",
                    value: "\(totalBagsThrown)",
                    trend: nil
                )
                StatBox(
                    label: "4 Bagger Rate",
                    value: String(format: "%.1f", fourBaggerRate),
                    trend: fourBaggerTrend
                )
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let trend: Double?
    @State private var animate = false
    
    var trendIcon: String {
        guard let trend = trend else { return "" }
        return trend > 0 ? "⬆️" : (trend < 0 ? "⬇️" : "➡️")
    }
    
    var trendColor: Color {
        guard let trend = trend else { return .primary }
        return trend > 0 ? .green : (trend < 0 ? .red : .blue)
    }
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(trendColor)
                
                if let trend = trend {
                    Text(String(format: "(%.1f%%)", abs(trend)))
                        .font(.caption)
                        .foregroundColor(trendColor)
                    
                    Text(trendIcon)
                        .scaleEffect(animate ? 1.2 : 1.0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6),
                            value: animate
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .onAppear {
            animate = true
        }
    }
}

struct DetailedInsightsCard: View {
    let sessions: [SavedPracticeSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Detailed Insights")
                .font(.headline)
            
            InsightRow(label: "Best Session PPR", value: bestSessionPPR())
            InsightRow(label: "Most 4 Baggers", value: mostFourBaggers())
            InsightRow(label: "Highest In Hole %", value: highestInHolePercentage())
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func bestSessionPPR() -> String {
        guard let best = sessions.max(by: { $0.pointsPerRound < $1.pointsPerRound }) else {
            return "N/A"
        }
        return String(format: "%.1f", best.pointsPerRound)
    }
    
    private func mostFourBaggers() -> String {
        guard let mostFourBaggers = sessions.max(by: { $0.fourBaggers < $1.fourBaggers }) else {
            return "N/A"
        }
        return "\(mostFourBaggers.fourBaggers)"
    }
    
    private func highestInHolePercentage() -> String {
        guard !sessions.isEmpty else { return "N/A" }
        
        let percentages = sessions.map {
            Double($0.totalBagsInHole) /
            Double($0.totalBagsInHole + $0.bagsOnBoard + $0.bagsOffBoard) * 100
        }
        
        return String(format: "%.1f%%", percentages.max() ?? 0)
    }
}

struct InsightRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
}

struct AnimatedPieChart: View {
    let inHolePercentage: Double
    let onBoardPercentage: Double
    let offBoardPercentage: Double
    @State private var animateChart = false
    
    private var slices: [(Double, Color)] {
        [
            (inHolePercentage, .green),
            (onBoardPercentage, .blue),
            (offBoardPercentage, .red)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Throw Distribution")
                .font(.headline)
                .padding(.bottom, 8)
            
            HStack {
                ZStack {
                    ForEach(0..<slices.count, id: \.self) { index in
                        PieSliceShape(
                            startAngle: startAngle(for: index),
                            endAngle: endAngle(for: index),
                            cornerRadius: 5
                        )
                        .fill(slices[index].1)
                        .scaleEffect(animateChart ? 1 : 0.7)
                        .opacity(animateChart ? 1 : 0)
                    }
                }
                .frame(width: 150, height: 150)
                .animation(.easeInOut(duration: 1.0), value: animateChart)
                
                VStack(alignment: .leading, spacing: 12) {
                    LegendItem(color: .green, label: "In Hole", value: inHolePercentage)
                    LegendItem(color: .blue, label: "On Board", value: onBoardPercentage)
                    LegendItem(color: .red, label: "Off Board", value: offBoardPercentage)
                }
                .padding(.leading)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            animateChart = true
        }
    }
    
    private func startAngle(for index: Int) -> Double {
        let precedingRatios = slices[0..<index].map { $0.0 }
        let ratioSum = precedingRatios.reduce(0, +)
        return ratioSum / 100 * 360
    }
    
    private func endAngle(for index: Int) -> Double {
        let precedingRatios = slices[0...index].map { $0.0 }
        let ratioSum = precedingRatios.reduce(0, +)
        return ratioSum / 100 * 360
    }
}

struct PieSliceShape: Shape {
    let startAngle: Double
    let endAngle: Double
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        let start = startAngle - 90
        let end = endAngle - 90
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(start),
            endAngle: .degrees(end),
            clockwise: false
        )
        path.addLine(to: center)
        path.closeSubpath()
        
        return path
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: Double
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(String(format: "%.1f%%", value))
                .font(.subheadline)
                .bold()
        }
    }
}

struct PPRTrendChart: View {
    let sessions: [SavedPracticeSession]
    @State private var selectedSession: SavedPracticeSession?
    @State private var showingDetail = false
    @State private var detailPosition: CGPoint = .zero
    
    private var bestPPR: Double {
        sessions.map(\.pointsPerRound).max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🔥 PPR Trend")
                .font(.title2)
                .bold()
                .foregroundColor(.blue)
                .padding(.horizontal)
            
            GeometryReader { geometry in
                let points = calculatePoints(in: geometry.size)
                
                ZStack {
                    // Background Grid Lines
                    VStack(spacing: geometry.size.height / 4) {
                        ForEach(0..<4) { _ in
                            Divider()
                                .background(Color.gray.opacity(0.2))
                        }
                    }
                    
                    if points.count > 1 {
                        // Gradient Line Path
                        Path { path in
                            path.move(to: points[0])
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                        .strokedPath(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        
                        // Best PPR Label
                        if let maxPPR = sessions.map({ $0.pointsPerRound }).max() {
                            let maxY = geometry.size.height - (CGFloat(maxPPR) / CGFloat(maxPPR + 2.0) * geometry.size.height)
                            
                            HStack {
                                Text("Best PPR: \(String(format: "%.1f", maxPPR))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .offset(y: -20)
                            .position(x: geometry.size.width / 2, y: maxY)
                        }
                        
                        // Interactive Points
                        ForEach(Array(zip(sessions.indices, points)), id: \.0) { index, point in
                            Circle()
                                .fill(sessions[index] == selectedSession ? Color.purple : Color.blue)
                                .frame(width: 12, height: 12)
                                .shadow(color: Color.blue.opacity(0.6), radius: 4, x: 0, y: 2)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .position(point)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedSession = sessions[index]
                                        detailPosition = point
                                        showingDetail = true
                                    }
                                }
                        }
                        
                        // Session Detail Popup
                        if showingDetail, let session = selectedSession {
                            SessionDetailPopup(
                                session: session,
                                position: CGPoint(x: geometry.size.width/2, y: geometry.size.height/2),
                                onDismiss: {
                                    withAnimation(.spring()) {
                                        showingDetail = false
                                        selectedSession = nil
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .frame(height: 250)  // Increased height to accommodate popup
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(radius: 10)
    }
    
    private func calculatePoints(in size: CGSize) -> [CGPoint] {
        let pprValues = sessions.map { $0.pointsPerRound }
        guard !pprValues.isEmpty else { return [] }
        
        let maxPPR = (pprValues.max() ?? 12.0) + 2.0
        
        return pprValues.enumerated().map { (index, ppr) in
            let x = CGFloat(index) * (size.width / CGFloat(max(1, pprValues.count - 1)))
            let y = size.height - (CGFloat(ppr) / CGFloat(maxPPR) * size.height)
            return CGPoint(x: x, y: y)
        }
    }
}

struct SessionDetailPopup: View {
    let session: SavedPracticeSession
    let position: CGPoint
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Session Details")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                DetailRow(label: "PPR", value: String(format: "%.1f", session.pointsPerRound))
                DetailRow(label: "In Hole", value: "\(session.totalBagsInHole)")
                DetailRow(label: "On Board", value: "\(session.bagsOnBoard)")
                DetailRow(label: "4 Baggers", value: "\(session.fourBaggers)")
                if let date = session.date {
                    DetailRow(label: "Date", value: {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM/dd/yyyy"
                        return formatter.string(from: date)
                    }())
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .frame(width: 200)
        .position(position)
        .transition(.scale.combined(with: .opacity))
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .bold()
        }
        .font(.subheadline)
    }
}
