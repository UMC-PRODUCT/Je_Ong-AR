import Foundation
import XCTest
@testable import UMCAR

final class UMCARTests: XCTestCase {
    func test_twoPlusTwo_isFour() {
        XCTAssertEqual(2+2, 4)
    }

    /// 인트로는 영상을 못 찾으면 조용히 건너뛴다 — 갇히는 것보다 낫지만, 그래서
    /// Tuist glob이 mp4를 빠뜨리거나 파일명이 틀려도 런타임에 티가 안 난다.
    /// 그 유일한 실패 모드를 여기서 잡는다.
    func test_인트로_영상이_앱_번들에_포함된다() {
        let url = Bundle.main.url(
            forResource: IntroVideoView.IntroVideoConstants.resourceName,
            withExtension: IntroVideoView.IntroVideoConstants.resourceExtension
        )

        XCTAssertNotNil(
            url,
            "\(IntroVideoView.IntroVideoConstants.resourceName).\(IntroVideoView.IntroVideoConstants.resourceExtension)이 번들에 없다 — 인트로 영상이 조용히 건너뛰어진다"
        )
    }
}
