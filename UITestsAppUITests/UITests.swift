import XCTest

class UITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAddition() {
        let app = XCUIApplication()

        let delayView = app.otherElements["Delay view"]
        self.waitForElementToAppear(delayView)

        app.navigationBars["UITestsApp.Collection"].buttons["Add"].tap()

        let addedCell = app.collectionViews.cells.staticTexts["0"]
        self.waitForElementToAppear(addedCell)
    }
}

extension XCTestCase {
    func waitForElementToAppear(element: XCUIElement, timeout: NSTimeInterval = 5,  file: String = #file, line: UInt = #line) {
        let existsPredicate = NSPredicate(format: "exists == true")
        expectationForPredicate(existsPredicate, evaluatedWithObject: element, handler: nil)
        waitForExpectationsWithTimeout(timeout) { error in
            if error != nil {
                let message = "Failed to find \(element) after \(timeout) seconds."
                self.recordFailureWithDescription(message, inFile: file, atLine: line, expected: true)
            }
        }
    }
}