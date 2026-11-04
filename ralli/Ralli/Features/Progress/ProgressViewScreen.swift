import SwiftUI
import Charts

struct ProgressViewScreen: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var selected: PracticeRecord?
    private var comparisons: [PracticeComparison] { PracticeComparison.groups(from: store.records) }
    private var recordedSeconds: Int { store.records.reduce(0) { $0 + $1.seconds } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Eyebrow(text: L10n.text("Skorun ötesinde"))
                    Text(L10n.text("progress.title")).font(RalliTheme.title(39)).tracking(-1).accessibilityAddTraits(.isHeader)
                    weekStrip
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow(text: L10n.text("progress.participation"))
                        Text(String(format: L10n.text("progress.count"), store.completedSessions)).font(RalliTheme.title(29))
                        Label(recordedSeconds < 60 ? L10n.seconds(recordedSeconds) : L10n.minutes(recordedSeconds / 60), systemImage: "clock").ralliFont(size: 15, design: .monospaced)
                        Text(L10n.text("progress.time")).ralliFont(size: 12).foregroundStyle(RalliTheme.muted)
                    }.padding(23).frame(maxWidth: .infinity, alignment: .leading).background(RalliTheme.lime.opacity(0.35), in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                    SectionHeading(title: L10n.text("progress.checks"))
                    Text(L10n.text("progress.checks.body")).ralliFont(size: 14).foregroundStyle(RalliTheme.muted).lineSpacing(4)
                    if comparisons.isEmpty {
                        Text(L10n.text("progress.insufficient")).font(RalliTheme.title(24)).padding(23).frame(maxWidth: .infinity, alignment: .leading).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                    }
                    ForEach(comparisons) { comparison in comparisonCard(comparison) }
                    SectionHeading(title: L10n.text("progress.history"))
                    if store.records.isEmpty { Text(L10n.text("progress.none")).font(RalliTheme.title(24)).foregroundStyle(RalliTheme.muted) }
                    LazyVStack(spacing: 12) {
                        ForEach(store.records) { record in
                            Button { selected = record } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(plan(for: record)?.title ?? L10n.text(record.focus)).font(RalliTheme.title(25))
                                    HStack {
                                        Text(record.date, format: .dateTime.day().month(.abbreviated))
                                        Spacer()
                                        Text(record.seconds < 60 ? L10n.seconds(record.seconds) : L10n.minutes(record.seconds / 60))
                                        Image(systemName: "arrow.up.right")
                                    }.ralliFont(size: 12).foregroundStyle(RalliTheme.muted)
                                    if let score = record.result {
                                        Text((plan(for: record)?.metricTitle ?? L10n.text("practice.benchmark")) + ": \(score)").ralliFont(size: 13)
                                    }
                                    if let reflection = record.reflection { Text(reflection).ralliFont(size: 13).foregroundStyle(RalliTheme.muted).lineLimit(2) }
                                }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(24)
            }.background(RalliTheme.paper).foregroundStyle(RalliTheme.ink).toolbar(.hidden, for: .navigationBar)
                .sheet(item: $selected) { SessionRecordDetail(record: $0).ralliPresentationEnvironment() }
        }
    }
    /// Last seven days, oldest first. A weekly rhythm motivates without punishing a missed day.
    private var week: [Date] {
        let today = Calendar.current.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }
    }
    private var weekRecords: [PracticeRecord] {
        guard let start = week.first else { return [] }
        return store.records.filter { $0.date >= start }
    }
    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow(text: L10n.text("progress.week"))
                Spacer()
                Text(String(format: L10n.text("progress.week.summary"), weekRecords.count, weekRecords.reduce(0) { $0 + $1.seconds } / 60))
                    .ralliFont(size: 12, design: .monospaced).foregroundStyle(RalliTheme.muted)
            }
            HStack(spacing: 0) {
                ForEach(week, id: \.self) { day in
                    let practised = store.records.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }
                    let isToday = Calendar.current.isDateInToday(day)
                    VStack(spacing: 8) {
                        Text(day, format: .dateTime.weekday(.narrow)).ralliFont(size: 11, weight: isToday ? .bold : .regular).foregroundStyle(isToday ? RalliTheme.ink : RalliTheme.muted)
                        ZStack {
                            Circle().fill(practised ? RalliTheme.ink : Color.clear)
                            Circle().stroke(practised ? RalliTheme.ink : RalliTheme.line, lineWidth: 1.5)
                            if practised { Image(systemName: "tennisball.fill").font(.system(size: 13)).foregroundStyle(RalliTheme.lime) }
                        }.frame(width: 34, height: 34)
                    }.frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide)))
                    .accessibilityValue(L10n.text(practised ? "progress.day.done" : "progress.day.none"))
                }
            }
        }.padding(20).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
    }
    private func plan(for record: PracticeRecord) -> PracticePlan? { PracticePlan.library.first { $0.id == record.planID } }
    private func comparisonCard(_ comparison: PracticeComparison) -> some View {
        let records = comparison.records
        let plan = PracticePlan.library.first { $0.id == comparison.planID }
        return VStack(alignment: .leading, spacing: 18) {
            Text(plan?.title ?? comparison.planID).font(RalliTheme.title(27))
            Text(plan?.metricTitle ?? L10n.text("practice.benchmark")).ralliFont(size: 12).foregroundStyle(RalliTheme.muted)
            if !textSize.isAccessibilitySize { Chart(Array(records.suffix(8))) { record in
                BarMark(x: .value("Date", record.date), y: .value("Result", record.result ?? 0)).foregroundStyle(RalliTheme.ink)
            }.chartYScale(domain: 0...Double(max(plan?.maximumScore == 999 ? (records.compactMap(\.result).max() ?? 1) : (plan?.maximumScore ?? 10), 1)))
                .frame(height: 150).accessibilityHidden(true) }
            comparisonLayout {
                resultLabel(L10n.text("progress.previous"), record: records[records.count - 2])
                if !textSize.isAccessibilitySize { Spacer() }
                resultLabel(L10n.text("progress.latest"), record: records[records.count - 1])
            }
            Text(L10n.text("progress.conditions")).ralliFont(size: 12).foregroundStyle(RalliTheme.muted).lineSpacing(3)
        }.padding(22).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(format: L10n.text("a11y.comparison"), plan?.title ?? comparison.planID))
    }
    private var comparisonLayout: AnyLayout {
        textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20)) : AnyLayout(HStackLayout(alignment: .top))
    }
    private func resultLabel(_ title: String, record: PracticeRecord) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).ralliFont(size: 12).foregroundStyle(RalliTheme.muted)
            Text("\(record.result ?? 0)").font(RalliTheme.title(33))
            Text(record.date, format: .dateTime.day().month(.abbreviated)).ralliFont(size: 11).foregroundStyle(RalliTheme.muted)
        }
    }
}

struct SessionRecordDetail: View {
    let record: PracticeRecord
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    private var plan: PracticePlan? { PracticePlan.library.first { $0.id == record.planID } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(plan?.title ?? L10n.text(record.focus)).font(RalliTheme.title(34))
                    Text(record.date, format: .dateTime.day().month(.wide).year()).foregroundStyle(RalliTheme.muted)
                    Eyebrow(text: L10n.text("progress.time"))
                    Text(record.seconds < 60 ? L10n.seconds(record.seconds) : L10n.minutes(record.seconds / 60)).font(RalliTheme.title(30))
                    if let score = record.result {
                        Text(plan?.metricTitle ?? L10n.text("practice.benchmark")).font(.headline)
                        Text("\(score)").font(RalliTheme.title(40))
                    } else { Text(L10n.text("progress.no.result")).foregroundStyle(RalliTheme.muted) }
                    if let reflection = record.reflection { Eyebrow(text: L10n.text("practice.reflection")); Text(reflection).lineSpacing(5) }
                    if let note = store.notes.first(where: { $0.id == record.noteID }) {
                        Eyebrow(text: L10n.text("progress.linked"))
                        Text(note.title).font(RalliTheme.title(25))
                        Text(note.text).lineSpacing(5)
                    }
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            }.background(RalliTheme.paper).foregroundStyle(RalliTheme.ink)
                .navigationTitle(L10n.text("progress.session")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("Tamam")) { dismiss() } } }
        }
    }
}
