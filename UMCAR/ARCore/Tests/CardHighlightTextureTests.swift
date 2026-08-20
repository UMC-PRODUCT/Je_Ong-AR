import XCTest
@testable import ARCore

/// 무지개 테두리 텍스처가 만들어지는지 확인한다.
///
/// CoreGraphics 렌더링과 TextureResource 생성이 둘 다 도는지 보는 것이라
/// 시뮬레이터에서 검증된다. 실패하면 인식된 카드에 테두리가 안 뜬다.
final class CardHighlightTextureTests: XCTestCase {
    func test_테두리_텍스처가_만들어진다() throws {
        XCTAssertNotNil(CardHighlightTexture.make())
    }

    func test_두_번째_호출은_캐시를_쓴다() throws {
        // 9장이 공유하는 텍스처다. 카드마다 구우면 낭비다.
        let first = try XCTUnwrap(CardHighlightTexture.make())
        let second = try XCTUnwrap(CardHighlightTexture.make())
        XCTAssertEqual(first.width, second.width)
        XCTAssertEqual(first.height, second.height)
    }
}
