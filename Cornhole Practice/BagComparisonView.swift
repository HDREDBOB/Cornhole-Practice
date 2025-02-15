import SwiftUI
import CoreData

struct PerformanceBarView: View {
    let performance: BagPerformance
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background bar
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.3))
                .frame(width: 60, height: 200)
            
            // Foreground bar with gradient
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 60, height: CGFloat(performance.avgPPR / 12.0 * 200))
                .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 0)
            
            VStack {
                Text(String(format: "%.1f", performance.avgPPR))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.2))
                    .cornerRadius(4)
                
                Text(performance.bagType)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                    .frame(width: 55)
            }
            .padding(.bottom, 8)
        }
        .padding(.bottom, 10) // Additional padding at the bottom of the entire ZStack
    }
}

struct BagComparisonView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavedPracticeSession.date, ascending: true)],
        animation: .default)
    private var sessions: FetchedResults<SavedPracticeSession>
    
    private var bagPerformanceMetrics: [String: BagPerformance] {
        let uniqueBagTypes = Set(sessions.compactMap { $0.bagType })
        
        return uniqueBagTypes.reduce(into: [:]) { result, bagType in
            let bagSessions = sessions.filter { $0.bagType == bagType }
            guard !bagSessions.isEmpty else { return }
            
            result[bagType] = calculateBagPerformance(for: bagSessions)
        }
    }
    
    private func calculateBagPerformance(for sessions: [SavedPracticeSession]) -> BagPerformance {
        let totalSessions = Double(sessions.count)
        
        let avgPPR = sessions.reduce(0.0) { $0 + $1.pointsPerRound } / totalSessions
        
        let fourBaggerRate = Double(sessions.reduce(0) { $0 + $1.fourBaggers }) / totalSessions
        
        let totalBags = sessions.reduce(0) { $0 + $1.totalBagsInHole + $1.bagsOnBoard + $1.bagsOffBoard }
        let inHoleBags = sessions.reduce(0) { $0 + $1.totalBagsInHole }
        let onBoardBags = sessions.reduce(0) { $0 + $1.bagsOnBoard }
        let offBoardBags = sessions.reduce(0) { $0 + $1.bagsOffBoard }
        
        let inHolePercentage = totalBags > 0 ? (Double(inHoleBags) / Double(totalBags)) * 100 : 0
        let onBoardPercentage = totalBags > 0 ? (Double(onBoardBags) / Double(totalBags)) * 100 : 0
        let offBoardPercentage = totalBags > 0 ? (Double(offBoardBags) / Double(totalBags)) * 100 : 0
        
        return BagPerformance(
            bagType: sessions.first?.bagType ?? "",
            totalSessions: Int(totalSessions),
            avgPPR: avgPPR,
            fourBaggerRate: Double(fourBaggerRate),
            inHolePercentage: inHolePercentage,
            onBoardPercentage: onBoardPercentage,
            offBoardPercentage: offBoardPercentage,
            bestPPRSession: sessions.max(by: { $0.pointsPerRound < $1.pointsPerRound })?.pointsPerRound ?? 0
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Bag Performance Comparison")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    if bagPerformanceMetrics.isEmpty {
                        Text("No bag performance data available")
                            .foregroundColor(.secondary)
                    } else {
                        // PPR Comparison Chart
                        VStack(alignment: .leading, spacing: 15) {
                            Text("PPR Comparison")
                                .font(.headline)
                                .padding(.top, 15) // Add padding to the top to move it down
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .bottom, spacing: 12) {
                                    ForEach(Array(bagPerformanceMetrics.values).sorted(by: { $0.avgPPR > $1.avgPPR }), id: \.bagType) { performance in
                                        PerformanceBarView(performance: performance)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .background(Color(UIColor.systemGray4))                        .cornerRadius(12)
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                        //.padding(.horizontal)
                        
                        // Performance Cards
                        ForEach(Array(bagPerformanceMetrics.values).sorted(by: { $0.avgPPR > $1.avgPPR }), id: \.bagType) { performance in
                            BagPerformanceCard(performance: performance)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Bag Performance")
            .background(Color(.systemGroupedBackground))
        }
    }
}
struct BagPerformanceCard: View {
    let performance: BagPerformance
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(performance.bagType)
                    .font(.headline)
                Spacer()
                Text("\(performance.totalSessions) Sessions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .background(Color.primary.opacity(colorScheme == .dark ? 0.3 : 0.2))
            
            VStack(alignment: .leading, spacing: 10) {
                PerformanceRow(label: "Average PPR", value: String(format: "%.2f", performance.avgPPR), color: .blue)
                PerformanceRow(label: "Best Session PPR", value: String(format: "%.2f", performance.bestPPRSession), color: .green)
                PerformanceRow(label: "4 Bagger Rate", value: String(format: "%.2f", performance.fourBaggerRate), color: .purple)
            }
            
            Divider()
                .background(Color.primary.opacity(colorScheme == .dark ? 0.3 : 0.2))
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Throw Distribution")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    DistributionBar(percentage: performance.inHolePercentage, color: .green, label: "In Hole")
                    DistributionBar(percentage: performance.onBoardPercentage, color: .blue, label: "On Board")
                    DistributionBar(percentage: performance.offBoardPercentage, color: .red, label: "Off Board")
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray4))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 5, x: 0, y: 2)
        
    }
}

struct PerformanceRow: View {
    let label: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(color.opacity(colorScheme == .dark ? 1.0 : 0.8))
                .fontWeight(.semibold)
        }
    }
}

struct DistributionBar: View {
    @Environment(\.colorScheme) private var colorScheme
    let percentage: Double
    let color: Color
    let label: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Background bar - adjust opacity based on mode
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 40, height: geometry.size.height)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Foreground bar with brighter gradient in dark mode
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color,
                                    color.opacity(colorScheme == .dark ? 0.8 : 0.7)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 40, height: CGFloat(percentage / 100) * geometry.size.height)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .shadow(color: color.opacity(colorScheme == .dark ? 0.4 : 0.3), radius: 2, x: 0, y: 0)
                }
            }
            .frame(height: 50)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 65, alignment: .center)
                .multilineTextAlignment(.center)
            
            Text("\(String(format: "%.1f%%", percentage))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(width: 65, alignment: .center)
        }
        .frame(width: 65)
    }
}

struct BagPerformance {
    let bagType: String
    let totalSessions: Int
    let avgPPR: Double
    let fourBaggerRate: Double
    let inHolePercentage: Double
    let onBoardPercentage: Double
    let offBoardPercentage: Double
    let bestPPRSession: Double
}
