import SwiftUI

// Assuming Post and UserProfile models are defined elsewhere and accessible.
// UserProfile is available from closeup/Models/UserProfile.swift
// Post model is available from closeup/Models/Post.swift

struct PostsCalendarView: View {
    @State private var currentDate: Date = Date() // Represents the month/year being viewed
    @State private var selectedDate: Date? = nil // For tapping on a day

    // Mock Data
    let mockUser = UserProfile(
        id: UUID(),
        username: "journaleer",
        firstName: "Alex",
        lastName: "Chen",
        phoneNumber: nil,
        profilePicture: nil,
        lastLogin: Date(),
        joinedAt: Date()
    )

    let mockPosts: [Post]
    private var postDates: Set<Date> = []

    init() {
        let calendar = Calendar.current
        var posts: [Post] = []

        // Create a specific date for May 20, 2025 for mocking, as in image
        var components2025 = DateComponents(year: 2025, month: 5, day: 20)
        let may20_2025 = calendar.date(from: components2025)!
        
        // Create a specific date for May 23, 2025 for mocking, as in image
        components2025 = DateComponents(year: 2025, month: 5, day: 23)
        let may23_2025 = calendar.date(from: components2025)!
        
        // Create a specific date for June 10, 2025
        components2025 = DateComponents(year: 2025, month: 6, day: 10)
        let june10_2025 = calendar.date(from: components2025)!

        posts.append(Post(id: UUID(), userId: mockUser.id, content: "Journal entry for May 20, 2025", mediaUrls: ["https://example.com/image.jpg"], mediaTypes: ["image"], audience: "private", type: "journal", promptId: nil, threadId: nil, createdAt: may20_2025))
        posts.append(Post(id: UUID(), userId: mockUser.id, content: "Thoughts on May 23rd", mediaUrls: nil, mediaTypes: nil, audience: "private", type: "journal", promptId: nil, threadId: nil, createdAt: may23_2025))
        posts.append(Post(id: UUID(), userId: mockUser.id, content: "Another post on May 23rd!", mediaUrls: nil, mediaTypes: nil, audience: "private", type: "journal", promptId: nil, threadId: nil, createdAt: may23_2025))
        posts.append(Post(id: UUID(), userId: mockUser.id, content: "June thoughts", mediaUrls: nil, mediaTypes: nil, audience: "private", type: "journal", promptId: nil, threadId: nil, createdAt: june10_2025))
        
        // Add some random posts for the current month and previous/next for testing
        for i in 0..<5 {
            posts.append(Post(id: UUID(), userId: mockUser.id, content: "Random post \(i)", mediaUrls: nil, mediaTypes: nil, audience: "private", type: "journal", promptId: nil, threadId: nil, createdAt: calendar.date(byAdding: .day, value: -Int.random(in: 0...30), to: Date())!))
        }
        
        self.mockPosts = posts
        self.postDates = Set(posts.map { calendar.startOfDay(for: $0.createdAt) })
        
        // Set initial currentDate to May 2025 to match the image
        let initialDateComponents = DateComponents(year: 2025, month: 5, day: 1)
        if let initialDate = calendar.date(from: initialDateComponents) {
            _currentDate = State(initialValue: initialDate)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                
                weekdaysHeaderView
                    .padding(.horizontal)

                calendarGridView
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                
                Spacer() // Pushes everything to the top
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)) // Standard light system background
            .navigationBarHidden(true) // Hiding default nav bar to use custom header
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

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(days, id: \.self) { date in
                DayView(date: date,
                        currentMonth: currentDate,
                        hasPost: postDates.contains(Calendar.current.startOfDay(for: date)),
                        isSelected: selectedDate == date,
                        action: {
                            self.selectedDate = date
                            let postsOnDay = mockPosts.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
                            print("Tapped on \(dateFormatter.string(from: date)). Posts: \(postsOnDay.count)")
                            if !postsOnDay.isEmpty {
                                print("Posts content: ")
                                postsOnDay.forEach { print("- \($0.content)") }
                            }
                       }
                )
            }
        }
    }

    // MARK: - Helper Functions
    private func generateDaysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: date),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }

        var days: [Date] = []
        let firstDayOfMonth = monthInterval.start
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
    
    private var dateFormatter: DateFormatter { // For printing tapped date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
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
    PostsCalendarView()
} 
