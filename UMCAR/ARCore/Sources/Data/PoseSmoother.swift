//
//  PoseSmoother.swift
//  ARCore
//

import simd

/// ARKit 앵커 자세의 떨림을 걸러낸다.
///
/// **왜 필요한가.** 이미지 추적을 켜면 ARKit이 매 프레임 카드 자세를 새로
/// 추정하는데, 그 추정이 밀리미터·1도 단위로 흔들린다. 앵커에 바로 붙이면
/// 그 잡음이 그대로 화면에 나온다.
///
/// 패널이 이를 증폭한다. 45도로 세운 A4 패널의 윗변은 앵커에서 약 18cm 떨어져
/// 있어서, 회전 오차 1도가 윗변에서는 3mm 움직임이 된다. 패널을 키울수록
/// 지렛대가 길어져 더 심해진다.
///
/// **어떻게 거르나.** 카드는 책상에 고정이라 대부분의 변화는 잡음이다. 죽은
/// 구역보다 작게 움직이면 무시하고, 실제로 옮겨졌으면 부드럽게 따라간다.
/// 무시만 하면 진짜로 옮겼을 때 안 따라가고, 따라가기만 하면 계속 떤다.
public struct PoseSmoother {
    /// 이 이하로 움직이면 떨림으로 본다 (미터).
    ///
    /// 카드가 9cm이므로 5mm면 눈에 띄는 이동의 하한이다. 더 키우면 살짝 민
    /// 카드를 안 따라가고, 줄이면 잡음이 새어 들어온다.
    public static let positionDeadZone: Float = 0.005

    /// 이 이하로 돌면 떨림으로 본다 (라디안, 약 2도).
    ///
    /// 위 계산에서 2도는 패널 윗변 6mm에 해당한다. 이걸 넘겨야 "돌렸다"로 친다.
    public static let rotationDeadZone: Float = 0.035

    /// 죽은 구역을 넘었을 때 한 프레임에 따라가는 비율.
    ///
    /// 1이면 즉시 튀고, 낮을수록 부드럽지만 굼뜨다. 0.2면 60fps에서 대략
    /// 0.2초 안에 따라붙는다.
    public static let followRate: Float = 0.2

    /// 지금 화면에 쓰는 안정된 자세
    public private(set) var pose: simd_float4x4

    public init(pose: simd_float4x4) {
        self.pose = pose
    }

    /// 새 관측을 반영한다.
    ///
    /// - Returns: 자세가 바뀌었으면 true. false면 호출부는 엔티티를 건드리지 않는다.
    @discardableResult
    public mutating func update(observed: simd_float4x4) -> Bool {
        let currentPosition = SIMD3<Float>(pose.columns.3.x, pose.columns.3.y, pose.columns.3.z)
        let observedPosition = SIMD3<Float>(observed.columns.3.x,
                                            observed.columns.3.y,
                                            observed.columns.3.z)
        let currentRotation = simd_quatf(rotationPart(of: pose))
        let observedRotation = simd_quatf(rotationPart(of: observed))

        let moved = simd_distance(currentPosition, observedPosition)
        let turned = Self.angle(between: currentRotation, and: observedRotation)

        guard moved > Self.positionDeadZone || turned > Self.rotationDeadZone else {
            return false
        }

        let blended = simd_mix(currentPosition, observedPosition,
                               SIMD3<Float>(repeating: Self.followRate))
        let rotated = simd_slerp(currentRotation, observedRotation, Self.followRate)

        var next = simd_float4x4(rotated)
        next.columns.3 = SIMD4<Float>(blended, 1)
        pose = next
        return true
    }

    /// 두 회전 사이의 각도 (라디안).
    ///
    /// q와 -q는 같은 회전이라 내적의 절댓값을 쓴다. 부호를 안 지우면 같은
    /// 자세인데도 180도 차이가 난 것으로 읽힌다.
    static func angle(between lhs: simd_quatf, and rhs: simd_quatf) -> Float {
        let dot = abs(simd_dot(lhs.vector, rhs.vector))
        return 2 * acos(min(1, max(-1, dot)))
    }

    /// 이동 성분을 뺀 회전 행렬. simd_quatf는 3x3만 받는다.
    private func rotationPart(of matrix: simd_float4x4) -> simd_float3x3 {
        simd_float3x3(
            SIMD3<Float>(matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z),
            SIMD3<Float>(matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z),
            SIMD3<Float>(matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z)
        )
    }
}
