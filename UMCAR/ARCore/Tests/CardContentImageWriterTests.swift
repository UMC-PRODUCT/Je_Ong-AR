import XCTest
import UIKit
@testable import ARCore

/// 패널 텍스처 생성이 실제로 이미지를 만들어내는지 확인한다.
///
/// AR 경로는 실기기가 있어야 검증되지만, 텍스처를 굽는 일은 UIKit만 쓰므로
/// 시뮬레이터에서 돌아간다 (DESIGN.md §11).
final class CardContentImageWriterTests: XCTestCase {
    private var baseURL: URL!

    override func setUp() {
        super.setUp()
        ARCoreFontSystem.shared.configure(
            title: .systemFont(ofSize: 64, weight: .black),
            subtitle: .systemFont(ofSize: 32, weight: .bold)
        )
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("panel-tests-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: baseURL)
        super.tearDown()
    }

    func test_9장_모두_패널_이미지가_만들어진다() throws {
        let writer = CardContentImageWriter(baseURL: baseURL)

        for card in TechCard.all {
            try writer.writeImage(cardData: card)

            let path = baseURL.appendingPathComponent("\(card.id).png")
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: path.path),
                "\(card.id): 패널 이미지가 안 만들어졌다"
            )

            let data = try Data(contentsOf: path)
            let image = try XCTUnwrap(UIImage(data: data), "\(card.id): PNG로 안 읽힌다")
            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)
        }
    }

    func test_패널은_카드와_같은_세로_비율이다() throws {
        // 패널 quad가 카드 실측(90 x 127mm)으로 만들어지므로 텍스처도 세로여야
        // 글자가 늘어나지 않는다.
        let writer = CardContentImageWriter(baseURL: baseURL)
        let card = try XCTUnwrap(TechCard.all.first)
        try writer.writeImage(cardData: card)

        let data = try Data(contentsOf: baseURL.appendingPathComponent("\(card.id).png"))
        let image = try XCTUnwrap(UIImage(data: data))

        XCTAssertLessThan(image.size.width, image.size.height, "패널 텍스처가 가로다")

        let cardRatio = 90.0 / 127.0
        let imageRatio = image.size.width / image.size.height
        XCTAssertEqual(imageRatio, cardRatio, accuracy: 0.05,
                       "패널 비율이 카드(90x127mm)와 다르다")
    }

    func test_빈_이미지가_아니다() throws {
        // 배경만 칠하고 끝나면 부스에서 흰 판만 뜬다. 실제로 무언가 그려졌는지 본다.
        let writer = CardContentImageWriter(baseURL: baseURL)
        let card = try XCTUnwrap(TechCard.all.first)
        try writer.writeImage(cardData: card)

        let data = try Data(contentsOf: baseURL.appendingPathComponent("\(card.id).png"))
        let image = try XCTUnwrap(UIImage(data: data))
        let cgImage = try XCTUnwrap(image.cgImage)

        // 8x8로 줄여서 밝기 편차를 본다. 단색이면 편차가 0에 가깝다.
        let side = 8
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels, width: side, height: side,
            bitsPerComponent: 8, bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))

        let luminances = stride(from: 0, to: pixels.count, by: 4).map {
            Double(pixels[$0]) * 0.299 + Double(pixels[$0 + 1]) * 0.587 + Double(pixels[$0 + 2]) * 0.114
        }
        let mean = luminances.reduce(0, +) / Double(luminances.count)
        let variance = luminances.map { pow($0 - mean, 2) }.reduce(0, +) / Double(luminances.count)

        XCTAssertGreaterThan(variance, 1.0, "패널이 사실상 단색이다 — 아무것도 안 그려졌다")
    }
}
