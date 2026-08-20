import XCTest
import UIKit
@testable import ARCore

/// 패널 글자를 키운 뒤 내용이 밖으로 넘치지 않는지 지킨다.
///
/// 넘침은 조용히 일어난다 — 총 높이가 패널을 넘으면 렌더러가 위에서부터 쌓아서
/// 마지막 문단이 아래로 잘려 나가고, 에러는 아무것도 안 난다. 설명이 가장 긴
/// 카드가 52자라 지금은 여유가 있지만, 문구를 늘리거나 비율을 더 올리면 걸린다.
///
/// 실기기는 Pretendard를 쓰고 테스트 타깃엔 그 폰트가 없어 시스템 폰트로 잰다.
/// 줄 높이가 달라지므로 여유를 두고 판정한다 — 정밀 검증이 아니라 과도한
/// 넘침을 잡는 그물이다.
final class PanelLayoutTests: XCTestCase {
    /// CardContentImageWriter의 기본값 (680 x 960에 scaleFactor 4)
    private let panelSize = CGSize(width: 680 * 4, height: 960 * 4)

    override func setUp() {
        super.setUp()
        ARCoreFontSystem.shared.configure(
            title: .systemFont(ofSize: 64, weight: .black),
            subtitle: .systemFont(ofSize: 32, weight: .bold)
        )
    }

    func test_아홉_장_모두_내용이_패널_안에_들어간다() {
        for card in TechCard.all {
            let layout = PanelLayout(card: card, size: panelSize)

            XCTAssertLessThanOrEqual(
                layout.totalHeight,
                panelSize.height * 0.88,
                "\(card.id): 내용 블록이 패널 높이의 88%를 넘었다. 잘려 보인다"
            )
        }
    }

    func test_빈칸이_지나치게_많지_않다() {
        // 키우기 전에는 56%만 채우고 나머지가 빈칸이었다. 그게 글자가
        // 작아 보인 이유다.
        let longest = TechCard.all.max { $0.detail.count < $1.detail.count }!
        let layout = PanelLayout(card: longest, size: panelSize)

        XCTAssertGreaterThan(
            layout.totalHeight,
            panelSize.height * 0.60,
            "패널이 비어 보인다. 글자 비율을 올릴 여지가 있다"
        )
    }

    func test_본문_글자가_실물_8mm_이상으로_선다() {
        // 아이패드 카메라를 거쳐 읽으므로 직접 읽기(약 4mm)의 두 배가 필요하다.
        // panelScale을 낮추면 여기서 걸린다 — 두 상수가 같이 움직여야 한다.
        let cardHeightMeters = 0.127
        let panelHeightMillimeters =
            cardHeightMeters * Double(CardPanelBuilder.panelScale) * 1000
        let detailMillimeters = panelHeightMillimeters * Double(PanelLayout.Ratio.detail)

        XCTAssertGreaterThan(detailMillimeters, 8.0,
                             "본문이 \(detailMillimeters)mm — 부스 거리에서 안 읽힌다")
    }
}
