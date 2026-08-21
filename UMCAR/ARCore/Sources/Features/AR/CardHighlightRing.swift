//
//  CardHighlightRing.swift
//  ARCore
//

import RealityKit
import simd

/// 카드 테두리를 따라 도는 띠(band) 메시.
///
/// **왜 판이 아니라 띠인가.** 예전에는 카드 크기의 사각 판에 "가운데가 뚫린"
/// 테두리 텍스처를 붙였다. 그러면 테두리 모양이 텍스처에 박혀서, 색을 움직이려면
/// 프레임마다 텍스처를 다시 구워야 했다.
///
/// 모양을 메시로 옮기면 텍스처는 "띠를 폈을 때의 한 줄"만 담으면 된다. UV를
/// u = 테두리를 따라 잰 거리, v = 띠를 가로지른 거리로 깔았으므로, 색을
/// 흘려보내는 일이 UV를 x축으로 미는 것으로 끝난다 (CardHighlightMaterial).
///
/// **좌표계.** ARImageAnchor의 로컬 공간을 따라 x-z 평면에 눕고 +Y가 법선이다.
/// 2D 계산은 (x, z)로 하고 마지막에 y=0을 끼워 넣는다.
enum CardHighlightRing {
    /// 메시 정점 데이터.
    ///
    /// RealityKit 없이 검증할 수 있게 순수 값으로 떼어놨다 — 감기 방향이 틀리면
    /// 뒷면만 남아 테두리가 통째로 안 보이는데, 그건 눈으로만 잡을 수 있는
    /// 버그가 아니다.
    struct Geometry: Equatable {
        var positions: [SIMD3<Float>]
        var normals: [SIMD3<Float>]
        var textureCoordinates: [SIMD2<Float>]
        var triangleIndices: [UInt32]
    }

    /// 띠의 바깥 모서리가 카드 밖으로 나가는 거리 (카드 폭 대비).
    ///
    /// 두께·선 위치(CardHighlightTexture.linePosition)와 짝을 이뤄, 밝은 선이
    /// 실물 카드 가장자리 바로 바깥(카드 폭의 2%)에 얹히도록 잡았다. 셋 중
    /// 하나만 바꾸면 선이 카드 안으로 파고들거나 액자처럼 떠버린다.
    static let outerMargin: Float = 0.144

    /// 띠 두께 (카드 폭 대비).
    ///
    /// 번짐이 이 안에서 다 사라져야 해서 눈에 보이는 선보다 훨씬 두껍다.
    /// 실제로 보이는 건 두께의 5% 남짓인 심지뿐이고 나머지는 번짐이다.
    static let bandWidth: Float = 0.20

    /// 띠 중심선의 모서리 둥글기 (카드 폭 대비).
    ///
    /// 실물 카드 모서리(약 0.06)보다 넉넉하다. 빛은 각을 세우지 않는다 —
    /// 카드와 똑같이 맞추면 형광펜으로 덧그린 윤곽선처럼 보인다.
    static let cornerRadius: Float = 0.13

    /// 모서리 하나를 몇 조각으로 나눌지. 12면 90도를 7.5도씩 끊는다.
    static let cornerSteps = 12

    /// 같은 점으로 볼 거리. 모서리 반지름이 0에 가까울 때 호가 한 점으로 뭉친다.
    private static let epsilon: Float = 1e-6

    // MARK: - 메시

    /// 띠 메시를 만든다. 실패하면 nil — 테두리 없이도 앱은 동작한다.
    static func makeMesh(cardWidth: Float, cardDepth: Float) -> MeshResource? {
        let geometry = geometry(cardWidth: cardWidth, cardDepth: cardDepth)

        var descriptor = MeshDescriptor(name: "cardHighlightRing")
        descriptor.positions = MeshBuffers.Positions(geometry.positions)
        descriptor.normals = MeshBuffers.Normals(geometry.normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(geometry.textureCoordinates)
        descriptor.primitives = .triangles(geometry.triangleIndices)

        return try? MeshResource.generate(from: [descriptor])
    }

    // MARK: - 기하

    /// 카드 크기에서 띠의 정점·UV·인덱스를 계산한다.
    static func geometry(cardWidth: Float, cardDepth: Float) -> Geometry {
        let band = cardWidth * bandWidth
        let half = band / 2
        let margin = cardWidth * outerMargin

        // 중심선은 바깥 모서리에서 띠 두께의 절반만큼 안쪽에 있다.
        let halfX = cardWidth / 2 + margin - half
        let halfZ = cardDepth / 2 + margin - half

        // 반지름이 띠 두께의 절반보다 작으면 안쪽 윤곽이 뒤집힌다. 반대로
        // 짧은 변의 절반을 넘으면 모서리끼리 겹친다.
        let radius = min(max(cardWidth * cornerRadius, half), min(halfX, halfZ))

        let samples = centerline(halfX: halfX, halfZ: halfZ, radius: radius)
        return extrude(samples: samples, half: half)
    }

    /// 중심선 위의 점과 그 지점의 바깥 방향.
    private struct Sample {
        let point: SIMD2<Float>
        let outward: SIMD2<Float>
    }

    /// 둥근 사각형 중심선을 한 바퀴 훑는다.
    ///
    /// 직선 구간은 양 끝점만 있으면 된다 — 그 사이 호의 길이는 거리에 정비례하고,
    /// UV도 거리로 매기므로 선형 보간이 정확하다. 곡선만 잘게 나눈다.
    private static func centerline(halfX: Float, halfZ: Float, radius: Float) -> [Sample] {
        let kx = halfX - radius          // 모서리 중심의 x
        let kz = halfZ - radius          // 모서리 중심의 z
        var samples: [Sample] = []

        func addEdge(from: SIMD2<Float>, to: SIMD2<Float>, outward: SIMD2<Float>) {
            samples.append(Sample(point: from, outward: outward))
            samples.append(Sample(point: to, outward: outward))
        }

        func addCorner(center: SIMD2<Float>, from start: Float, to end: Float) {
            for step in 0...cornerSteps {
                let angle = start + (end - start) * Float(step) / Float(cornerSteps)
                let outward = SIMD2<Float>(cos(angle), sin(angle))
                samples.append(Sample(point: center + outward * radius, outward: outward))
            }
        }

        // +z 방향으로 오른쪽 변을 올라가며 시작해 반시계로 한 바퀴 돈다.
        // 이 진행 방향이 아래 extrude의 감기 순서와 짝을 이룬다.
        addEdge(from: [halfX, -kz], to: [halfX, kz], outward: [1, 0])
        addCorner(center: [kx, kz], from: 0, to: .pi / 2)
        addEdge(from: [kx, halfZ], to: [-kx, halfZ], outward: [0, 1])
        addCorner(center: [-kx, kz], from: .pi / 2, to: .pi)
        addEdge(from: [-halfX, kz], to: [-halfX, -kz], outward: [-1, 0])
        addCorner(center: [-kx, -kz], from: .pi, to: .pi * 1.5)
        addEdge(from: [-kx, -halfZ], to: [kx, -halfZ], outward: [0, -1])
        addCorner(center: [kx, -kz], from: .pi * 1.5, to: .pi * 2)

        return dropDuplicates(samples)
    }

    /// 구간 이음매에서 겹친 점을 걷어낸다.
    ///
    /// 직선의 끝점과 이어지는 호의 첫 점은 위치도 바깥 방향도 같다. 그대로 두면
    /// 길이 0인 사각형이 생겨 UV가 그 자리에서 멈춘다.
    private static func dropDuplicates(_ samples: [Sample]) -> [Sample] {
        var result: [Sample] = []
        for sample in samples {
            if let last = result.last, distance(last.point, sample.point) < epsilon { continue }
            result.append(sample)
        }
        // 마지막 점이 첫 점과 겹치는 경우도 같은 이유로 뺀다. 고리를 닫는 일은
        // extrude가 UV 1.0짜리 정점을 따로 붙여서 한다.
        if let first = result.first, let last = result.last, result.count > 1,
           distance(first.point, last.point) < epsilon {
            result.removeLast()
        }
        return result
    }

    /// 중심선을 바깥·안쪽으로 벌려 띠를 만든다.
    ///
    /// **UV.** u는 중심선을 따라 잰 누적 거리를 둘레로 나눈 값이라 한 바퀴에
    /// 정확히 0→1이다. 텍스처의 왼쪽 끝 색과 오른쪽 끝 색이 같으므로 이음매가
    /// 안 보이고, 반복 샘플링으로 얼마든지 밀 수 있다. v는 0이 바깥, 1이 안쪽.
    ///
    /// **고리를 닫는 법.** 마지막 사각형이 인덱스 0으로 되감기면 u가 1이 아니라
    /// 0으로 떨어져 그 한 칸에 무지개 전체가 거꾸로 압축된다. 그래서 첫 점을
    /// u=1로 한 번 더 붙인다.
    private static func extrude(samples: [Sample], half: Float) -> Geometry {
        let count = samples.count
        guard count > 2 else {
            return Geometry(positions: [], normals: [], textureCoordinates: [], triangleIndices: [])
        }

        var lengths: [Float] = [0]
        lengths.reserveCapacity(count + 1)
        for i in 1..<count {
            lengths.append(lengths[i - 1] + distance(samples[i].point, samples[i - 1].point))
        }
        let perimeter = lengths[count - 1] + distance(samples[0].point, samples[count - 1].point)

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        positions.reserveCapacity((count + 1) * 2)

        for i in 0...count {
            let sample = samples[i % count]
            let u = i == count ? 1 : lengths[i] / perimeter
            let outer = sample.point + sample.outward * half
            let inner = sample.point - sample.outward * half

            positions.append(SIMD3(outer.x, 0, outer.y))
            uvs.append(SIMD2(u, 0))
            positions.append(SIMD3(inner.x, 0, inner.y))
            uvs.append(SIMD2(u, 1))
            normals.append(contentsOf: [SIMD3<Float>(0, 1, 0), SIMD3<Float>(0, 1, 0)])
        }

        var indices: [UInt32] = []
        indices.reserveCapacity(count * 6)
        for i in 0..<count {
            let o0 = UInt32(i * 2), i0 = o0 + 1
            let o1 = UInt32((i + 1) * 2), i1 = o1 + 1
            // 앞면 법선이 +Y가 되는 감기 순서. 뒤집으면 카드를 위에서 볼 때
            // 뒷면만 남는다.
            indices.append(contentsOf: [o0, i0, o1])
            indices.append(contentsOf: [i0, i1, o1])
        }

        return Geometry(
            positions: positions,
            normals: normals,
            textureCoordinates: uvs,
            triangleIndices: indices
        )
    }
}
