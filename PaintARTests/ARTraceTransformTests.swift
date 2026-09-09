import Foundation
import Testing
@testable import PaintAR

struct ARTraceTransformTests {
    @Test("Acumula a escala entre gestos de pinça")
    func accumulatesScaleAcrossPinchGestures() {
        let firstScale = ARTraceTransform.scale(base: 1, gesture: 2)
        let secondScale = ARTraceTransform.scale(base: firstScale, gesture: 2)

        #expect(firstScale == 2)
        #expect(secondScale == 4)
    }

    @Test("Limita a escala nos valores mínimo e máximo")
    func clampsScaleToSupportedRange() {
        #expect(ARTraceTransform.scale(base: 1, gesture: 0.01) == 0.05)
        #expect(ARTraceTransform.scale(base: 4, gesture: 2) == 5)
    }

    @Test("Acumula e normaliza a rotação entre gestos")
    func accumulatesAndNormalizesRotation() {
        let firstRotation = ARTraceTransform.rotation(
            base: 0,
            gesture: .pi * 0.75
        )
        let secondRotation = ARTraceTransform.rotation(
            base: firstRotation,
            gesture: .pi * 0.75
        )

        #expect(abs(secondRotation + (.pi * 0.5)) < 0.0001)
        #expect(secondRotation >= -.pi)
        #expect(secondRotation <= .pi)
    }
}
