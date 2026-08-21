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

/// 기술명이 두 줄로 접힐 때 아래 요소를 덮지 않는지 지킨다.
///
/// **조용히 깨지는 종류의 버그다.** 렌더러는 기술명을 두 줄 들어갈 상자에 그리는데
/// 다음 요소로는 한 줄 남짓만 내려간다. 한 줄짜리 이름에서는 아무 일도 안 나고,
/// 이름이 길어지는 순간 둘째 줄이 태그와 구분선 위에 겹쳐 찍힌다. 에러는 없다.
///
/// 실기기는 Pretendard를 쓰고 테스트 타깃엔 그 폰트가 없어 시스템 폰트로 잰다.
/// 그래서 "어느 카드가 접히는가"는 여기서 단정할 수 없다 — 대신 **접히든 말든
/// 잰 높이만큼은 자리를 잡아둔다**는 불변식을 검사한다. 폰트가 바뀌어도 살아남는다.
final class PanelTitleWrapTests: XCTestCase {
    /// CardContentImageWriter의 기본값 (680 x 960에 scaleFactor 4)
    private let panelSize = CGSize(width: 680 * 4, height: 960 * 4)

    override func setUp() {
        super.setUp()
        ARCoreFontSystem.shared.configure(
            title: .systemFont(ofSize: 64, weight: .black),
            subtitle: .systemFont(ofSize: 32, weight: .bold)
        )
    }

    /// 주어진 글자가 실제로 차지하는 높이
    private func measuredHeight(_ text: String, font: UIFont,
                                style: NSParagraphStyle, width: CGFloat) -> CGFloat {
        (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: style],
            context: nil
        ).height
    }

    func test_기술명이_차지하는_높이만큼_자리를_잡는다() {
        for card in TechCard.all {
            let layout = PanelLayout(card: card, size: panelSize)
            let measured = measuredHeight(card.name, font: layout.nameFont,
                                          style: layout.centered, width: layout.contentWidth)

            XCTAssertGreaterThanOrEqual(
                layout.nameHeight, measured - 0.5,
                "\(card.id): 기술명이 \(measured)pt인데 \(layout.nameHeight)pt만 잡았다 — 태그를 덮는다"
            )
        }
    }

    func test_태그가_차지하는_높이만큼_자리를_잡는다() {
        for card in TechCard.all {
            let layout = PanelLayout(card: card, size: panelSize)
            let measured = measuredHeight(card.tag, font: layout.tagFont,
                                          style: layout.centered, width: layout.contentWidth)

            XCTAssertGreaterThanOrEqual(
                layout.tagHeight, measured - 0.5,
                "\(card.id): 태그가 \(measured)pt인데 \(layout.tagHeight)pt만 잡았다 — 구분선을 덮는다"
            )
        }
    }

    func test_아주_긴_기술명도_두_줄_자리를_잡는다() {
        // 폰트와 무관하게 반드시 접히는 길이. 실제 카드가 짧아져도 이 회귀는 남는다.
        let card = TechCard(
            id: "wrap-probe",
            name: "Apple Intelligence Foundation Models Nearby Interaction",
            tag: "온디바이스 개인 지능과 초광대역 정밀 측위를 한 줄에 담을 수 없는 긴 태그",
            summary: "-", detail: "-"
        )
        let layout = PanelLayout(card: card, size: panelSize)

        XCTAssertGreaterThan(layout.nameHeight, layout.nameFont.lineHeight * 1.5,
                             "두 줄인데 한 줄 자리만 잡았다")
        XCTAssertGreaterThan(layout.tagHeight, layout.tagFont.lineHeight * 1.5,
                             "두 줄인데 한 줄 자리만 잡았다")
    }

    func test_아홉_장_모두_기술명이_한_줄로_선다() {
        // 관람객이 보는 결과다. 두 줄로 접히면 태그를 덮거나 패널을 넘친다.
        for card in TechCard.all {
            let layout = PanelLayout(card: card, size: panelSize)
            XCTAssertLessThanOrEqual(
                layout.nameHeight, layout.nameFont.lineHeight * 1.2,
                "\(card.id): 기술명이 접혔다. 이름이 길어졌거나 minimumTitleScale이 너무 높다"
            )
        }
    }

    func test_기술명을_지나치게_줄이지_않는다() {
        // 카드마다 제목 크기가 널뛰면 아홉 장이 따로 논다.
        let base = panelSize.height * PanelLayout.Ratio.name
        for card in TechCard.all {
            let layout = PanelLayout(card: card, size: panelSize)
            XCTAssertGreaterThanOrEqual(
                layout.nameFont.pointSize,
                base * PanelLayout.Ratio.minimumTitleScale - 0.5,
                "\(card.id): 하한 아래로 줄었다"
            )
        }
    }

    func test_한_줄_이름은_예전과_같은_자리를_쓴다() {
        // 이번 수정이 멀쩡히 보이던 카드까지 흔들면 안 된다.
        // 예전 값: 이름 = lineHeight x 1.15, 태그 = lineHeight x 1.9
        let card = TechCard(id: "short", name: "Siri", tag: "음성",
                            summary: "-", detail: "-")
        let layout = PanelLayout(card: card, size: panelSize)

        XCTAssertEqual(layout.nameHeight + layout.nameGap,
                       layout.nameFont.lineHeight * 1.15, accuracy: 0.5)
        XCTAssertEqual(layout.tagHeight + layout.tagGap,
                       layout.tagFont.lineHeight * 1.9, accuracy: 0.5)
    }
}
