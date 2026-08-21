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
    /// 거의 없고 분홍-마젠타-보라-파랑-청록이 넓게 깔린다.
    ///
    /// **초록·골드를 좁혔다.** 균등한 색상환으로 돌리면 초록·노랑 구간이 한 변을
    /// 통째로 차지해서 무지개 깃발처럼 읽혔다. 지금은 냉색(분홍→시안)이 둘레의
    /// 약 2/3, 초록·골드가 1/6이다.
    private static let stops: [(t: Float, rgb: SIMD3<Float>)] = [
        (0.00, .init(1.00, 0.27, 0.55)),   // 핑크
        (0.10, .init(0.93, 0.30, 0.82)),   // 마젠타
        (0.21, .init(0.68, 0.38, 1.00)),   // 보라
        (0.33, .init(0.40, 0.46, 1.00)),   // 인디고
        (0.45, .init(0.22, 0.68, 1.00)),   // 파랑
        (0.56, .init(0.22, 0.86, 0.93)),   // 시안
        (0.65, .init(0.34, 0.88, 0.70)),   // 청록
        (0.72, .init(0.62, 0.87, 0.50)),   // 초록 (좁게 지나간다)
        (0.79, .init(0.97, 0.83, 0.40)),   // 골드 (좁게 지나간다)
        (0.88, .init(1.00, 0.60, 0.32)),   // 주황
        (0.95, .init(1.00, 0.40, 0.40)),   // 코랄
        (1.00, .init(1.00, 0.27, 0.55)),   // 핑크로 되돌아온다
    ]

    static func paletteColor(at t: Float) -> SIMD3<Float> {
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

    /// 밝은 선이 띠 안 어디에 있는지 (0 = 바깥 끝, 1 = 안쪽 끝).
    ///
    /// 0.5보다 크게 둬서 선을 바깥쪽으로 밀었다. 번짐이 카드 바깥(테이블)으로
    /// 더 퍼지고 카드 그림은 덜 덮는다. CardHighlightRing의 여백·두께와 짝을
    /// 이뤄 이 선이 실물 카드 가장자리에 얹힌다.
    static let linePosition: Float = 0.62

    /// 선 자체의 굵기. 좁을수록 또렷한 광선이 된다.
    private static let coreWidth: Float = 0.045

    /// 선 바깥쪽 번짐 폭. 빛이 테이블로 새어나가는 쪽이라 넓다.
    private static let outerBloom: Float = 0.34

    /// 선 안쪽 번짐 폭. 카드 그림을 덮지 않게 좁다.
    private static let innerBloom: Float = 0.16

    /// 번짐이 선 대비 얼마나 밝은지
    private static let bloomWeight: Float = 0.5

    /// 띠 양 끝에서 0으로 사그라드는 구간의 폭 (v 단위)
    private static let edgeFadeWidth: Float = 0.18

    /// 띠를 가로지르는 위치(v)에서의 불투명도.
    ///
    /// **선 하나 + 바깥으로 퍼지는 번짐**이다. 예전에는 띠 한가운데를 흰빛으로
    /// 띄웠는데, 그 흰 심지가 색을 양옆으로 밀어내서 한 줄이 아니라 두 줄로
    /// 보였다 — 실물 사진에서 평행선 두 개로 확인됐다. 흰 심지를 없애고
    /// 채도를 그대로 살린다.
    ///
    /// 마지막 `edgeFade`가 없으면 띠 가장자리에 옅은 값이 남아 메시 경계가
    /// 실선으로 드러난다. **띠 중심이 아니라 양 끝 기준으로 재야 한다** —
    /// 중심 기준으로 깎으면 선이 중심에서 벗어나 있는 만큼 가장 밝은 지점이
    /// 선에서 밀려나, 선 바깥에 미세하게 더 밝은 자리가 생긴다.
    static func glowProfile(at v: Float) -> Float {
        let offset = v - linePosition
        let core = exp(-pow(offset / coreWidth, 2))
        let spread = offset < 0 ? outerBloom : innerBloom
        let bloom = exp(-pow(offset / spread, 2)) * bloomWeight

        let t = min(min(v, 1 - v) / edgeFadeWidth, 1)
        let edgeFade = t * t * (3 - 2 * t)          // smoothstep

        return min(1, core + bloom) * edgeFade
    }

    // MARK: - 렌더

    private static func renderColorStrip() -> CGImage? {
        makeImage { x, _ in
            // width 로 나눈다 (width-1 이 아니라). 그래야 마지막 픽셀 다음이
            // 첫 픽셀과 이어져, 반복 샘플링해도 이음매가 안 생긴다.
            let u = Float(x) / Float(stripWidth)
            // 색은 u에만 의존한다. 띠를 가로지르는 밝기는 전부 번짐 텍스처가 맡는다.
            return (paletteColor(at: u), 1)
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
