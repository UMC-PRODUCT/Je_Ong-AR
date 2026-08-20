import XCTest
@testable import ARCore

final class TechCardTests: XCTestCase {
    /// 레퍼런스 이미지 이름과 1:1로 맞아야 한다.
    /// 어긋나면 인식은 되는데 카드 조회가 실패해 패널이 안 뜬다.
    private let expectedIDs = [
        "corelocation", "apple-intelligence", "cloudkit", "coreml",
        "foundation-models", "liquid-glass", "sirikit",
        "nearby-interaction", "widgetkit",
    ]

    func test_카드는_9장이다() {
        XCTAssertEqual(TechCard.all.count, 9)
    }

    func test_id가_레퍼런스_이미지_이름과_일치한다() {
        XCTAssertEqual(Set(TechCard.all.map(\.id)), Set(expectedIDs))
    }

    func test_id에_중복이_없다() {
        XCTAssertEqual(Set(TechCard.all.map(\.id)).count, TechCard.all.count)
    }

    func test_모든_카드에_내용이_채워져_있다() {
        for card in TechCard.all {
            XCTAssertFalse(card.name.isEmpty, "\(card.id): name 비어 있음")
            XCTAssertFalse(card.tag.isEmpty, "\(card.id): tag 비어 있음")
            XCTAssertFalse(card.summary.isEmpty, "\(card.id): summary 비어 있음")
            XCTAssertFalse(card.detail.isEmpty, "\(card.id): detail 비어 있음")
        }
    }

    func test_id로_카드를_찾는다() {
        XCTAssertEqual(TechCard.card(id: "coreml")?.name, "CoreML")
        XCTAssertNil(TechCard.card(id: "없는카드"))
    }
}
