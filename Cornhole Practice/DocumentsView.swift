import SwiftUI

struct DocumentationView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Cornhole Practice Tracker Documentation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    // Introduction
                    Text("""
                    Welcome to *Cornhole Practice Tracker*, an app designed to help you track and analyze your cornhole practice sessions. Whether you’re a beginner or a seasoned player, this app provides detailed statistics and trends to improve your game. This documentation will guide you through setup, features, and usage.
                    """)
                    .font(.body)
                    
                    // Introduction Section
                    Text("Introduction")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("""
                    *Cornhole Practice Tracker* is a tool for monitoring your cornhole practice performance. It allows you to record practice sessions, view key metrics such as points per round (PPR) and bag placement, and analyze trends over time. The app supports both light and dark modes for a seamless user experience.
                    """)
                    .font(.body)
                    
                    // Getting Started Section
                    Text("Getting Started")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("""
                    Follow these steps to start using *Cornhole Practice Tracker*:

                    1. **Download and Install** – Download *Cornhole Practice Tracker* from the App Store and install it on your iPhone or iPad.
                    2. **Launch the App** – Open the app to access the main interface, which includes the “Home” screen.
                    3. **Start a Practice Session** – From the “Home” screen, tap “Practice” to begin tracking your throws. Enter details such as bags in the hole, bags on the board, bags off the board, and four-baggers.
                    4. **Save and Track** – After completing a session, save it to store the data. Your performance metrics will be available for review on the “Trends” screen.
                    """)
                    .font(.body)
                    
                    // Features Section
                    Text("Features")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("""
                    The app includes several features to help you track and analyze your cornhole practice sessions. Below is an overview of the main components, accessible from the “Home” screen.
                    """)
                    .font(.body)
                    
                    // Home Screen Subsection
                    Text("Home Screen")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("""
                    The “Home” screen is the main entry point of the app, providing navigation to all key features. It features a clean design with a gradient background and a list of navigation buttons. The following options are available:

                    - **Practice** – Takes you to the practice session interface, where you can start a new session and track your throws.
                    - **History** – Displays a list of all past practice sessions, allowing you to review details and trends.
                    - **Trends** – Shows detailed statistics and trends for your practice sessions, including performance summaries, throw distribution, and trend charts.
                    - **Bag Performance** – Provides insights into how different bag types perform, based on your practice data.
                    - **Manage Bag Types** – Allows you to add, edit, and manage different types of cornhole bags.
                    - **Help** – Takes you to this documentation for guidance on using the app.
                    """)
                    .font(.body)
                    
                    // Practice Trends Subsection
                    Text("Practice Trends Screen")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("""
                    The “Practice Trends” screen is the central hub for viewing your performance data. It includes the following sections:

                    - **Performance Overview** – Displays a summary of your practice sessions, including:
                      - Total number of sessions.
                      - Average points per round (PPR).
                      - Total bags thrown.
                      - Four-bagger rate (average number of four-baggers per session).
                      - Trends in PPR and four-bagger rate, shown as percentage changes.
                    - **Throw Distribution** – A pie chart illustrating the percentage of bags landing in the hole, on the board, and off the board.
                    - **PPR Trend** – A line chart showing your points per round (PPR) over time. Tap on any data point to view a popup with detailed session statistics.
                    - **Bag Placement Trends** – A line chart displaying trends in bag placement (in hole, on board, off board) over time. Tap on a line to highlight it and view percentage values.
                    - **Detailed Insights** – A summary of key achievements, including:
                      - Best session PPR.
                      - Most four-baggers in a single session.
                      - Highest in-hole percentage across all sessions.
                    - **Load More Sessions** – If you have more than 100 sessions, a “Load More Sessions” button appears, allowing you to load additional data in batches of 100.
                    """)
                    .font(.body)
                    
                    // Session Details Popup Subsection
                    Text("Session Details Popup")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("""
                    When you tap on a data point in the PPR Trend chart, a popup displays detailed statistics for that session, including:
                    - Points per round (PPR).
                    - Bags in the hole.
                    - Bags on the board.
                    - Bags off the board.
                    - Four-baggers.
                    - Date of the session.
                    """)
                    .font(.body)
                    
                    // Bag Placement Details Popup Subsection
                    Text("Bag Placement Details Popup")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("""
                    When you tap on a data point in the Bag Placement Trends chart, a popup displays the bag placement statistics for that session, including:
                    - Bags in the hole.
                    - Bags on the board.
                    - Bags off the board.
                    """)
                    .font(.body)
                    
                    // Bag Management Subsection
                    Text("Bag Management Screen")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("""
                    The “Bag Management” screen allows you to manage different types of cornhole bags, which can be useful for tracking performance with various bag types. Features include:

                    - **List of Bag Types** – Displays all bag types currently in use, with the default bag type marked by a filled star. The “Default” bag type is always present and cannot be deleted.
                    - **Set Default Bag** – Tap the star next to a bag type to set it as the default. The default bag type is used as the baseline for performance comparisons in the “Bag Performance” screen.
                    - **Add New Bag** – Tap the “Add New Bag” button to open a popup where you can enter a new bag type name. Bag names must be unique and cannot be empty or “Default”. Once added, the new bag type is saved to the list.
                    - **Delete Bag Types** – Swipe left on a bag type to delete it, except for the “Default” bag type, which is protected. Deleted bag types are removed from the list and no longer available for selection in practice sessions.
                    - **Persistence** – Bag types and the default bag type are saved to the device’s storage, ensuring they persist between app launches.
                    """)
                    .font(.body)
                    
                    // Pagination and Refresh Subsection
                    Text("Pagination and Refresh")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("""
                    - **Pagination** – The app loads sessions in batches of 100. Use the “Load More Sessions” button to view additional sessions.
                    - **Refresh** – Pull down on the “Practice Trends” screen to refresh the data and reset to the first batch of 100 sessions.
                    """)
                    .font(.body)
                    
                    // Data and Stats Section
                    Text("Data and Stats")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("""
                    The app tracks several key metrics to help you analyze your performance. Below is an explanation of the primary statistics and trends:

                    - **Points Per Round (PPR)** – A measure of your scoring efficiency per round, calculated as the total points divided by the number of rounds in a session.
                    - **Bag Placement** – Tracks where your bags land:
                      - **In Hole** – Bags that go into the hole (worth 3 points each).
                      - **On Board** – Bags that land on the board (worth 1 point each).
                      - **Off Board** – Bags that miss the board entirely (worth 0 points).
                    - **Four-Baggers** – The number of times you land all four bags in the hole in a single round.
                    - **PPR Trend** – The percentage change in your PPR over recent sessions, calculated by comparing a weighted average of your 10 most recent sessions to an older subset.
                    - **Four-Bagger Trend** – The percentage change in your four-bagger rate over recent sessions, calculated similarly to the PPR trend.
                    - **Throw Distribution** – The percentage of total bags thrown that land in the hole, on the board, or off the board.
                    - **Best Session PPR** – The highest PPR achieved in any single session.
                    - **Most Four-Baggers** – The highest number of four-baggers in any single session.
                    - **Highest In-Hole Percentage** – The highest percentage of bags landing in the hole in any single session.
                    """)
                    .font(.body)
                    
                    // Tips and Tricks Section
                    Text("Tips and Tricks")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("""
                    - **Use Trends to Improve** – Focus on the PPR Trend and Bag Placement Trends to identify areas for improvement. For example, if your “Off Board” percentage is high, practice your aim to land more bags on the board.
                    - **Tap for Details** – Tap on data points in the charts to view detailed session stats, helping you pinpoint what went well or what needs work.
                    - **Refresh Regularly** – Use the refresh feature to ensure your data is up to date, especially after adding new sessions.
                    - **Dark Mode** – The app supports dark mode for comfortable use in low-light conditions. All text and charts are optimized for visibility in both light and dark modes.
                    - **Manage Bag Types** – Use the “Bag Management” screen to track performance with different bag types. Set a default bag type to use as a baseline for comparisons, and add or delete bag types as needed.
                    """)
                    .font(.body)
                    
                    // FAQs Section
                    Text("FAQs")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("""
                    **Q: How many sessions can I track?**  
                    A: There is no limit to the number of sessions you can track. The app loads sessions in batches of 100 for performance, but you can load more as needed.

                    **Q: What happens if I delete a session?**  
                    A: Deleting a session removes it from the database, and the app recalculates all trends and statistics to reflect the updated data.

                    **Q: Why are some stats not visible in dark mode?**  
                    A: This issue has been addressed in the latest version. Ensure you have updated the app, and all text should be visible in both light and dark modes.

                    **Q: How is the PPR trend calculated?**  
                    A: The PPR trend is calculated by comparing a weighted average of your 10 most recent sessions to a weighted average of the older half of those sessions. The result is expressed as a percentage change.

                    **Q: Can I export my data?**  
                    A: Data export is not currently supported, but you can view all your stats within the app. Future updates may include export functionality.

                    **Q: What happens if I delete a bag type?**  
                    A: Deleting a bag type removes it from the list of available bag types, but it does not affect past sessions where that bag type was used. The “Default” bag type cannot be deleted.
                    """)
                    .font(.body)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
