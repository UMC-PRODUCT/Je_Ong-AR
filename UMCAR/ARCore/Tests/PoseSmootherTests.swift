import XCTest
import simd
@testable import ARCore

/// 떨림 필터가 잡음은 막고 진짜 이동은 통과시키는지 확인한다.
///
/// 실기기 없이 검증 가능한 유일한 지점이다 — ARKit이 주는 자세를 흉내 낸
/// 행렬을 넣어보면 된다.
final class PoseSmootherTests: XCTestCase {
    private func pose(x: Float = 0, y: Float = 0, z: Float = 0,
                      yaw: Float = 0) -> simd_float4x4 {
        var m = simd_float4x4(simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0)))
        m.columns.3 = SIMD4<Float>(x, y, z, 1)
        return m
    }

    private func position(_ m: simd_float4x4) -> SIMD3<Float> {
        SIMD3<Float>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
    }

    func test_아주_작은_흔들림은_무시한다() {
        var smoother = PoseSmoother(pose: pose())

        // 1mm 흔들림 — 죽은 구역(5mm) 안이다
        let changed = smoother.update(observed: pose(x: 0.001))

        XCTAssertFalse(changed, "떨림인데 따라가면 화면이 떤다")
        XCTAssertEqual(position(smoother.pose).x, 0, accuracy: 1e-6)
    }

    func test_작은_회전_흔들림은_무시한다() {
        var smoother = PoseSmoother(pose: pose())

        // 1도 — 죽은 구역(약 2도) 안이다
        let changed = smoother.update(observed: pose(yaw: .pi / 180))

        XCTAssertFalse(changed)
    }

    func test_실제로_옮기면_따라간다() {
        var smoother = PoseSmoother(pose: pose())

        // 10cm 이동 — 명백한 이동이다
        XCTAssertTrue(smoother.update(observed: pose(x: 0.10)))
        XCTAssertGreaterThan(position(smoother.pose).x, 0, "안 따라가면 카드를 옮겨도 제자리다")
    }

    func test_따라가되_한_번에_튀지_않는다() {
        var smoother = PoseSmoother(pose: pose())
        smoother.update(observed: pose(x: 0.10))

        // followRate 만큼만 간다. 즉시 도착하면 부드럽게 보이지 않는다.
        XCTAssertEqual(position(smoother.pose).x, 0.10 * PoseSmoother.followRate, accuracy: 1e-5)
    }

    func test_계속_관측하면_결국_도착한다() {
        var smoother = PoseSmoother(pose: pose())
        let target = pose(x: 0.10)

        // 60fps에서 1초. 굼떠서 못 따라가면 카드를 옮겨도 계속 뒤처진다.
        for _ in 0..<60 { smoother.update(observed: target) }

        XCTAssertEqual(position(smoother.pose).x, 0.10, accuracy: 0.005)
    }

    func test_떨림이_쌓여_흘러가지_않는다() {
        var smoother = PoseSmoother(pose: pose())

        // 죽은 구역 안의 잡음을 한쪽으로만 계속 준다. 누적되면 카드가 스르르 밀린다.
        for _ in 0..<300 { smoother.update(observed: pose(x: 0.001)) }

        XCTAssertEqual(position(smoother.pose).x, 0, accuracy: 1e-6)
    }

    func test_같은_회전을_다른_부호로_줘도_각도는_0이다() {
        // q와 -q는 같은 회전이다. 부호를 안 지우면 180도 차이로 읽혀 매 프레임 튄다.
        let q = simd_quatf(angle: 0.7, axis: SIMD3<Float>(0, 1, 0))
        let flipped = simd_quatf(vector: -q.vector)

        XCTAssertEqual(PoseSmoother.angle(between: q, and: flipped), 0, accuracy: 1e-3)
    }
}
