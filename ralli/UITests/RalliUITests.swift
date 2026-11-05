import XCTest

/// End-to-end flows driven like a real player. Runs in English with a private, freshly wiped store.
final class RalliUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    private func launch(reset: Bool = true, skipIntro: Bool = true, extra: [String] = []) {
        app.launchArguments = ["-ralli-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
            + (reset ? ["-ralli-reset"] : []) + (skipIntro ? ["-ralli-skip-intro"] : []) + extra
        app.launch()
    }
    private func tab(_ name: String) { app.tabBars.buttons[name].tap() }
    private func tapButton(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[label].firstMatch
        // Lists build rows lazily: scroll until the button exists, then until it can be tapped.
        var tries = 0
        while !button.waitForExistence(timeout: tries == 0 ? 3 : 1) && tries < 8 { app.swipeUp(velocity: .slow); tries += 1 }
        XCTAssertTrue(button.exists, "missing button \(label)", file: file, line: line)
        scrollTo(button)
        button.tap()
    }
    /// Scrolls until the element sits comfortably on screen, away from the home indicator.
    private func scrollTo(_ element: XCUIElement, attempts: Int = 8, awayFromEdge: Bool = false) {
        let safeBottom = app.frame.maxY - 120
        var count = 0
        while (!element.isHittable || (awayFromEdge && element.frame.maxY > safeBottom)) && count < attempts {
            app.swipeUp(velocity: .slow); count += 1
        }
    }
    /// Any element whose label contains the text, ignoring case (eyebrows are shown in capitals).
    private func text(_ value: String, timeout: TimeInterval = 5) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", value)).firstMatch
    }
    /// Waits for the text, scrolling down like a player would if it is further down the page.
    private func assertShows(_ value: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        let element = text(value)
        var found = element.waitForExistence(timeout: timeout)
        var tries = 0
        while !found && tries < 6 { app.swipeUp(velocity: .slow); found = element.waitForExistence(timeout: 1); tries += 1 }
        XCTAssertTrue(found, "expected to see “\(value)”", file: file, line: line)
    }
    /// Finds a drill the way a player would: search for it, then open it.
    private func openDrill(_ title: String) {
        tab("Practice")
        let search = app.textFields["Search sessions"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        if let current = search.value as? String, !current.isEmpty, current != "Search sessions" { app.buttons["Reset filters"].firstMatch.tap() }
        search.tap(); search.typeText(title)
        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "drill \(title)")
        row.tap()
        assertShows(title)
    }

    // MARK: First launch
    func testIntroThenSetupLeadsToAMatchingRecommendation() {
        launch(skipIntro: false)
        assertShows("Save the one tip")
        tapButton("Continue"); assertShows("Take it")
        tapButton("Continue"); assertShows("See what")
        tapButton("Set it up for me")
        XCTAssertTrue(app.navigationBars["Your court, your way"].waitForExistence(timeout: 5))
        app.buttons["Left"].tap()
        app.buttons["Partner"].tap()
        tapButton("Find my session")
        assertShows("A SESSION THAT FITS")
        // Intro is not shown again on the next launch.
        app.terminate(); launch(reset: false, skipIntro: false)
        XCTAssertFalse(text("Save the one tip").waitForExistence(timeout: 2))
    }
    func testSkippingTheIntroLandsOnToday() {
        launch(skipIntro: false)
        tapButton("Skip")
        assertShows("Your game,")
        XCTAssertTrue(app.tabBars.buttons["Today"].isSelected)
    }

    // MARK: Library
    func testSearchFiltersAndFavourites() {
        launch()
        tab("Practice")
        let search = app.textFields["Search sessions"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap(); search.typeText("lob")
        assertShows("Lob and overhead")
        XCTAssertFalse(text("Find your depth").exists)
        app.buttons["Reset filters"].firstMatch.tap()   // the clear (x) button in the search field
        // Nonsense search shows the empty state with a reset.
        search.tap(); search.typeText("zzzz")
        assertShows("No sessions match")
        tapButton("Reset filters")
        assertShows("Trust your backhand")
        // Save a drill and filter by saved.
        app.buttons["Save session"].firstMatch.tap()
        tapButton("Saved")
        assertShows("Trust your backhand")
        XCTAssertFalse(text("Find your depth").exists)
    }

    // MARK: Session
    func testFullSessionIsRecordedInProgress() {
        launch()
        openDrill("A toss you can trust")
        tapButton("Start session")
        assertShows("Step 1 of 3")
        tapButton("Pause"); tapButton("Resume")
        tapButton("Next step"); assertShows("Step 2 of 3")
        tapButton("Next step"); assertShows("Step 3 of 3")
        tapButton("Review session")
        assertShows("Keep the")
        let toggle = app.switches["Record the final check"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.switches.firstMatch.tap()
        let stepper = app.steppers.firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.buttons["Increment"].tap(); stepper.buttons["Increment"].tap()
        tapButton("Save session")
        tab("Progress")
        assertShows("Sessions recorded: 1")
        assertShows("A toss you can trust")
        assertShows("Tosses on target out of 10: 2")
    }
    func testSaveAndLeaveRestoresAfterRelaunch() {
        launch()
        openDrill("Shadow swings")
        tapButton("Start session")
        tapButton("Next step"); assertShows("Step 2 of 3")
        tapButton("Leave session")
        tapButton("Save and leave")
        tab("Today")
        assertShows("Pick up where you left off.")
        app.terminate(); launch(reset: false)
        assertShows("Pick up where you left off.")
        tapButton("Resume saved session")
        assertShows("Step 2 of 3")
        assertShows("Restored and paused")
    }
    func testOtherDrillsStayBrowsableWhileASessionIsSaved() {
        launch()
        openDrill("Shadow swings")
        tapButton("Start session")
        tapButton("Leave session"); tapButton("Save and leave")
        // Another drill opens normally and shows its motion.
        openDrill("Serve with intention")
        assertShows("See how it's done")
        // Starting it asks before replacing the saved session.
        tapButton("Start session")
        XCTAssertTrue(app.alerts["You have a saved session"].waitForExistence(timeout: 5))
        app.alerts.buttons["Discard it and start this one"].tap()
        assertShows("Step 1 of 3")
    }
    func testDiscardingASessionRecordsNothing() {
        launch()
        openDrill("Shadow swings")
        tapButton("Start session")
        tapButton("Leave session"); tapButton("Discard session")
        tab("Progress")
        assertShows("Your first session will start your story here.")
        tab("Today")
        XCTAssertFalse(text("Pick up where you left off.").waitForExistence(timeout: 2))
    }

    // MARK: Journal
    func testNoteCanBeWrittenUsedEditedAndDeleted() {
        launch()
        tab("Journal")
        tapButton("Add a lesson note")
        let body = app.textViews.firstMatch
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        body.tap(); body.typeText("Turn the shoulders before the bounce")
        app.navigationBars.buttons["Save"].tap()
        // The first line becomes the title when the title is empty.
        assertShows("Turn the shoulders before the bounce")
        tapButton("Practise with this cue")
        XCTAssertTrue(app.tabBars.buttons["Today"].isSelected)
        assertShows("TAKE THIS TO COURT")
        // Edit
        tab("Journal")
        app.buttons["More actions"].firstMatch.tap()
        app.buttons["Edit"].tap()
        let edit = app.textViews.firstMatch
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap(); edit.typeText("EARLY")
        app.navigationBars.buttons["Save"].tap()
        assertShows("EARLY")
        // Delete with confirmation
        app.buttons["More actions"].firstMatch.tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.alerts["Delete this note?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Delete"].tap()
        assertShows("A fresh page.")
    }
    func testUnsavedNoteCanBeKeptAsDraft() {
        launch()
        tab("Journal")
        tapButton("Add a lesson note")
        let body = app.textViews.firstMatch
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        body.tap(); body.typeText("Half written")
        app.navigationBars.buttons["Cancel"].tap()
        tapButton("Keep draft and leave")
        tapButton("Add a lesson note")
        assertShows("Your unfinished note was restored.")
        XCTAssertEqual(app.textViews.firstMatch.value as? String, "Half written")
    }

    // MARK: About & accessibility
    func testSettingsShowPrivacyPolicyOffline() {
        launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        assertShows("Practice preferences")
        tapButton("Privacy policy")
        assertShows("In short")
        assertShows("Ralli never saves audio.")
    }
    func testLargestTextSizeKeepsKeyActionsReachable() {
        launch(extra: ["-ralli-accessibility-qa"])
        tab("Practice")
        openDrill("Shadow swings")
        tapButton("Start session")
        tapButton("Pause")
        tapButton("Next step")
        tapButton("Leave session")
        XCTAssertTrue(app.buttons["Save and leave"].waitForExistence(timeout: 5))
    }

    // MARK: Handedness & languages
    func testLeftHandedChoiceIsRememberedInTheMotionPlayer() {
        launch()
        openDrill("Serve with intention")
        let lefty = app.buttons["Left-handed"].firstMatch
        var tries = 0
        while !lefty.exists && tries < 6 { app.swipeUp(velocity: .slow); tries += 1 }
        XCTAssertTrue(lefty.waitForExistence(timeout: 5))
        scrollTo(lefty, awayFromEdge: true)
        lefty.tap()
        XCTAssertTrue(lefty.isSelected, "toggle shows its on state")
        app.terminate(); launch(reset: false)
        tab("Today")
        app.buttons["Change"].firstMatch.exists ? app.buttons["Change"].firstMatch.tap() : app.buttons["Set up"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Left"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Left"].isSelected, "left-handed preference should persist")
    }
    /// Smoke test: in every language, every tab opens and the app keeps running.
    func testEveryLanguageOpensEveryTab() {
        let tabs: [String: [String]] = [
            "en": ["Today", "Practice", "Journal", "Progress"], "tr": ["Bugün", "Çalış", "Defter", "Gelişim"],
            "es": ["Hoy", "Practicar", "Cuaderno", "Progreso"], "de": ["Heute", "Training", "Notizbuch", "Fortschritt"],
            "fr": ["Aujourd’hui", "S’entraîner", "Carnet", "Progrès"], "it": ["Oggi", "Allenati", "Quaderno", "Progressi"]]
        for (language, names) in tabs.sorted(by: { $0.key < $1.key }) {
            app.launchArguments = ["-ralli-ui-testing", "-ralli-reset", "-ralli-skip-intro", "-AppleLanguages", "(\(language))"]
            app.launch()
            for name in names {
                let button = app.tabBars.buttons[name]
                XCTAssertTrue(button.waitForExistence(timeout: 5), "\(language): tab \(name)")
                button.tap()
                XCTAssertTrue(button.isSelected, "\(language): \(name) selected")
            }
            XCTAssertEqual(app.state, .runningForeground, language)
            app.terminate()
        }
    }

    // MARK: Navigation
    func testSwipingFromTheLeftEdgeGoesBack() {
        launch()
        openDrill("Shadow swings")
        swipeBackFromEdge()
        XCTAssertTrue(app.textFields["Search sessions"].waitForExistence(timeout: 5), "back on the library")
    }
    func testSwipeBackIsBlockedWhileASessionRuns() {
        launch()
        openDrill("Shadow swings")
        tapButton("Start session")
        swipeBackFromEdge()
        assertShows("Step 1 of 3")
        XCTAssertFalse(app.textFields["Search sessions"].exists)
    }
    func testHandednessCanBeChangedInSettings() {
        launch()
        app.buttons["Settings"].tap()
        // A menu picker reads as "Which hand do you play with?, Right".
        let picker = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Which hand")).firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        let left = app.buttons["Left"].firstMatch
        XCTAssertTrue(left.waitForExistence(timeout: 5))
        left.tap()
        app.buttons["OK"].firstMatch.tap()
        openDrill("Serve with intention")
        let lefty = app.buttons["Left-handed"].firstMatch
        var tries = 0
        while !lefty.exists && tries < 6 { app.swipeUp(velocity: .slow); tries += 1 }
        XCTAssertTrue(lefty.isSelected, "settings and motion player share the same preference")
    }
    private func swipeBackFromEdge() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)))
    }
}
