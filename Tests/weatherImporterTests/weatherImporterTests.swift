import XCTest
@testable import weatherImporter

final class weatherImporterTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(weatherImporter().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
