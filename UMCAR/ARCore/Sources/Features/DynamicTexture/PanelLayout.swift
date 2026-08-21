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
/// **비율은 부스에서의 읽기 거리로 정했다.** 패널은 실물 19.8 x 27.9cm로 뜨고,
/// 관람객은 아이패드 카메라를 거쳐 본다. 카메라를 거치면 해상도와 흔들림으로
/// 손해를 보므로 직접 읽을 때(약 4mm)의 세 배인 약 13mm로 잡았다.
///
/// 로고를 0.26으로 줄여 글자에 자리를 내줬다 — 아이콘은 이미 실물 카드에
/// 크게 인쇄돼 있어 패널에서까지 클 이유가 없다.
struct PanelLayout {
    /// 패널 크기 대비 비율. 이름·태그·본문은 높이 기준, 로고와 여백은 너비 기준이다.
    enum Ratio {
        static let logoWidth: CGFloat = 0.26
        static let name: CGFloat = 0.095
        static let tag: CGFloat = 0.050
        static let detail: CGFloat = 0.047

        static let margin: CGFloat = 0.08
        static let topInset: CGFloat = 0.06
        static let logoGap: CGFloat = 0.035
        static let ruleGap: CGFloat = 0.032
        static let lineSpacing: CGFloat = 0.008

        /// 기술명·태그 **아래에 두는 여백**을 줄 높이의 몇 배로 잡을지.
        ///
        /// 예전에는 "다음 요소까지 내려갈 거리"였다(각각 1.15, 1.9). 글자가 딱
        /// 한 줄이라는 가정이 숨어 있어서, 이름이 두 줄로 접히면 둘째 줄이 태그
        /// 위에 겹쳐 찍혔다. 지금은 글자 높이를 따로 재고 이 값은 순수한 여백만
        /// 맡는다 — 한 줄일 때의 총 간격은 예전과 같다(1 + 0.15, 1 + 0.9).
        static let nameGap: CGFloat = 0.15
        static let tagGap: CGFloat = 0.9

        /// 한 줄에 안 들어가는 기술명·태그를 어디까지 줄여도 되는지 (원래 크기 대비).
        ///
        /// 두 줄로 접히게 두면 내용 블록이 패널 높이를 넘는다 — 실제로 9장 중
        /// 세 장이 넘겼다. 접는 대신 그 카드만 글자를 줄여 한 줄로 세운다.
        /// 여기까지 줄여도 안 들어가면 그때는 접고, 접힌 높이만큼 자리를 잡는다.
        static let minimumTitleScale: CGFloat = 0.6
    }

    let margin: CGFloat
    let contentWidth: CGFloat
    let logoSide: CGFloat
    let nameFont: UIFont
    let tagFont: UIFont
    let detailFont: UIFont

    /// 기술명이 실제로 차지하는 높이. 두 줄로 접히면 그만큼 커진다.
    let nameHeight: CGFloat

    /// 기술명 아래 여백
    let nameGap: CGFloat

    /// 태그가 실제로 차지하는 높이
    let tagHeight: CGFloat

    /// 태그 아래 여백
    let tagGap: CGFloat

    let detailHeight: CGFloat
    let totalHeight: CGFloat
    let centered: NSParagraphStyle
    let justified: NSParagraphStyle

    init(card: TechCard, size: CGSize) {
        margin = size.width * Ratio.margin
        contentWidth = size.width - margin * 2
        logoSide = size.width * Ratio.logoWidth

        // 기술명·태그는 한 줄에 세운다. 카드마다 이름 길이가 제각각이라
        // 고정 크기로 두면 긴 이름만 접히고, 접힌 줄이 아래 요소를 밀어낸다.
        nameFont = Self.fitted(card.name,
                               base: UIFont.arCoreTitle.withSize(size.height * Ratio.name),
                               width: contentWidth)
        tagFont = Self.fitted(card.tag,
                              base: UIFont.arCoreSubtitle.withSize(size.height * Ratio.tag),
                              width: contentWidth)
        detailFont = UIFont.arCoreSubtitle.withSize(size.height * Ratio.detail)

        let centeredStyle = NSMutableParagraphStyle()
        centeredStyle.alignment = .center
        centered = centeredStyle

        let justifiedStyle = NSMutableParagraphStyle()
        justifiedStyle.alignment = .left
        justifiedStyle.lineSpacing = size.height * Ratio.lineSpacing
        justified = justifiedStyle

        detailHeight = Self.height(of: card.detail, font: detailFont,
                                   style: justifiedStyle, width: contentWidth)

        // 한 줄짜리 이름은 예전과 똑같이 놓이도록 lineHeight를 하한으로 둔다.
        // boundingRect는 한 줄이어도 lineHeight보다 살짝 작게 나올 수 있다.
        nameHeight = max(nameFont.lineHeight,
                         Self.height(of: card.name, font: nameFont,
                                     style: centeredStyle, width: contentWidth))
        tagHeight = max(tagFont.lineHeight,
                        Self.height(of: card.tag, font: tagFont,
                                    style: centeredStyle, width: contentWidth))

        nameGap = nameFont.lineHeight * Ratio.nameGap
        tagGap = tagFont.lineHeight * Ratio.tagGap

        totalHeight = logoSide
            + size.height * Ratio.logoGap
            + nameHeight + nameGap
            + tagHeight + tagGap
            + size.height * Ratio.ruleGap
            + detailHeight
    }

    /// 한 줄에 들어가도록 줄인 폰트. 이미 들어가면 그대로 돌려준다.
    ///
    /// 글자 폭은 포인트 크기에 비례하므로 비율 한 번으로 끝난다. `minimumTitleScale`
    /// 아래로는 안 줄인다 — 카드마다 제목 크기가 널뛰면 아홉 장이 따로 논다.
    private static func fitted(_ text: String, base: UIFont, width: CGFloat) -> UIFont {
        let natural = (text as NSString).size(withAttributes: [.font: base]).width
        guard natural > width, natural > 0 else { return base }

        let scale = max(Ratio.minimumTitleScale, width / natural)
        return base.withSize(base.pointSize * scale)
    }

    /// 주어진 폭 안에서 글자가 차지하는 높이. 접히면 줄 수만큼 커진다.
    private static func height(of text: String, font: UIFont,
                               style: NSParagraphStyle, width: CGFloat) -> CGFloat {
        (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: style],
            context: nil
        ).height
    }
}
