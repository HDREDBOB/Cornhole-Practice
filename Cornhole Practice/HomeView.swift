import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.1),
                        Color.purple.opacity(colorScheme == .dark ? 0.15 : 0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // Header section
                        VStack(spacing: 15) {
                            Circle()
                                .fill(Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.1))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "figure.disc.sports")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.blue.opacity(colorScheme == .dark ? 1.0 : 0.8))
                                )
                                .rotation3DEffect(.degrees(360), axis: (x: 0, y: 1, z: 0))
                                .animation(.easeInOut(duration: 1.0), value: true)
                            
                            VStack(spacing: 8) {
                                Text("Cornhole")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                Text("Practice Tracker")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Navigation buttons
                        VStack(spacing: 15) {
                            NavigationLink(destination: ContentView()) {
                                SimplifiedMenuButton(
                                    title: "Practice",
                                    icon: "figure.disc.sports",
                                    color: .blue
                                )
                            }
                            
                            NavigationLink(destination: SessionHistoryView()) {
                                SimplifiedMenuButton(
                                    title: "History",
                                    icon: "clock.arrow.circlepath",
                                    color: .green
                                )
                            }
                            
                            NavigationLink(destination: TrendsView()) {
                                SimplifiedMenuButton(
                                    title: "Trends",
                                    icon: "chart.xyaxis.line",
                                    color: .purple
                                )
                            }
                            
                            NavigationLink(destination: BagComparisonView()) {
                                SimplifiedMenuButton(
                                    title: "Bag Performance",
                                    icon: "sportscourt.fill",
                                    color: .red
                                )
                            }
                            
                            NavigationLink(destination: BagTypesManagementView()) {
                                SimplifiedMenuButton(
                                    title: "Manage Bag Types",
                                    icon: "bag.fill",
                                    color: .orange
                                )
                            }
                            
                            // Added Help button
                            NavigationLink(destination: DocumentationView()) {
                                SimplifiedMenuButton(
                                    title: "Help",
                                    icon: "questionmark.circle.fill",
                                    color: .cyan // Using cyan to stand out, but feel free to change, babe! 😘
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct SimplifiedMenuButton: View {
    let title: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(color.opacity(colorScheme == .dark ? 1.0 : 0.8))
            
            Text(title)
                .font(.headline)
                .foregroundColor(Color.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
        .contentShape(Rectangle())
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
