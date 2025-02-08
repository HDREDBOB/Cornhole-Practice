import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(gradient:
                    Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 35) {
                    // Top Icon
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "figure.disc.sports")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                        )
                        .padding(.top, 40)
                    
                    Text("Cornhole")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Practice Tracker")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    // Buttons
                    NavigationLink(destination: ContentView()) {
                        MenuButton(
                            title: "Let's Practice",
                            icon: "figure.disc.sports",
                            color: .blue
                        )
                    }
                    
                    NavigationLink(destination: SessionHistoryView()) {
                        MenuButton(
                            title: "View History",
                            icon: "clock.arrow.circlepath",
                            color: .green
                        )
                    }
                    
                    NavigationLink(destination: TrendsView()) {
                        MenuButton(
                            title: "View Trends",
                            icon: "chart.xyaxis.line",
                            color: .purple
                        )
                    }
                    
                    NavigationLink(destination: BagTypesManagementView()) {
                        MenuButton(
                            title: "Manage Bag Types",
                            icon: "bag.fill",
                            color: .orange
                        )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.2)))
    }
}

