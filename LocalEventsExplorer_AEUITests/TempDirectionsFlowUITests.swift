// TEMPORARY verification test — delete after use.
import XCTest

final class TempDirectionsFlowUITests: XCTestCase {
    private let shots = "/private/tmp/claude-501/-Users-a-elnajjar-Documents-GitHub-LocalEventsExplorer-AE/aa1f9713-4a0e-46ae-a801-9b677290e30c/scratchpad"

    private func save(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "\(shots)/\(name).png"))
    }

    @MainActor
    func testDirectionsOpensMapsRoute() throws {
        let app = XCUIApplication()
        app.launch()

        let row = app.staticTexts["Distillery Winter Village"]
        XCTAssertTrue(row.waitForExistence(timeout: 20), "event row missing")
        row.tap()

        let directions = app.buttons["Directions"]
        XCTAssertTrue(directions.waitForExistence(timeout: 10), "Directions button missing")
        save("ui1_detail")
        directions.tap()

        let maps = XCUIApplication(bundleIdentifier: "com.apple.Maps")
        XCTAssertTrue(maps.wait(for: .runningForeground, timeout: 20), "Maps did not open")

        // Dismiss Maps' own location prompt if it appears.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for _ in 0..<3 {
            let allow = springboard.buttons["Allow While Using App"]
            let allowInMaps = maps.buttons["Allow While Using App"]
            if allow.waitForExistence(timeout: 5) { allow.tap() } else if allowInMaps.exists { allowInMaps.tap() } else { break }
        }
        sleep(15)
        save("ui2_maps")
    }
}
