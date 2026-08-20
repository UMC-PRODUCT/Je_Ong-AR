//
//  PanelLayout.swift
//  ARCore
//

import UIKit

/// 설명 패널 한 장의 세로 배치 치수.
///
/// 렌더러에 흩어져 있던 숫자를 한곳에 모았다. 글자를 키울 때 가장 무서운 건
/// 긴 카드의 본문이 조용히 패널 밖으로 흘러나가는 것인데, 여기서 총 높이를
/// 계산해두면 테스트가 9장 전부를 한 번에 확인할 수 있다.
///
/// **비율은 부스에서의 읽기 거리로 정했다.** 패널은 실물 16.2 x 22.9cm로 뜨고,
/// 관람객은 아이패드 카메라를 거쳐 본다. 직접 읽을 때보다 두 배쯤 커야 읽혀서
/// 본문을 약 9mm로 잡았다.
struct PanelLayout {
    /// 패널 크기 대비 비율. 이름·태그·본문은 높이 기준, 로고와 여백은 너비 기준이다.
    enum Ratio {
        static let logoWidth: CGFloat = 0.30
        static let name: CGFloat = 0.082
        static let tag: CGFloat = 0.042
        static let detail: CGFloat = 0.039

        static let margin: CGFloat = 0.08
        static let topInset: CGFloat = 0.06
        static let logoGap: CGFloat = 0.035
        static let ruleGap: CGFloat = 0.032
        static let lineSpacing: CGFloat = 0.008

        /// 줄 높이의 몇 배만큼 다음 요소로 내려갈지
        static let nameLead: CGFloat = 1.15
        static let tagLead: CGFloat = 1.9
    }

    let margin: CGFloat
    let contentWidth: CGFloat
    let logoSide: CGFloat
    let nameFont: UIFont
    let tagFont: UIFont
    let detailFont: UIFont
    let detailHeight: CGFloat
    let totalHeight: CGFloat
    let centered: NSParagraphStyle
    let justified: NSParagraphStyle

    init(card: TechCard, size: CGSize) {
        margin = size.width * Ratio.margin
        contentWidth = size.width - margin * 2
        logoSide = size.width * Ratio.logoWidth

        nameFont = UIFont.arCoreTitle.withSize(size.height * Ratio.name)
        tagFont = UIFont.arCoreSubtitle.withSize(size.height * Ratio.tag)
        detailFont = UIFont.arCoreSubtitle.withSize(size.height * Ratio.detail)

        let centeredStyle = NSMutableParagraphStyle()
        centeredStyle.alignment = .center
        centered = centeredStyle

        let justifiedStyle = NSMutableParagraphStyle()
        justifiedStyle.alignment = .left
        justifiedStyle.lineSpacing = size.height * Ratio.lineSpacing
        justified = justifiedStyle

        detailHeight = (card.detail as NSString).boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: detailFont, .paragraphStyle: justifiedStyle],
            context: nil
        ).height

        totalHeight = logoSide
            + size.height * Ratio.logoGap
            + nameFont.lineHeight * Ratio.nameLead
            + tagFont.lineHeight * Ratio.tagLead
            + size.height * Ratio.ruleGap
            + detailHeight
    }
}
