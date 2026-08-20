import XCTest
@testable import ARCore

final class CardSelectionTests: XCTestCase {
    func test_초기에는_선택된_카드가_없다() {
        let selection = CardSelection()
        XCTAssertNil(selection.selected)
    }

    func test_카드를_탭하면_열린다() {
        var selection = CardSelection()
        let change = selection.tap("coreml")
        XCTAssertEqual(selection.selected, "coreml")
        XCTAssertEqual(change, .opened("coreml"))
    }

    func test_같은_카드를_다시_탭하면_닫힌다() {
        var selection = CardSelection()
        _ = selection.tap("coreml")
        let change = selection.tap("coreml")
        XCTAssertNil(selection.selected)
        XCTAssertEqual(change, .closed("coreml"))
    }

    func test_다른_카드를_탭하면_교체된다() {
        var selection = CardSelection()
        _ = selection.tap("coreml")
        let change = selection.tap("sirikit")
        XCTAssertEqual(selection.selected, "sirikit")
        XCTAssertEqual(change, .replaced(from: "coreml", to: "sirikit"))
    }

    func test_빈_곳을_탭하면_열린_카드가_닫힌다() {
        var selection = CardSelection()
        _ = selection.tap("coreml")
        let change = selection.tap(nil)
        XCTAssertNil(selection.selected)
        XCTAssertEqual(change, .closed("coreml"))
    }

    func test_아무것도_안_열린_상태에서_빈_곳_탭은_아무_일도_없다() {
        var selection = CardSelection()
        let change = selection.tap(nil)
        XCTAssertNil(selection.selected)
        XCTAssertEqual(change, .unchanged)
    }
}
