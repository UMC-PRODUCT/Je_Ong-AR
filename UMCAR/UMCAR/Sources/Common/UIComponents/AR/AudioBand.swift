//
//  AudioBand.swift
//  UMCAR
//
//  Created by 임영택 on 8/17/25.
//

import SwiftUI

struct AudioBand: View {
    @Binding var isPlaying: Bool // Timer invalidate를 위해 상태유지 필요 -> Binding
    @State var currentPhase: Int = 0
    @State var timer: Timer?
    
    var currentImageResource: ImageResource {
        switch currentPhase {
        case 0:
            return .audioBandOff
        case 1:
            return .audioBand1
        case 2:
            return .audioBand2
        case 3:
            return .audioBand3
        case 4:
            return .audioBand4
        default:
            return .audioBandOff
        }
    }
    
    var body: some View {
        Image(currentImageResource)
            .resizable()
            .scaledToFit()
            .onAppear {
                if isPlaying {
                    startAudioBandAnimation()
                }
            }
            .onChange(of: isPlaying) { _, newValue in
                if newValue {
                    startAudioBandAnimation()
                } else {
                    invalidateAudioBandAnimation()
                }
            }
    }
}

extension AudioBand {
    func startAudioBandAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            currentPhase = (currentPhase % 4) + 1 // 1, 2, 3, 4, 1, ...
        }
    }
    
    func invalidateAudioBandAnimation() {
        timer?.invalidate()
        timer = nil
        currentPhase = 0
    }
}

#Preview {
    AudioBand(isPlaying: .constant(true))
}
