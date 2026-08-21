import XCTest
import simd
@testable import ARCore

/// 무지개 테두리 띠 메시의 기하를 확인한다.
///
/// 눈으로만 잡히는 버그가 여기 몰려 있다. 감기 방향이 뒤집히면 테두리가 통째로
/// 안 보이고, UV가 되감기면 이음매 한 칸에 무지개가 압축된다. 둘 다 "안 보인다"
/// 또는 "이상하다"로만 보고돼서 원인을 못 찾는다.
final class CardHighlightRingTests: XCTestCase {
    /// 실물 카드 크기 (미터). 90 x 127mm
    private let cardWidth: Float = 0.09
    private let cardDepth: Float = 0.127

    private func makeGeometry() -> CardHighlightRing.Geometry {
        CardHighlightRing.geometry(cardWidth: cardWidth, cardDepth: cardDepth)
    }

    func test_정점과_UV_개수가_맞는다() {
        let geometry = makeGeometry()
        XCTAssertFalse(geometry.positions.isEmpty)
        XCTAssertEqual(geometry.positions.count, geometry.textureCoordinates.count)
        XCTAssertEqual(geometry.positions.count, geometry.normals.count)
        // 정점 쌍(바깥·안쪽)마다 사각형 하나, 사각형마다 삼각형 둘
        let quads = geometry.positions.count / 2 - 1
        XCTAssertEqual(geometry.triangleIndices.count, quads * 6)
    }

    func test_모든_삼각형이_위를_본다() {
        // 법선이 -Y로 뒤집힌 삼각형은 카드를 위에서 보는 관람객에게 뒷면이다.
        let geometry = makeGeometry()
        let indices = geometry.triangleIndices

        for i in stride(from: 0, to: indices.count, by: 3) {
            let p0 = geometry.positions[Int(indices[i])]
            let p1 = geometry.positions[Int(indices[i + 1])]
            let p2 = geometry.positions[Int(indices[i + 2])]
            let facing = cross(p1 - p0, p2 - p0).y
            XCTAssertGreaterThan(facing, 0, "삼각형 \(i / 3)이 아래를 본다")
        }
    }

    func test_UV의_u는_0에서_1까지_한_번만_올라간다() {
        // 되감기면 그 한 칸에 무지개 전체가 거꾸로 압축돼 흰 줄처럼 보인다.
        let geometry = makeGeometry()
        let us = stride(from: 0, to: geometry.textureCoordinates.count, by: 2)
            .map { geometry.textureCoordinates[$0].x }

        XCTAssertEqual(us.first, 0)
        XCTAssertEqual(us.last, 1)
        for (previous, next) in zip(us, us.dropFirst()) {
            XCTAssertGreaterThan(next, previous, "u가 \(previous)에서 \(next)로 뒷걸음쳤다")
        }
    }

    func test_UV의_v는_바깥이_0_안쪽이_1이다() {
        let geometry = makeGeometry()
        for i in stride(from: 0, to: geometry.textureCoordinates.count, by: 2) {
            XCTAssertEqual(geometry.textureCoordinates[i].y, 0)
            XCTAssertEqual(geometry.textureCoordinates[i + 1].y, 1)
        }
    }

    func test_u는_테두리를_따라_잰_거리에_비례한다() {
        // 거리 비례가 깨지면 짧은 변에서 색이 뭉치고 긴 변에서 늘어진다.
        // 중심선(바깥·안쪽 정점의 중점) 기준으로 "거리당 u"가 어디서나 같아야 한다.
        let geometry = makeGeometry()
        var rates: [Float] = []

        for i in stride(from: 0, to: geometry.positions.count - 2, by: 2) {
            let here = (geometry.positions[i] + geometry.positions[i + 1]) / 2
            let next = (geometry.positions[i + 2] + geometry.positions[i + 3]) / 2
            let step = distance(here, next)
            guard step > 1e-6 else { continue }
            let deltaU = geometry.textureCoordinates[i + 2].x - geometry.textureCoordinates[i].x
            rates.append(deltaU / step)
        }

        let first = try! XCTUnwrap(rates.first)
        for rate in rates {
            XCTAssertEqual(rate, first, accuracy: first * 0.001)
        }
    }

    func test_띠가_카드_가장자리를_감싼다() {
        // 전부 카드 밖이면 인쇄된 가장자리와 떨어져 액자처럼 보이고,
        // 전부 카드 안이면 카드 그림을 덮는다. 걸쳐 있어야 카드가 빛나 보인다.
        let geometry = makeGeometry()
        let outerReach = stride(from: 0, to: geometry.positions.count, by: 2)
            .map { abs(geometry.positions[$0].x) }.max() ?? 0
        let innerReach = stride(from: 1, to: geometry.positions.count, by: 2)
            .map { abs(geometry.positions[$0].x) }.max() ?? 0

        XCTAssertGreaterThan(outerReach, cardWidth / 2, "띠가 카드 밖으로 안 나간다")
        XCTAssertLessThan(innerReach, cardWidth / 2, "띠가 카드 안으로 안 들어온다")
        XCTAssertEqual(outerReach - innerReach,
                       cardWidth * CardHighlightRing.bandWidth,
                       accuracy: 1e-5)
    }

    func test_밝은_선이_카드_가장자리에_얹힌다() {
        // 여백·두께·선 위치 셋이 어긋나면 선이 카드 그림을 덮거나 액자처럼 뜬다.
        let geometry = makeGeometry()
        let outerReach = stride(from: 0, to: geometry.positions.count, by: 2)
            .map { abs(geometry.positions[$0].x) }.max() ?? 0
        let band = cardWidth * CardHighlightRing.bandWidth
        let lineReach = outerReach - band * CardHighlightTexture.linePosition

        XCTAssertEqual(lineReach, cardWidth / 2, accuracy: cardWidth * 0.05)
    }

    func test_모서리_반지름이_띠_두께에_눌리지_않는다() {
        // 중심선 반지름이 띠 두께의 절반보다 작으면 안쪽 윤곽이 뒤집혀 모서리가
        // 꼬인다. 카드가 아주 작아도(5cm) 성립해야 한다.
        for width in [Float(0.05), 0.09, 0.2] {
            let depth = width * 1.4
            let geometry = CardHighlightRing.geometry(cardWidth: width, cardDepth: depth)
            let indices = geometry.triangleIndices

            // 뒤집힌 모서리는 감기 방향이 뒤집힌 삼각형으로 드러난다.
            for i in stride(from: 0, to: indices.count, by: 3) {
                let p0 = geometry.positions[Int(indices[i])]
                let p1 = geometry.positions[Int(indices[i + 1])]
                let p2 = geometry.positions[Int(indices[i + 2])]
                XCTAssertGreaterThan(cross(p1 - p0, p2 - p0).y, 0,
                                     "카드 폭 \(width)에서 모서리가 꼬였다")
            }
        }
    }
}
