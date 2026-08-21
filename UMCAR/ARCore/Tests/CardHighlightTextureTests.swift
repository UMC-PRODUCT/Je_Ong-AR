import XCTest
@testable import ARCore

/// 무지개 테두리 텍스처가 만들어지는지, 번짐 곡선이 의도대로 생겼는지 확인한다.
///
/// CoreGraphics 렌더링과 TextureResource 생성이 둘 다 도는지 보는 것이라
/// 시뮬레이터에서 검증된다. 실패하면 인식된 카드에 테두리가 안 뜬다.
final class CardHighlightTextureTests: XCTestCase {
    func test_색과_번짐_텍스처가_만들어진다() throws {
        let pair = try XCTUnwrap(CardHighlightTexture.make())
        XCTAssertEqual(pair.color.width, CardHighlightTexture.stripWidth)
        XCTAssertEqual(pair.color.height, CardHighlightTexture.stripHeight)
        XCTAssertEqual(pair.glow.width, CardHighlightTexture.stripWidth)
        XCTAssertEqual(pair.glow.height, CardHighlightTexture.stripHeight)
    }

    func test_두_번째_호출은_캐시를_쓴다() throws {
        // 9장이 공유하는 텍스처다. 카드마다 구우면 낭비다.
        let first = try XCTUnwrap(CardHighlightTexture.make())
        let second = try XCTUnwrap(CardHighlightTexture.make())
        XCTAssertTrue(first.color === second.color)
        XCTAssertTrue(first.glow === second.glow)
    }

    func test_번짐은_띠_가운데가_가장_밝다() {
        let center = CardHighlightTexture.glowProfile(at: 0.5)
        XCTAssertEqual(center, 1.0, accuracy: 0.001)
        XCTAssertGreaterThan(center, CardHighlightTexture.glowProfile(at: 0.35))
        XCTAssertGreaterThan(CardHighlightTexture.glowProfile(at: 0.35),
                             CardHighlightTexture.glowProfile(at: 0.2))
    }

    func test_번짐은_띠_끝에서_완전히_사라진다() {
        // 0이 아니면 메시 경계가 실선으로 드러난다 — 번짐이 아니라 테두리가 된다.
        XCTAssertEqual(CardHighlightTexture.glowProfile(at: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(CardHighlightTexture.glowProfile(at: 1), 0, accuracy: 0.0001)
    }

    func test_번짐은_안팎이_대칭이다() {
        for v in stride(from: Float(0), through: 0.5, by: 0.05) {
            XCTAssertEqual(CardHighlightTexture.glowProfile(at: v),
                           CardHighlightTexture.glowProfile(at: 1 - v),
                           accuracy: 0.0001)
        }
    }
}

/// 색이 흐르는 상태값을 확인한다.
final class CardHighlightMaterialTests: XCTestCase {
    func test_한_주기에_UV를_정확히_한_바퀴_민다() {
        let period = CardHighlightMaterial.sweepPeriod
        XCTAssertEqual(CardHighlightMaterial.sweep(at: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(CardHighlightMaterial.sweep(at: period / 2), 0.5, accuracy: 0.0001)
        // 한 바퀴 돌면 처음 자리로 돌아온다. 안 그러면 이음매에서 색이 튄다.
        XCTAssertEqual(CardHighlightMaterial.sweep(at: period),
                       CardHighlightMaterial.sweep(at: 0), accuracy: 0.0001)
        XCTAssertEqual(CardHighlightMaterial.sweep(at: period * 3.25),
                       CardHighlightMaterial.sweep(at: period * 0.25), accuracy: 0.0001)
    }

    func test_숨쉬기는_정해진_범위를_안_벗어난다() {
        for tick in stride(from: Double(0), through: 12, by: 0.05) {
            let value = CardHighlightMaterial.breath(at: tick)
            XCTAssertGreaterThanOrEqual(value, CardHighlightMaterial.breathFloor - 0.0001)
            XCTAssertLessThanOrEqual(value, 1.0001)
        }
    }

    func test_숨쉬기는_가장_밝은_상태로_시작한다() {
        // 카드를 인식한 순간 테두리가 흐릿하게 뜨면 인식이 덜 된 걸로 읽힌다.
        XCTAssertEqual(CardHighlightMaterial.breath(at: 0), 1.0, accuracy: 0.0001)
    }
}
