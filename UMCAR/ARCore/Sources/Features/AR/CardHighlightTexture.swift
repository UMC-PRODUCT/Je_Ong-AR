//
//  CardHighlightTexture.swift
//  ARCore
//

import RealityKit
import UIKit
import os.log

/// 인식된 카드를 감싸는 무지개 테두리 텍스처.
///
/// 관람객에게 "이 카드는 누를 수 있다"를 알리는 어포던스다. 화면 하단 안내 문구가
/// 방법을 말한다면, 이 테두리는 **어느 것을** 누르면 되는지를 가리킨다.
///
/// 텍스처는 9장이 공유한다 — 카드마다 굽을 이유가 없고, 세션당 한 번만 만든다.
enum CardHighlightTexture {
    /// 카드 대비 테두리 두께 비율
    private static let strokeRatio: CGFloat = 0.055

    /// 모서리 둥글기 비율
    private static let cornerRatio: CGFloat = 0.06

    private static let logger = Logger.of("CardHighlightTexture")

    private static var cached: TextureResource?

    /// 무지개 테두리 텍스처를 만든다. 실패하면 nil — 테두리 없이도 앱은 동작한다.
    static func make() -> TextureResource? {
        if let cached { return cached }

        // 카드 비율(90:127)에 맞춘다. 늘어나면 모서리 둥글기가 찌그러진다.
        let size = CGSize(width: 512, height: 723)
        let image = render(size: size)

        guard let cgImage = image.cgImage else {
            logger.error("테두리 이미지를 CGImage로 못 바꿨다")
            return nil
        }

        do {
            let texture = try TextureResource(image: cgImage, options: .init(semantic: .color))
            cached = texture
            return texture
        } catch {
            logger.error("테두리 텍스처 생성 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// 가장자리에만 무지개가 있고 안쪽은 투명한 이미지를 그린다.
    private static func render(size: CGSize) -> UIImage {
        let stroke = size.width * strokeRatio
        let corner = size.width * cornerRatio

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext

            let rect = CGRect(origin: .zero, size: size).insetBy(dx: stroke / 2, dy: stroke / 2)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: corner)

            // 테두리 선만 남기고 그 안에서 그라디언트를 칠한다.
            cg.saveGState()
            cg.addPath(path.cgPath)
            cg.setLineWidth(stroke)
            cg.replacePathWithStrokedPath()
            cg.clip()

            let hues: [CGFloat] = [0.00, 0.09, 0.16, 0.33, 0.52, 0.66, 0.78, 0.92, 1.00]
            let colors = hues.map {
                UIColor(hue: $0, saturation: 0.90, brightness: 1.0, alpha: 1.0).cgColor
            }
            let locations: [CGFloat] = hues.enumerated().map { i, _ in
                CGFloat(i) / CGFloat(hues.count - 1)
            }

            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors as CFArray,
                                         locations: locations) {
                // 대각선 방향. 세로나 가로로 칠하면 한 변이 통째로 단색이 된다.
                cg.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
                )
            }
            cg.restoreGState()
        }
    }
}
