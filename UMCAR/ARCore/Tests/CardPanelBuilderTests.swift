import XCTest
import RealityKit
@testable import ARCore

/// 패널의 크기와 기울기를 검증한다.
///
/// 부스에서 책상 위 카드를 내려다보며 읽어야 하므로, 패널은 카드보다 크고
/// 관람객 쪽으로 서 있어야 한다. 실기기 없이 확인 가능한 건 이 기하뿐이다.
final class CardPanelBuilderTests: XCTestCase {
    /// 실물 카드 크기 (미터)
    private let cardSize = CGSize(width: 0.09, height: 0.127)

    private func makePanel() throws -> ModelEntity {
        let (_, panel, _) = CardPanelBuilder.build(cardID: "coreml", physicalSize: cardSize)
        return panel
    }

    private var halfPanelDepth: Float {
        Float(cardSize.height) * CardPanelBuilder.panelScale / 2
    }

    func test_패널이_카드보다_30퍼센트_크다() throws {
        let panel = try makePanel()
        let extents = try XCTUnwrap(panel.model?.mesh.bounds.extents)

        XCTAssertEqual(extents.x, Float(cardSize.width) * 1.3, accuracy: 1e-4)
        XCTAssertEqual(extents.z, Float(cardSize.height) * 1.3, accuracy: 1e-4)
    }

    func test_히트_판은_실물_카드_크기_그대로다() throws {
        // 히트 판까지 키우면 카드 밖 허공을 탭해도 패널이 열린다.
        let (hit, _, _) = CardPanelBuilder.build(cardID: "coreml", physicalSize: cardSize)
        let extents = try XCTUnwrap(hit.model?.mesh.bounds.extents)

        XCTAssertEqual(extents.x, Float(cardSize.width), accuracy: 1e-4)
        XCTAssertEqual(extents.z, Float(cardSize.height), accuracy: 1e-4)
    }

    func test_세운_패널의_아래_모서리가_카드_평면을_뚫지_않는다() throws {
        let panel = try makePanel()

        // 관람객 쪽(+Z) 모서리를 앵커 공간으로 옮긴다
        let nearEdge = panel.transform.matrix * SIMD4<Float>(0, 0, halfPanelDepth, 1)

        XCTAssertEqual(nearEdge.y, CardPanelBuilder.panelClearance, accuracy: 1e-4)
        XCTAssertGreaterThan(nearEdge.y, 0, "카드 평면 아래로 내려가면 책상에 잘려 보인다")
    }

    func test_먼_쪽_모서리가_들려_독서대처럼_선다() throws {
        let panel = try makePanel()

        let nearEdge = panel.transform.matrix * SIMD4<Float>(0, 0, halfPanelDepth, 1)
        let farEdge = panel.transform.matrix * SIMD4<Float>(0, 0, -halfPanelDepth, 1)

        XCTAssertGreaterThan(farEdge.y, nearEdge.y, "인쇄물 위쪽(-Z)이 들려야 한다")
    }

    func test_패널_앞면이_관람객_쪽으로_눕는다() throws {
        let panel = try makePanel()

        // generatePlane의 앞면 법선은 +Y다. 기울이면 관람객이 선 +Z로 눕는다.
        let normal = panel.orientation.act(SIMD3<Float>(0, 1, 0))

        XCTAssertGreaterThan(normal.z, 0, "법선이 관람객 반대쪽을 보면 뒷면만 보인다")
        XCTAssertGreaterThan(normal.y, 0, "완전히 눕지 않고 여전히 위를 향한다")
        XCTAssertEqual(normal.y, normal.z, accuracy: 1e-4, "45도면 두 성분이 같다")
    }

    func test_패널은_탭_전까지_꺼져_있다() throws {
        let panel = try makePanel()
        XCTAssertFalse(panel.isEnabled)
    }
}
