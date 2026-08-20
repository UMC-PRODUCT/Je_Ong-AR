//
//  WordDetailCard.swift
//  UMCAR
//
//  Created by Apple MacBook on 7/23/25.
//

import SwiftUI

/// 단어 카드 상세 컴포넌트
struct WordDetailCard: View {
    // MARK: - Property
    @Bindable var detailCardViewModel: DetailCardViewModel
    @Bindable var arViewModel: ARViewModel
    
    // MARK: - Constants
    fileprivate enum WordDetailCardConstants {
        static let horizonPadding: CGFloat = 40
        static let cornerRadius: CGFloat = 30
        static let safePadding: CGFloat = 12
        static let topPadding: CGFloat = 19
        static let detailViewTopPadding: CGFloat = 37
        
        static let bottomContentsHspacing: CGFloat = 40
        static let topRightVspacing: CGFloat = 12
        static let bottomRightHspacing: CGFloat = 20
        static let guideHspacing: CGFloat = 18
        static let voiceHspacing: CGFloat = 4
        static let accuracyHspacing: CGFloat = 8
        
        static let offsetValue: (CGFloat,CGFloat) = (40, 95)
        static let maxWidth: CGFloat = 680
        static let rectangleMaxHeight: CGFloat = 440
        static let mainMaxHeight: CGFloat = 493
        static let mainMaxWidth: CGFloat = 730
        static let capsuleWidth: CGFloat = 4
        static let capsuleHeight: CGFloat = 80
        static let dividerLine: CGFloat = 4
        static let imageSize: CGFloat = 280
        static let voiceBarCount: Int = 8
        static let textTStroke: CGFloat = 5
        static let textBStroke: CGFloat = 3
        static let textCStroke: CGFloat = 1
        
        static let rotationDegree: CGFloat = 35
        static let micImageSize: CGFloat = 36
        static let voiceWidth: CGFloat = 6
        static let voiceAnimation: TimeInterval = 0.1
        static let accuracyText: String = "발음 정확도"
        static let successText: String = "성공!"
        
        static let dropShadowColor: Color = Color(#colorLiteral(red: 0.6941176471, green: 0.6941176471, blue: 0.5137254902, alpha: 1))
        static let dropShadowSize: CGFloat = 8
        
        static let audioBandWidth: CGFloat = 82
        static let audioBandHeight: CGFloat = 44
    }
    // MARK: - Body
    var body: some View {
        if let model = detailCardViewModel.word {
            ZStack(alignment: .topTrailing, content: {
                RoundedRectangle(cornerRadius: WordDetailCardConstants.cornerRadius)
                    .fill(Color.wordCardYellow.opacity(0.75))
                    .background(Material.thin)
                    .clipShape(RoundedRectangle(cornerRadius: WordDetailCardConstants.cornerRadius))
                    .shadow(color: WordDetailCardConstants.dropShadowColor, radius: 0, x: 0, y: WordDetailCardConstants.dropShadowSize)
                    .frame(width: WordDetailCardConstants.mainMaxWidth, height: WordDetailCardConstants.rectangleMaxHeight)
                
                VStack {
                    topContents(model: model)
                    Spacer()
                    dividerLine
                    bottomContents
                }
                .frame(height: 380)
                .safeAreaPadding(WordDetailCardConstants.safePadding)
                
                if detailCardViewModel.lastPassed {
                    successText
                        .rotationEffect(.degrees(WordDetailCardConstants.rotationDegree))
                }
            })
            .safeAreaPadding(.top, WordDetailCardConstants.detailViewTopPadding)
            .onChange(of: detailCardViewModel.accuracyPercent) { oldValue, newValue in
                if let wordId = detailCardViewModel.word?.id {
                    arViewModel.triggerSubmitAccuracy = (
                        wordId,
                        Float(detailCardViewModel.accuracyPercent) / 100
                    )
                }
            }
            .frame(width: WordDetailCardConstants.mainMaxWidth, height: WordDetailCardConstants.rectangleMaxHeight)
        }
    }
    
    private var successText: some View {
        Text(WordDetailCardConstants.successText)
            .font(.semibold104)
            .foregroundStyle(Color.green03)
            .customOutline(width: WordDetailCardConstants.textTStroke, color: .white01)
            .offset(x: WordDetailCardConstants.offsetValue.0 ,y: -WordDetailCardConstants.offsetValue.1)
    }
    
    // MARK: - Top
    private func topContents(model: CardModel) -> some View {
        HStack(spacing: 40) {
            image(model: model)
            wordText(model: model)
        }
    }
    /// 단어 이미지
    private func image(model: CardModel) -> some View {
        Image(model.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: WordDetailCardConstants.imageSize, height: WordDetailCardConstants.imageSize)
    }
    
    private func wordText(model: CardModel) -> some View {
        VStack(spacing: WordDetailCardConstants.topRightVspacing, content: {
            Text(model.wordEng)
                .font(.semibold64)
                .customOutline(width: WordDetailCardConstants.textTStroke, color: .white)
            
            Text(model.wordKor)
                .font(.bold32)
                .customOutline(width: WordDetailCardConstants.textBStroke, color: .white)
        })
        .foregroundStyle(Color.black)
    }
    
    // MARK: - Bottom
    private var bottomContents: some View {
        HStack(spacing: WordDetailCardConstants.bottomContentsHspacing, content: {
            voiceLevel
            Capsule()
                .fill(Color.dividerYellow)
                .frame(width: WordDetailCardConstants.capsuleWidth, height: WordDetailCardConstants.capsuleHeight)
            pronunciationAccuracy
        })
        .frame(height: WordDetailCardConstants.capsuleHeight + 10, alignment: .bottomLeading)
        .offset(y: 20)
    }
    
    private var dividerLine: some View {
        Capsule()
            .fill(Color.dividerYellow)
            .frame(maxWidth: .infinity)
            .frame(height: WordDetailCardConstants.dividerLine)
            .offset(y: 30)
    }
    
    // MARK: - Bodttom Right
    private var pronunciationAccuracy: some View {
        HStack(spacing: WordDetailCardConstants.accuracyHspacing, content: {
            Text(WordDetailCardConstants.accuracyText)
                .font(.bold24)
                .foregroundStyle(Color.black01)
            
            printPointGuide(type: detailCardViewModel.accuracyType)
        })
    }
    
    @ViewBuilder
    private func printPointGuide(type: AccuracyType) -> some View {
        switch type {
        case .btnMic:
            makeTextView(type: type)
        case .recording:
            makeTextView(type: type)
        case .success:
            successFailure(type: type)
        case .failure:
            successFailure(type: type)
        }
    }
    
    private func successFailure(type: AccuracyType) -> some View {
        HStack(spacing: WordDetailCardConstants.guideHspacing, content: {
            
            Text("\(detailCardViewModel.accuracyPercent)%")
                .font(type.accuracyFont)
                .foregroundStyle(type.accuracyColor)
                .customOutline(width: WordDetailCardConstants.textCStroke, color: .white)
            
            Label(title: {
                makeTextView(type: type)
            }, icon: {
                Image(type.image ?? .greenCheck)
            })
        })
    }
    
    private func makeTextView(type: AccuracyType) -> some View {
        Text(type.text)
            .font(type.reactionTextFont)
            .foregroundStyle(type.reactionTextColor)
    }
    
    // MARK: - BottomLeft
    private var voiceLevel: some View {
        HStack(spacing: WordDetailCardConstants.voiceHspacing, content: {
            Image(.mic)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: WordDetailCardConstants.micImageSize, height: WordDetailCardConstants.micImageSize)
            
            AudioBand(
                isPlaying: Binding(
                    get: { detailCardViewModel.recordingState == .recording },
                    set: { _ in }
                )
            )
            .frame(width: WordDetailCardConstants.audioBandWidth, height: WordDetailCardConstants.audioBandHeight)
        })
    }
}

#Preview {
    WordDetailCard(detailCardViewModel: .init(), arViewModel: .init())
}
