import SwiftUI
import CoreData




struct TrendsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var sessions: FetchedResults<SavedPracticeSession>
    
    // Pagination state
    @State private var currentPage = 0
    @State private var isLoading = false
    
    init() {
        let request = NSFetchRequest<SavedPracticeSession>(entityName: "SavedPracticeSession")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedPracticeSession.date, ascending: false)]
        request.fetchLimit = 100
        
        _sessions = FetchRequest(fetchRequest: request, animation: .default)
    }
    
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
                   
                    BagPlacementChart(sessions: Array(sessions))
                       
                    
                    
                    //BagPlacementTestChart(sessions: Array(sessions))
                    DetailedInsightsCard(sessions: Array(sessions))
                    
                    // Load More Button
                    if sessions.count >= (currentPage + 1) * 100 {
                        loadMoreButton
                    }
                }
                .padding()
            }
            .navigationTitle("Practice Trends")
            .refreshable {
                await refreshSessions()
            }
        }
    }
    
    private var loadMoreButton: some View {
        Button(action: loadMoreSessions) {
            HStack {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Load More Sessions")
                    Image(systemName: "arrow.down")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
    
    private func loadMoreSessions() {
        guard !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        // Modify fetch request to load next batch
        let request: NSFetchRequest<SavedPracticeSession> = SavedPracticeSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedPracticeSession.date, ascending: false)]
        request.fetchLimit = 100
        request.fetchOffset = currentPage * 100
        
        do {
            // This will automatically update the @FetchRequest
            _ = try viewContext.fetch(request)
            isLoading = false
        } catch {
            print("Failed to load more sessions: \(error)")
            isLoading = false
        }
    }
    
    private func refreshSessions() async {
        // Reset to first page
        currentPage = 0
        
        let request: NSFetchRequest<SavedPracticeSession> = SavedPracticeSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedPracticeSession.date, ascending: false)]
        request.fetchLimit = 100
        
        do {
            // This will automatically update the @FetchRequest
            _ = try viewContext.fetch(request)
        } catch {
            print("Failed to refresh sessions: \(error)")
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
        .background(Color(UIColor.systemBackground))
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
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("🔥 PPR Trend")
                .font(.title2)
                .bold()
                .foregroundColor(.blue)
            
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollProxy in
                        ZStack(alignment: .leading) {
                            drawGrid(in: geometry.size)
                            drawChartWithLabels(sessions: sessions, in: geometry.size)
                        }
                        .frame(width: geometry.size.width * 2)
                        .onAppear {
                            withAnimation {
                                scrollProxy.scrollTo(sessions.count - 1, anchor: .trailing)
                            }
                        }
                    }
                }
                .background(Color.black.opacity(0.05))
                .overlay {
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
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(radius: 10)
    }

    
    private func drawGrid(in size: CGSize) -> some View {
        let yPositions = [0, 2, 4, 6, 8, 10, 12].map { CGFloat($0) / 12.0 * size.height }
        
        return ZStack {
            ForEach(yPositions, id: \.self) { y in
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size.width * 2, height: 1)
                    .position(x: size.width, y: size.height - y)
            }
        }
    }
    

    
    private func drawChartWithLabels(sessions: [SavedPracticeSession], in size: CGSize) -> some View { // New function
        let points = calculatePoints(sessions: sessions, in: size, spacing: 30)
        
        if points.count > 1 {
            return AnyView(
                ZStack {
                    // 1️⃣ Draw the trend line first (keeps it in the background)
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

                    // 2️⃣ Render the tap circles LAST so they are on top
                    ForEach(Array(zip(sessions.indices, points)), id: \.0) { index, point in
                        Circle()
                            .fill(sessions[index] == selectedSession ? Color.purple : Color.blue)
                            .frame(width: 12, height: 12)
                            .position(point)
                        // Always show the PPR value above the point
                        Text(String(format: "%.1f", sessions[index].pointsPerRound))
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .offset(y: -15)
                            .position(point)

                        // 🔥 Make the tappable area larger & ensure taps register
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 30, height: 30)  // 👈 Increased size
                            .contentShape(Rectangle())     // 👈 Ensures entire area is tappable
                            .position(point)
                            .onTapGesture {
                               
                                withAnimation(.spring()) {
                                    selectedSession = sessions[index]
                                    showingDetail = true
                                }
                            }
                            .id(index)
                    }

                    // 3️⃣ Popup for the selected session (only shows when tapped)
                    if showingDetail, let session = selectedSession {
                        SessionDetailPopup(
                            session: session,
                            position: CGPoint(x: size.width / 2, y: size.height / 2),
                            onDismiss: {
                                withAnimation(.spring()) {
                                    showingDetail = false
                                    selectedSession = nil
                                }
                            }
                        )
                    }
                }

            )
        }
        return AnyView(EmptyView())
    }
    
    private func calculatePoints(sessions: [SavedPracticeSession], in size: CGSize, spacing: CGFloat) -> [CGPoint] {
        let pprValues = sessions.map { $0.pointsPerRound }
        let maxPPR = 12.0

        return pprValues.enumerated().map { (index, ppr) in
            let x = size.width * 2 - (CGFloat(index) * spacing + 15)  // Keep order correct while anchoring right
            let y = size.height - (CGFloat(min(ppr, maxPPR)) / maxPPR * size.height)
            return CGPoint(x: x, y: y)
        }
    }
}
struct SessionDetailPopup: View {
    let session: SavedPracticeSession
    let position: CGPoint
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme // To detect light/dark mode
    
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
                DetailRow(label: "Off Board", value: "\(session.bagsOffBoard)")
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
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white) // Adaptive background
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
    
    @Environment(\.colorScheme) var colorScheme // To detect light/dark mode
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(colorScheme == .dark ? .white : .black) // Ensure visibility
        }
        .font(.subheadline)
    }
}

struct BagPlacementChart: View {
    let sessions: [SavedPracticeSession]
    @State private var selectedSession: SavedPracticeSession?
    @State private var showingDetail = false
    @State private var selectedLine: Color? = nil
    
    private let inHoleColor = Color.green
    private let onBoardColor = Color.blue
    private let offBoardColor = Color.red
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("📊 Bag Placement Trends")
                .font(.title2)
                .bold()
                .foregroundColor(.blue)
            
            HStack(spacing: 16) {
                ChartLegendItem(color: inHoleColor, label: "In Hole")
                ChartLegendItem(color: onBoardColor, label: "On Board")
                ChartLegendItem(color: offBoardColor, label: "Off Board")
            }
            
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollProxy in
                        ZStack(alignment: .leading) {
                            drawGrid(in: geometry.size)
                            drawBagPlacementChart(sessions: sessions, in: geometry.size)
                        }
                        .frame(width: geometry.size.width * 2)
                        .onAppear {
                            withAnimation {
                                scrollProxy.scrollTo(sessions.count - 1, anchor: .trailing)
                            }
                        }
                    }
                }
                .background(Color.black.opacity(0.05))
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(radius: 10)
    }
    
    private func drawGrid(in size: CGSize) -> some View {
        let yPositions = [0, 25, 50, 75, 100].map { CGFloat($0) / 100.0 * size.height }
        
        return ZStack {
            ForEach(yPositions, id: \.self) { y in
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size.width * 2, height: 1)
                    .position(x: size.width, y: size.height - y)
            }
        }
    }
    
    private func drawBagPlacementChart(sessions: [SavedPracticeSession], in size: CGSize) -> some View {
        let reversedSessions = Array(sessions.reversed())
        
        let inHolePoints = calculatePoints(for: { session in
            let total = Double(session.totalBagsInHole + session.bagsOnBoard + session.bagsOffBoard)
            return total > 0 ? Double(session.totalBagsInHole) / total * 100 : 0
        }, sessions: reversedSessions, in: size, spacing: 30)
        
        let onBoardPoints = calculatePoints(for: { session in
            let total = Double(session.totalBagsInHole + session.bagsOnBoard + session.bagsOffBoard)
            return total > 0 ? Double(session.bagsOnBoard) / total * 100 : 0
        }, sessions: reversedSessions, in: size, spacing: 30)
        
        let offBoardPoints = calculatePoints(for: { session in
            let total = Double(session.totalBagsInHole + session.bagsOnBoard + session.bagsOffBoard)
            return total > 0 ? Double(session.bagsOffBoard) / total * 100 : 0
        }, sessions: reversedSessions, in: size, spacing: 30)
        
        return AnyView(
            ZStack {
                PathLine(points: inHolePoints, color: inHoleColor, isSelected: selectedLine == inHoleColor, onSelect: { selectedLine = inHoleColor })
                PathLine(points: onBoardPoints, color: onBoardColor, isSelected: selectedLine == onBoardColor, onSelect: { selectedLine = onBoardColor })
                PathLine(points: offBoardPoints, color: offBoardColor, isSelected: selectedLine == offBoardColor, onSelect: { selectedLine = offBoardColor })
                
                ForEach(Array(reversedSessions.indices), id: \.self) { index in
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 20, height: 20)
                        .position(inHolePoints[index])
                        .onTapGesture {
                            selectedSession = reversedSessions[index]
                            showingDetail = true
                        }
                        .id(index)
                }
                
                if showingDetail, let session = selectedSession {
                    BagPlacementDetailPopup(
                        session: session,
                        position: CGPoint(x: size.width/2, y: size.height/2),
                        onDismiss: {
                            withAnimation(.spring()) {
                                showingDetail = false
                                selectedSession = nil
                            }
                        }
                    )
                }
            }
        )
    }
    
    private func calculatePoints(
        for valueCalculation: (SavedPracticeSession) -> Double,
        sessions: [SavedPracticeSession],
        in size: CGSize,
        spacing: CGFloat
    ) -> [CGPoint] {
        let values = sessions.map(valueCalculation)
        guard !values.isEmpty else { return [] }
        
        return values.enumerated().map { (index, value) in
            let reversedIndex = sessions.count - index - 1
            let x = size.width * 2 - (CGFloat(reversedIndex) * spacing + 15)
            let y = size.height - (CGFloat(value) / 100.0 * size.height)
            return CGPoint(x: x, y: y)
        }
    }
}

struct PathLine: View {
    let points: [CGPoint]
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        ZStack {
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(color, lineWidth: isSelected ? 4 : 2)
            
            ForEach(points.indices, id: \.self) { index in
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                    if isSelected {
                        // Remove % sign and adjust percentage calculation
                        Text(String(format: "%.1f", 100 - points[index].y / size.height * 100))
                            .font(.caption2)
                            .foregroundColor(color)
                            .offset(y: -15)
                    }
                }
                .position(points[index])
            }
        }
        .contentShape(Path { path in  // This makes the entire line tappable
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        })
        .onTapGesture {
            onSelect()
        }
    }
    
    // Helper to access size in PathLine
    private let size = CGSize(width: 2000, height: 250) // Adjust this to match your chart's size
}

struct ChartLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

// Here's a basic implementation of BagPlacementDetailPopup
struct BagPlacementDetailPopup: View {
    let session: SavedPracticeSession
    let position: CGPoint
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Session Details")
                .font(.headline)
            Text("Bags In Hole: \(session.totalBagsInHole)")
            Text("Bags On Board: \(session.bagsOnBoard)")
            Text("Bags Off Board: \(session.bagsOffBoard)")
            Button("Close") {
                onDismiss()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .position(position)
    }
}
