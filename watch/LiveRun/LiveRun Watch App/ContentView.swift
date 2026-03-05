import SwiftUI

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @State private var selectedTab = 1

    var body: some View {
        if workoutManager.isRunning {
            TabView(selection: $selectedTab) {
                // Swipe left: Stop button
                VStack {
                    Spacer()
                    Button(action: { workoutManager.stop() }) {
                        Text("Stop")
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.red)
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .padding()
                .tag(0)

                // Main page: Stats
                VStack(alignment: .leading, spacing: 6) {
                    if let start = workoutManager.startDate {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            let elapsed = context.date.timeIntervalSince(start)
                            StatRow(label: "TIME", value: formatDuration(elapsed), unit: "")
                        }
                    }
                    StatRow(label: "HEART RATE", value: workoutManager.heartRate > 0 ? "\(Int(workoutManager.heartRate))" : "\u{2014}", unit: "bpm")
                    StatRow(label: "PACE", value: workoutManager.pace > 0 ? formatPaceCompact(workoutManager.pace) : "\u{2014}", unit: "/km")
                    StatRow(label: "DISTANCE", value: String(format: "%.2f", workoutManager.distanceMeters / 1000), unit: "km")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, -10)
                .tag(1)
            }
            .tabViewStyle(.page)
        } else {
            VStack {
                Spacer()
                Button(action: { workoutManager.start() }) {
                    Text("Start Run")
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding()
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func formatPaceCompact(_ minPerKm: Double) -> String {
        let mins = Int(minPerKm)
        let secs = Int((minPerKm - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, design: .monospaced).monospacedDigit())
                if value != "\u{2014}" && !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
