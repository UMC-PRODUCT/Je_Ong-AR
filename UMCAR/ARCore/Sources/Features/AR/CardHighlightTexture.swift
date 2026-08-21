//
//  CardHighlightTexture.swift
//  ARCore
//

import CoreGraphics
import RealityKit
import os.log

/// 인식된 카드를 감싸는 무지개 테두리에 쓰는 텍스처 두 장.
///
/// 관람객에게 "이 카드는 누를 수 있다"를 알리는 어포던스다. 화면 하단 안내 문구가
/// 방법을 말한다면, 이 테두리는 **어느 것을** 누르면 되는지를 가리킨다.
///
/// **띠를 따라 흐르는 가로 스트립이다.** 예전에는 카드 모양 그대로(512x723)
/// 테두리를 구워서, 색을 움직이려면 프레임마다 다시 구워야 했다. 지금은 메시가
/// 테두리 모양을 갖고(CardHighlightRing) 텍스처는 "띠를 폈을 때의 한 줄"만
/// 담는다 — u는 테두리를 한 바퀴, v는 띠를 가로지른다. 그래서 색을 흘려보내는
/// 일이 `textureCoordinateTransform.offset.x`를 더하는 것으로 끝난다.
///
/// **두 장으로 나눈 이유.** 한 장에 색과 알파를 같이 담으면 CoreGraphics가
/// 알파를 곱해 저장(premultiplied)하고, RealityKit이 불투명도를 또 곱해서
/// 번짐이 alpha² 로 죽는다. 색은 불투명하게, 번짐은 따로 굽는다.
///
/// 텍스처는 9장이 공유한다 — 카드마다 구울 이유가 없고, 세션당 한 번만 만든다.
enum CardHighlightTexture {
    /// 색(color)과 번짐(glow) 텍스처 한 쌍
    struct Pair {
        let color: TextureResource
        let glow: TextureResource
    }

    /// 테두리 한 바퀴를 몇 픽셀로 나눌지. 색이 흐르는 방향이라 여유를 준다.
    static let stripWidth = 1024

    /// 띠를 가로지르는 해상도. 번짐은 저주파라 이 정도면 충분하다.
    static let stripHeight = 64

    private static let logger = Logger.of("CardHighlightTexture")

    private static var cached: Pair?

    /// 색·번짐 텍스처를 만든다. 실패하면 nil — 테두리 없이도 앱은 동작한다.
    static func make() -> Pair? {
        if let cached { return cached }

        guard let colorImage = renderColorStrip(),
              let glowImage = renderGlowStrip() else {
            logger.error("테두리 스트립을 CGImage로 못 만들었다")
            return nil
        }

        do {
            let color = try TextureResource(image: colorImage, options: .init(semantic: .color))
            // .raw 로 굽는다. .color 로 두면 sRGB 로 해석돼 번짐 곡선이 감마만큼
            // 휘어 가장자리가 뚝 끊긴다 — 불투명도는 색이 아니라 숫자다.
            let glow = try TextureResource(image: glowImage, options: .init(semantic: .raw))
            let pair = Pair(color: color, glow: glow)
            cached = pair
            return pair
        } catch {
            logger.error("테두리 텍스처 생성 실패: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 팔레트

    /// 테두리를 한 바퀴 도는 색. 마지막이 처음과 같아야 이음매가 안 보인다.
    ///
    /// 무지개지만 순수 HSV 는 아니다. 애플 인텔리전스 쪽 색은 형광 초록·노랑이
    /// 거의 없고 분홍-보라-파랑-청록이 넓게 깔린다. 초록 구간은 좁게 지나가고
    /// 채도를 낮춰서, 무지개로 읽히되 색종이처럼 보이지 않게 했다.
    private static let stops: [(t: Float, rgb: SIMD3<Float>)] = [
        (0.00, .init(1.00, 0.23, 0.50)),   // 핑크
        (0.08, .init(1.00, 0.42, 0.29)),   // 코랄
        (0.17, .init(1.00, 0.66, 0.24)),   // 앰버
        (0.25, .init(0.96, 0.82, 0.29)),   // 골드
        (0.34, .init(0.49, 0.88, 0.54)),   // 민트 (좁게 지나간다)
        (0.44, .init(0.18, 0.83, 0.78)),   // 청록
        (0.55, .init(0.21, 0.66, 1.00)),   // 파랑
        (0.66, .init(0.36, 0.42, 1.00)),   // 인디고
        (0.77, .init(0.61, 0.36, 1.00)),   // 보라
        (0.88, .init(0.85, 0.30, 0.94)),   // 마젠타
        (1.00, .init(1.00, 0.23, 0.50)),   // 핑크로 되돌아온다
    ]

    private static func paletteColor(at t: Float) -> SIMD3<Float> {
        let x = t - floor(t)
        for i in 1..<stops.count where x <= stops[i].t {
            let lo = stops[i - 1], hi = stops[i]
            let span = hi.t - lo.t
            let k = span > 0 ? (x - lo.t) / span : 0
            return lo.rgb + (hi.rgb - lo.rgb) * k
        }
        return stops[stops.count - 1].rgb
    }

    // MARK: - 번짐 곡선

    /// 심지의 폭. 좁을수록 가운데 흰 선이 가늘고 또렷하다.
    private static let coreWidth: Float = 0.16

    /// 후광의 폭. 이게 애플 인텔리전스 특유의 "빛이 새어나오는" 느낌을 만든다.
    private static let haloWidth: Float = 0.55

    /// 후광이 심지 대비 얼마나 밝은지
    private static let haloWeight: Float = 0.42

    /// 띠를 가로지르는 위치(v)에서의 불투명도.
    ///
    /// 가운데가 가장 밝고 양쪽으로 사라진다. 마지막 `edgeFade`가 없으면 띠
    /// 가장자리에 옅은 값이 남아 메시 경계가 실선으로 드러난다.
    static func glowProfile(at v: Float) -> Float {
        let d = abs(v * 2 - 1)                      // 0 = 띠 한가운데, 1 = 띠 끝
        let core = exp(-pow(d / coreWidth, 2))
        let halo = exp(-pow(d / haloWidth, 2))
        let edgeFade = max(0, 1 - pow(d, 3))
        return min(1, core + halo * haloWeight) * edgeFade
    }

    /// 심지 쪽이 흰빛으로 뜨는 정도. 실제 발광체는 중심이 색을 잃고 하얘진다.
    private static func coreWhiteness(at v: Float) -> Float {
        let d = abs(v * 2 - 1)
        return exp(-pow(d / coreWidth, 2)) * 0.5
    }

    // MARK: - 렌더

    private static func renderColorStrip() -> CGImage? {
        makeImage { x, y in
            // width 로 나눈다 (width-1 이 아니라). 그래야 마지막 픽셀 다음이
            // 첫 픽셀과 이어져, 반복 샘플링해도 이음매가 안 생긴다.
            let u = Float(x) / Float(stripWidth)
            let v = (Float(y) + 0.5) / Float(stripHeight)
            let white = coreWhiteness(at: v)
            let rgb = paletteColor(at: u) * (1 - white) + SIMD3<Float>(repeating: white)
            return (rgb, 1)
        }
    }

    private static func renderGlowStrip() -> CGImage? {
        makeImage { _, y in
            let v = (Float(y) + 0.5) / Float(stripHeight)
            let a = glowProfile(at: v)
            // 흰색 x 알파. premultiplied 로 저장하면 RGB 도 알파와 같은 값이 돼서,
            // RealityKit 이 어느 채널을 읽든 같은 숫자가 나온다.
            return (SIMD3<Float>(repeating: 1), a)
        }
    }

    private static func makeImage(
        _ fill: (Int, Int) -> (rgb: SIMD3<Float>, alpha: Float)
    ) -> CGImage? {
        let width = stripWidth, height = stripHeight
        var bytes = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let (rgb, alpha) = fill(x, y)
                let i = (y * width + x) * 4
                bytes[i] = byte(rgb.x * alpha)
                bytes[i + 1] = byte(rgb.y * alpha)
                bytes[i + 2] = byte(rgb.z * alpha)
                bytes[i + 3] = byte(alpha)
            }
        }

        return bytes.withUnsafeMutableBytes { raw in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }
            return context.makeImage()
        }
    }

    private static func byte(_ value: Float) -> UInt8 {
        UInt8(max(0, min(255, (value * 255).rounded())))
    }
}
