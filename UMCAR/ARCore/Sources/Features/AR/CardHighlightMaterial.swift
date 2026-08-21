//
//  CardHighlightMaterial.swift
//  ARCore
//

import Foundation
import Metal
import RealityKit

/// 무지개 테두리의 머티리얼. 시간이 들어가면 색이 흐르는 상태가 나온다.
///
/// **움직임이 왜 필요한가.** 애플 인텔리전스의 인상은 색 자체보다 "빛이 테두리를
/// 따라 계속 돈다"에서 온다. 가만히 있는 무지개는 그냥 스티커로 보인다.
///
/// **어떻게 싸게 움직이나.** 텍스처를 다시 굽지 않는다. 띠 메시의 u가 테두리
/// 한 바퀴라서, UV를 x축으로 밀면 색이 그대로 테두리를 따라 흐른다. 프레임마다
/// 하는 일은 float 두 개를 바꾸는 것뿐이다.
enum CardHighlightMaterial {
    /// 색이 테두리를 한 바퀴 도는 데 걸리는 시간 (초).
    /// 빠르면 경고등처럼 보이고, 느리면 멈춰 있는 걸로 읽힌다.
    static let sweepPeriod: TimeInterval = 5.0

    /// 밝기가 한 번 오르내리는 데 걸리는 시간 (초).
    /// 회전 주기와 서로 나누어떨어지지 않아야 같은 그림이 반복되지 않는다.
    static let breathPeriod: TimeInterval = 2.9

    /// 숨쉬기의 가장 어두운 지점. 1이면 숨을 안 쉰다.
    static let breathFloor: Float = 0.72

    /// 경과 시간에 맞춘 머티리얼을 만든다.
    static func make(textures: CardHighlightTexture.Pair, elapsed: TimeInterval) -> UnlitMaterial {
        var material = UnlitMaterial()

        var color = MaterialParameters.Texture(textures.color)
        color.sampler = flowSampler
        material.color = .init(tint: .white, texture: color)

        var glow = MaterialParameters.Texture(textures.glow)
        glow.sampler = flowSampler
        material.blending = .transparent(opacity: .init(scale: breath(at: elapsed), texture: glow))

        // u만 민다. v를 건드리면 띠를 가로지르는 번짐이 어긋나 한쪽이 잘린다.
        material.textureCoordinateTransform = .init(offset: [sweep(at: elapsed), 0])

        // 카드를 비스듬히 아래에서 보는 관람객에게도 보여야 한다. 삼각형 200개라
        // 뒷면까지 그려도 부담이 없다.
        material.faceCulling = .none

        return material
    }

    /// 지금 UV를 얼마나 밀어야 하는지. 0~1을 반복한다.
    static func sweep(at elapsed: TimeInterval) -> Float {
        let phase = elapsed.truncatingRemainder(dividingBy: sweepPeriod) / sweepPeriod
        return Float(phase)
    }

    /// 지금 불투명도 배수. breathFloor와 1 사이를 오간다.
    static func breath(at elapsed: TimeInterval) -> Float {
        let phase = elapsed.truncatingRemainder(dividingBy: breathPeriod) / breathPeriod
        // cos는 -1~1이라 0~1로 접어 올린다. 0초에서 가장 밝게 시작한다.
        let wave = Float((cos(phase * 2 * .pi) + 1) / 2)
        return breathFloor + (1 - breathFloor) * wave
    }

    /// u는 반복, v는 끝값 유지.
    ///
    /// u를 반복으로 두지 않으면 UV를 민 만큼 텍스처 밖으로 나가 마지막 색이
    /// 테두리 절반에 늘어붙는다. v는 반복하면 안쪽 끝과 바깥쪽 끝이 이어져
    /// 번짐이 접힌다.
    private static let flowSampler: MaterialParameters.Texture.Sampler = {
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .clampToEdge
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.mipFilter = .linear
        return .init(descriptor)
    }()
}
