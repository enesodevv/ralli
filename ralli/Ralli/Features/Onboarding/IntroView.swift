import SwiftUI

/// First-launch introduction: what Ralli does, in three short pages.
/// Lesson cue → court session → visible change. Ends with an optional setup.
struct IntroView: View {
    /// Called once the player leaves the intro. `true` means they want to set preferences now.
    var onFinish: (_ openSetup: Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.ralliReducedMotion) private var motionOverride
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var page = 0
    private let pageCount = 3
    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }
    private var isLast: Bool { page == pageCount - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ralli.").font(RalliTheme.title(28)).tracking(-1.2)
                Spacer()
                if !isLast {
                    Button(L10n.text("intro.skip")) { onFinish(false) }
                        .ralliFont(size: 14, weight: .medium).frame(minWidth: 44, minHeight: 44)
                }
            }.frame(minHeight: 44).padding(.horizontal, 24).padding(.top, 8)
            // Manual paging: one page at a time, moved by the button or a horizontal swipe.
            ScrollView(showsIndicators: false) {
                pageContent(page).padding(24).id(page)
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                                     removal: .move(edge: .leading).combined(with: .opacity)))
            }.frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 30).onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    go(to: page + (value.translation.width < 0 ? 1 : -1))
                })
                .accessibilityAction(named: Text(L10n.text("intro.next"))) { go(to: page + 1) }
            footer
        }.foregroundStyle(RalliTheme.ink).background(RalliTheme.paper.ignoresSafeArea())
    }

    // MARK: Pages
    @ViewBuilder private func pageContent(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            illustration(index).frame(maxWidth: .infinity).frame(height: textSize.isAccessibilitySize ? 180 : 280)
                .background(RalliTheme.ink, in: RoundedRectangle(cornerRadius: RalliTheme.radius)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: L10n.text("intro.\(index + 1).eyebrow"), color: RalliTheme.clay)
                Text(L10n.text("intro.\(index + 1).title")).font(RalliTheme.title(36)).tracking(-1)
                    .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                Text(L10n.text("intro.\(index + 1).body")).ralliFont(size: 16).foregroundStyle(RalliTheme.muted).lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder private func illustration(_ index: Int) -> some View {
        switch index {
        case 0:
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Image(systemName: "mic.fill").font(.system(size: 22)).foregroundStyle(RalliTheme.paper)
                        .frame(width: 56, height: 56).background(RalliTheme.clay, in: Circle())
                    HStack(spacing: 4) {
                        ForEach([10.0, 22, 14, 30, 18, 26, 12, 20, 8], id: \.self) { height in
                            Capsule().fill(RalliTheme.lime).frame(width: 4, height: height)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("Backhand").uppercased(with: L10n.locale)).ralliFont(size: 10, weight: .semibold, design: .monospaced).tracking(2).foregroundStyle(RalliTheme.muted)
                    Text(L10n.text("intro.1.sample")).font(RalliTheme.title(19)).foregroundStyle(RalliTheme.ink).fixedSize(horizontal: false, vertical: true)
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(RalliTheme.paper, in: RoundedRectangle(cornerRadius: RalliTheme.smallRadius))
            }.padding(24)
        case 1:
            HStack(spacing: 22) {
                DrillCourtDiagram(pattern: "serve").frame(width: 92, height: 140)
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.step(2, total: 3).uppercased(with: L10n.locale)).ralliFont(size: 10, weight: .semibold, design: .monospaced).tracking(1.5).foregroundStyle(RalliTheme.lime)
                    Text("07:42").ralliFont(size: 44, weight: .medium, design: .monospaced).foregroundStyle(RalliTheme.lime).minimumScaleFactor(0.5).lineLimit(1)
                    Label(L10n.text("Duraklat"), systemImage: "pause.fill").ralliFont(size: 13, weight: .semibold)
                        .padding(.horizontal, 14).padding(.vertical, 10).foregroundStyle(RalliTheme.ink).background(RalliTheme.lime, in: Capsule())
                }
            }.padding(24)
        default:
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { day in
                        let done = [1, 3, 4, 6].contains(day)
                        ZStack {
                            Circle().fill(done ? RalliTheme.lime : Color.clear)
                            Circle().stroke(done ? RalliTheme.lime : RalliTheme.paper.opacity(0.3), lineWidth: 1.5)
                            if done { Image(systemName: "tennisball.fill").font(.system(size: 12)).foregroundStyle(RalliTheme.ink) }
                        }.frame(width: 30, height: 30)
                    }
                }
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array([4.0, 5, 5, 7].enumerated()), id: \.offset) { item in
                        RoundedRectangle(cornerRadius: 4).fill(item.offset == 3 ? RalliTheme.lime : RalliTheme.paper.opacity(0.35))
                            .frame(width: 30, height: item.element * 12)
                    }
                    Text("4 → 7").ralliFont(size: 22, weight: .medium, design: .monospaced).foregroundStyle(RalliTheme.paper).padding(.leading, 8)
                }
            }.padding(24)
        }
    }

    private func go(to target: Int) {
        let clamped = min(max(target, 0), pageCount - 1)
        guard clamped != page else { return }
        if reduceMotion { page = clamped } else { withAnimation(.easeInOut(duration: 0.3)) { page = clamped } }
    }

    // MARK: Footer
    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Capsule().fill(index == page ? RalliTheme.ink : RalliTheme.line).frame(width: index == page ? 22 : 8, height: 8)
                }
            }.accessibilityElement(children: .ignore)
                .accessibilityLabel(String(format: L10n.text("intro.page"), page + 1, pageCount))
            if isLast {
                PrimaryButton(title: L10n.text("intro.setup"), icon: "slider.horizontal.3") { onFinish(true) }
                Button { onFinish(false) } label: {
                    Text(L10n.text("intro.explore")).ralliFont(size: 15, weight: .medium).frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.plain)
                Text(L10n.text("intro.privacy")).ralliFont(size: 12).foregroundStyle(RalliTheme.muted)
            } else {
                PrimaryButton(title: L10n.text("intro.next"), icon: "arrow.right") { go(to: page + 1) }
            }
        }.padding(.horizontal, 24).padding(.bottom, 12).padding(.top, 8)
    }
}
