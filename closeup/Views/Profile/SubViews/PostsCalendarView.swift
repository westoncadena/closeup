import SwiftUI

// Assuming Post and UserProfile models are defined elsewhere and accessible.
// UserProfile is available from closeup/Models/UserProfile.swift
// Post model is available from closeup/Models/Post.swift

struct PostsCalendarView: View {
    // User for whom to display posts
    let user: UserProfile

    @State private var currentDate: Date = Date() // Represents the month/year being viewed
    @State private var selectedDate: Date? = nil // For tapping on a day

    // Services
    private let postService = PostService()

    // State for posts, loading, and error handling
    @State private var posts: [Post] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    // Computed property for dates that have posts
    private var postDates: Set<Date> {
        Set(posts.map { Calendar.current.startOfDay(for: $0.createdAt) })
    }

    // Initializer to set a default starting month if needed (e.g., current month or a specific one for UI reasons)
    // If you want it to always default to the current real-world month, you can remove this or adjust.
    init(user: UserProfile) {
        self.user = user
        // Example: Set initial currentDate to May 2025 if that's a design choice, otherwise use Date()
        // let initialDateComponents = DateComponents(year: 2025, month: 5, day: 1)
        // if let initialDate = Calendar.current.date(from: initialDateComponents) {
        //     _currentDate = State(initialValue: initialDate)
        // } else {
        //     _currentDate = State(initialValue: Date())
        // }
        // For now, let's default to the current month of the current year.
         _currentDate = State(initialValue: Date())
    }

    var body: some View {
        // Wrapped in a VStack to handle loading/error states before showing the calendar
        VStack {
            if isLoading {
                ProgressView("Loading posts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Error loading posts:")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await loadUserPosts()
                        }
                    }
                    .padding(.top, 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // The existing calendar UI structure
                NavigationView { // Consider if NavigationView is needed here or if provided by parent (ProfileView)
                    VStack(spacing: 0) {
                        headerView
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        
                        weekdaysHeaderView
                            .padding(.horizontal)

                        calendarGridView
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        
                        // Optionally, display posts for the selectedDate here
                        if let selectedDate = selectedDate {
                            postsForSelectedDateView(date: selectedDate)
                        } else {
                            Spacer() // Pushes everything to the top if no date selected
                        }
                    }
                    .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
                    .navigationBarHidden(true)
                }
            }
        }
        .onAppear {
            Task {
                await loadUserPosts()
            }
        }
        // .colorScheme(.dark) // Removed to default to light scheme
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Journal")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary) // Changed from .white
                    Text(currentDate, formatter: yearFormatter)
                        .font(.title3)
                        .foregroundColor(.secondary) // Changed from Color.gray
                }
                Spacer()
                // Placeholder for icons from the image (menu, search, etc.)
                // For now, keeping it simple
            }
            
            HStack {
                Text(currentDate, formatter: monthFormatter)
                    .font(.title2.bold())
                    .foregroundColor(.primary) // Changed from .white
                Spacer()
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.top, 20) // Space from top for status bar
    }
    
    // MARK: - Weekdays Header
    private var weekdaysHeaderView: some View {
        HStack {
            ForEach(0..<Calendar.current.veryShortWeekdaySymbols.count, id: \.self) { index in
                let daySymbol = Calendar.current.veryShortWeekdaySymbols[index]
                Text(daySymbol.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary) // Changed from Color.gray
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Calendar Grid View
    private var calendarGridView: some View {
        let days = generateDaysInMonth(for: currentDate)
        let columns = Array(repeating: GridItem(.flexible()), count: 7)

        // Added a ScrollView in case the content (postsForSelectedDateView) makes the view too tall
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(days, id: \.self) { date in
                    DayView(date: date,
                            currentMonth: currentDate,
                            hasPost: postDates.contains(Calendar.current.startOfDay(for: date)),
                            isSelected: selectedDate == date,
                            action: {
                                self.selectedDate = date // Select the date
                                // Action to show posts for this day can be handled by postsForSelectedDateView
                           }
                    )
                }
            }
        }
    }

    // MARK: - Posts for Selected Date View (New)
    @ViewBuilder
    private func postsForSelectedDateView(date: Date) -> some View {
        let postsOnDay = posts.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
        
        if postsOnDay.isEmpty {
            Text("No posts on \(date, formatter: dateFormatter)")
                .foregroundColor(.gray)
                .padding()
        } else {
            List {
                Section(header: Text("Posts on \(date, formatter: dateFormatter)")) {
                    ForEach(postsOnDay) { post in
                        // Using a simple Text view for now, can be customized
                        // Consider creating a PostRowView or similar if more complex display is needed
                        VStack(alignment: .leading) {
                            HTMLTextView(htmlContent: post.content) // Using HTMLTextView
                            Text(post.createdAt, style: .time)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(minHeight: 100, maxHeight: 300) // Adjust size as needed
        }
    }
    
    // MARK: - Helper Functions
    private func generateDaysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: date),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }

        var days: [Date] = []
        _ = monthInterval.start
        let lastDayOfMonth = monthInterval.end
        
        // Start from the beginning of the week containing the first day of the month
        var current = monthFirstWeek.start
        let calendar = Calendar.current

        while current < lastDayOfMonth || calendar.isDate(current, inSameDayAs: lastDayOfMonth) || (calendar.component(.weekday, from: current) != calendar.firstWeekday && calendar.isDate(current, inSameDayAs: calendar.date(byAdding: .day, value: (calendar.firstWeekday + 6 - calendar.component(.weekday, from: current)) % 7, to: current)! ) ) {
            // Add days until we cover the last week that contains the last day of the month
             if days.count >= 42 { break } // Max 6 weeks * 7 days
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
            
            // Ensure the loop terminates by breaking if we've filled a typical 6-week display and are past the month end
             if days.count > 34 && current > lastDayOfMonth && calendar.component(.weekday, from: current) == calendar.firstWeekday {
                 break
             }
        }
        return days
    }

    private func changeMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: currentDate) {
            currentDate = newDate
            selectedDate = nil // Clear selection when month changes
        }
    }

    // MARK: - Formatters
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }
    
    private var yearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }
    
    private var dateFormatter: DateFormatter { // For printing tapped date and section header
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // Function to load posts for the current user
    func loadUserPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPosts = try await postService.fetchPosts(forUserIds: [user.id])
            // Sort by creation date if needed, though for calendar view, the date itself is key
            self.posts = fetchedPosts.sorted(by: { $0.createdAt < $1.createdAt })
            print("Successfully loaded \\(posts.count) posts for user: \\(user.username) for calendar view.")
        } catch {
            print("Error loading posts for user \\(user.username) in calendar: \\(error)")
            self.errorMessage = error.localizedDescription
            self.posts = [] // Clear posts on error
        }
        isLoading = false
    }
}

// MARK: - Day View (Cell)
struct DayView: View {
    let date: Date
    let currentMonth: Date // To check if the date is in the currently displayed month
    let hasPost: Bool
    let isSelected: Bool
    let action: () -> Void
    
    private var calendar = Calendar.current // This private stored property made the synthesized init private

    // Explicit internal initializer to override the private synthesized one
    init(date: Date, currentMonth: Date, hasPost: Bool, isSelected: Bool, action: @escaping () -> Void) {
        self.date = date
        self.currentMonth = currentMonth
        self.hasPost = hasPost
        self.isSelected = isSelected
        self.action = action
    }

    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        Text("\(calendar.component(.day, from: date))")
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(cellBackground)
            .foregroundColor(textColor)
            .cornerRadius(8)
            .opacity(isInCurrentMonth ? 1.0 : 0.3) // Dim days not in current month
            .onTapGesture {
                if isInCurrentMonth { // Only allow tapping on days in the current month
                    action()
                }
            }
    }
    
    private var cellBackground: Color {
        if !isInCurrentMonth { return Color.clear }
        if isSelected { return .blue } 
        // For light mode, if "today" is just white, it won't stand out against other white cells.
        // Let's give it a very light gray background or a subtle accent.
        if isToday { return Color(UIColor.systemGray5) } 
        if hasPost { return .orange.opacity(0.7) } 
        return Color(UIColor.secondarySystemGroupedBackground) // Light cells, or .white if secondarySystemGroupedBackground is too dark
    }
    
    private var textColor: Color {
        if !isInCurrentMonth { return .gray }
        if isSelected { return .white } // Selected text is white on blue background
        if isToday { return .blue } // Today's text remains blue
        return .primary // Default text color for light mode
    }
}


#Preview {
    // Create a mock UserProfile for the preview
    let mockPreviewUser = UserProfile(
        id: UUID(),
        username: "calendar_preview",
        firstName: "Cal",
        lastName: "Endar",
        phoneNumber: nil,
        profilePicture: nil, // Provide a URL string if you have a placeholder image
        lastLogin: Date(),
        joinedAt: Date()
    )
    PostsCalendarView(user: mockPreviewUser)
} 
