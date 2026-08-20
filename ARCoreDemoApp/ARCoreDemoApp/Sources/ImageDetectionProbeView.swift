//
//  ImageDetectionProbeView.swift
//  ARCoreDemoApp
//
//  이미지 인식 검증용 화면.
//
//  목적은 단 하나 — "카드 9장이 각각 구분되어 인식되는가"를 실기기에서 확인하는 것.
//  ARCore의 게임 기계장치(평면 인식·포탈·점수)를 일부러 쓰지 않는다. 검증 대상을
//  이미지 인식으로만 좁혀야 실패했을 때 원인이 분명해지기 때문이다.
//
//  인식이 확인되면 이 파일은 폐기하고 UMCAR 본 전환 구현으로 대체한다.
//

import SwiftUI
import ARKit
import RealityKit

/// 카드 뒷면 레퍼런스 이미지를 담은 AR Resource Group 이름.
/// Tools/make_ar_resource_group.py 가 이 이름으로 만든다.
private let resourceGroupName = "TechCards"

/// 인식된 카드 한 장에 대한 관측 결과.
struct DetectedCard: Identifiable, Equatable {
    let id: String              // ARReferenceImage.name
    let physicalSize: CGSize    // 미터
    let elapsed: TimeInterval   // 세션 시작 후 인식까지 걸린 시간
}

@Observable
final class ImageDetectionProbeModel {
    /// 카탈로그에서 실제로 로드된 레퍼런스 이미지 이름들. 9개가 아니면 등록이 잘못된 것이다.
    var referenceNames: [String] = []
    var detected: [DetectedCard] = []
    var errorText: String?
    /// 리셋 버튼을 누른 횟수. updateUIView가 이 값의 변화를 보고 세션을 다시 돌린다.
    var resetToken = 0

    var detectedIDs: Set<String> { Set(detected.map(\.id)) }
}

// MARK: - AR 뷰

struct ImageDetectionProbeARView: UIViewRepresentable {
    let model: ImageDetectionProbeModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        // ARView가 제 마음대로 세션을 구성하면 detectionImages 설정이 덮인다.
        arView.automaticallyConfigureSession = false
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView
        context.coordinator.run()
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        guard context.coordinator.appliedResetToken != model.resetToken else { return }
        context.coordinator.appliedResetToken = model.resetToken
        context.coordinator.run()
    }

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    final class Coordinator: NSObject, ARSessionDelegate {
        private let model: ImageDetectionProbeModel
        weak var arView: ARView?
        var appliedResetToken = 0
        private var startedAt = Date()

        init(model: ImageDetectionProbeModel) {
            self.model = model
        }

        func run() {
            guard let arView else { return }

            guard let refs = ARReferenceImage.referenceImages(
                inGroupNamed: resourceGroupName, bundle: nil
            ) else {
                setError("AR Resource Group '\(resourceGroupName)'을 찾지 못했다. "
                         + "Assets.xcassets에 등록됐는지 확인할 것.")
                return
            }

            arView.scene.anchors.removeAll()
            startedAt = Date()

            let names = refs.compactMap(\.name).sorted()
            DispatchQueue.main.async {
                self.model.referenceNames = names
                self.model.detected.removeAll()
                self.model.errorText = nil
            }

            let configuration = ARWorldTrackingConfiguration()
            configuration.detectionImages = refs
            // 0 = 추적 안 함. Apple 문서상 이때도 관측된 이미지마다 앵커가 붙는다.
            // 추적을 켜면 동시 4장 상한에 걸리는데, 카드는 책상에 고정이라 추적이 필요 없다.
            configuration.maximumNumberOfTrackedImages = 0
            configuration.planeDetection = []

            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }

        // MARK: ARSessionDelegate

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            let elapsed = Date().timeIntervalSince(startedAt)

            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor else { continue }
                let reference = imageAnchor.referenceImage
                let name = reference.name ?? "(이름 없음)"

                placeMarkers(on: imageAnchor, size: reference.physicalSize)

                let card = DetectedCard(id: name,
                                        physicalSize: reference.physicalSize,
                                        elapsed: elapsed)
                DispatchQueue.main.async {
                    guard !self.model.detected.contains(where: { $0.id == name }) else { return }
                    self.model.detected.append(card)
                }
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            setError(error.localizedDescription)
        }

        // MARK: 마커

        /// 카드 위에 마커 둘을 놓는다.
        ///
        /// ARImageAnchor의 로컬 공간은 **이미지가 x-z 평면에 눕고 +Y가 법선**이다
        /// (Apple 샘플 주석: "ARImageAnchor assumes the image is horizontal in its local space").
        /// RealityKit의 generatePlane(width:depth:)도 x-z 평면이라 회전 보정이 필요 없다.
        ///
        /// 이 가정이 맞으면 화면에서:
        ///   - 초록 판이 실물 카드에 정확히 겹치고
        ///   - 하늘색 판이 카드에서 5cm 떠서 보인다
        /// 틀렸다면 판이 카드 옆으로 서거나 파고든다. 설계 §2를 이 화면으로 검증한다.
        private func placeMarkers(on imageAnchor: ARImageAnchor, size: CGSize) {
            guard let arView else { return }
            let width = Float(size.width)
            let depth = Float(size.height)

            let anchorEntity = AnchorEntity(anchor: imageAnchor)

            var overlayMaterial = UnlitMaterial(color: .green)
            overlayMaterial.blending = .transparent(opacity: 0.35)
            let overlay = ModelEntity(
                mesh: .generatePlane(width: width, depth: depth),
                materials: [overlayMaterial]
            )
            anchorEntity.addChild(overlay)

            var floatingMaterial = UnlitMaterial(color: .cyan)
            floatingMaterial.blending = .transparent(opacity: 0.75)
            let floating = ModelEntity(
                mesh: .generatePlane(width: width * 0.55, depth: depth * 0.3),
                materials: [floatingMaterial]
            )
            floating.position = [0, 0.05, 0]        // +Y = 카드 법선
            anchorEntity.addChild(floating)

            arView.scene.addAnchor(anchorEntity)
        }

        private func setError(_ text: String) {
            DispatchQueue.main.async { self.model.errorText = text }
        }
    }
}

// MARK: - 화면

struct ImageDetectionProbeView: View {
    @State private var model = ImageDetectionProbeModel()

    var body: some View {
        ZStack(alignment: .topLeading) {
            ImageDetectionProbeARView(model: model)
                .ignoresSafeArea()

            panel
                .padding(12)
                .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
                .padding(12)
        }
        .navigationTitle("이미지 인식 검증")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("인식 \(model.detected.count) / \(model.referenceNames.count)")
                .font(.headline)

            if let errorText = model.errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if model.referenceNames.isEmpty && model.errorText == nil {
                Text("레퍼런스 이미지를 불러오는 중…")
                    .font(.caption)
            }

            ForEach(model.referenceNames, id: \.self) { name in
                let card = model.detected.first { $0.id == name }
                HStack(spacing: 6) {
                    Image(systemName: card == nil ? "circle" : "checkmark.circle.fill")
                        .foregroundStyle(card == nil ? .gray : .green)
                    Text(name)
                        .font(.system(.caption, design: .monospaced))
                    if let card {
                        Text(sizeText(card.physicalSize))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.cyan)
                        Text(String(format: "%.1fs", card.elapsed))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("리셋") { model.resetToken += 1 }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
        }
    }

    /// 실측 크기를 mm로 보여준다. 90 x 127 이 아니면 카탈로그 등록이 잘못된 것이다.
    private func sizeText(_ size: CGSize) -> String {
        String(format: "%.0fx%.0fmm", size.width * 1000, size.height * 1000)
    }
}

#Preview {
    ImageDetectionProbeView()
}
