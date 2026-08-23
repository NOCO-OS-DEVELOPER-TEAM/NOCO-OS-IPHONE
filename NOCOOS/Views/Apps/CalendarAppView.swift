import SwiftUI

struct CalendarAppView: View {
    @State private var month = Date()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.title2.bold())
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
            }
            .foregroundStyle(.white)

            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { d in
                    Text(d).font(.caption.weight(.bold)).foregroundStyle(NOCOOSTheme.textSecondary)
                }
                ForEach(days, id: \.self) { day in
                    if let day {
                        Text("\(day)")
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(isToday(day) ? NOCOOSTheme.accent : Color.white.opacity(0.06), in: Circle())
                            .foregroundStyle(.white)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
    }

    private func shiftMonth(_ delta: Int) {
        if let m = Calendar.current.date(byAdding: .month, value: delta, to: month) {
            month = m
        }
    }

    private func daysInMonth() -> [Int?] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: month)!
        let first = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let weekday = (cal.component(.weekday, from: first) + 5) % 7
        var days: [Int?] = Array(repeating: nil, count: weekday)
        days += range.map { Optional($0) }
        return days
    }

    private func isToday(_ day: Int) -> Bool {
        let cal = Calendar.current
        return cal.isDate(month, equalTo: Date(), toGranularity: .month) && cal.component(.day, from: Date()) == day
    }
}
