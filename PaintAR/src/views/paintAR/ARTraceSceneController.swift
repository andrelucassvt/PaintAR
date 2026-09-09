import ARKit
import PencilKit
import SceneKit
import SwiftUI
import UIKit
import simd

@MainActor
struct ARTraceSceneController: UIViewControllerRepresentable {
    let drawing: PKDrawing
    let opacity: Double
    let isLocked: Bool
    let recenterID: UUID

    func makeUIViewController(context: Context) -> ARTraceViewController {
        ARTraceViewController(drawing: drawing)
    }

    func updateUIViewController(_ viewController: ARTraceViewController, context: Context) {
        viewController.setOpacity(opacity)
        viewController.setLocked(isLocked)
        viewController.recenter(ifNeededFor: recenterID)
    }
}

@MainActor
final class ARTraceViewController: UIViewController {
    private let drawing: PKDrawing
    private let sceneView = ARSCNView(frame: .zero)
    private let coachingOverlay = ARCoachingOverlayView()
    private let defaultPlanePosition = SCNVector3(0, 0.1, -0.8)

    private var planeNode: SCNNode?
    private var baseScale: Float = 1
    private var baseRotation: Float = 0
    private var basePosition = SCNVector3Zero
    private var isLocked = false
    private var currentOpacity: Double = 0.8
    private var lastRecenterID: UUID?

    init(drawing: PKDrawing) {
        self.drawing = drawing
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSceneView()
        configureCoachingOverlay()
        addTracePlane()
        addGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard ARWorldTrackingConfiguration.isSupported else {
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isLightEstimationEnabled = false
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    func setOpacity(_ opacity: Double) {
        currentOpacity = min(max(opacity, 0.1), 1)
        planeNode?.geometry?.firstMaterial?.transparency = CGFloat(currentOpacity)
    }

    func setLocked(_ isLocked: Bool) {
        self.isLocked = isLocked
    }

    func recenter() {
        guard let planeNode else {
            return
        }

        guard let pointOfView = sceneView.pointOfView else {
            planeNode.position = defaultPlanePosition
            return
        }

        let cameraTransform = pointOfView.simdWorldTransform
        let positionInFrontOfCamera = cameraTransform * SIMD4<Float>(0, 0, -0.8, 1)
        planeNode.simdWorldPosition = SIMD3(
            positionInFrontOfCamera.x,
            positionInFrontOfCamera.y,
            positionInFrontOfCamera.z
        )
        planeNode.simdWorldOrientation = pointOfView.simdWorldOrientation
    }

    func recenter(ifNeededFor recenterID: UUID) {
        guard recenterID != lastRecenterID else {
            return
        }

        lastRecenterID = recenterID
        recenter()
    }

    private func configureSceneView() {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.scene = SCNScene()
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling2X
        sceneView.preferredFramesPerSecond = 60

        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureCoachingOverlay() {
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        coachingOverlay.session = sceneView.session
        coachingOverlay.goal = .anyPlane
        coachingOverlay.activatesAutomatically = true

        view.addSubview(coachingOverlay)
        NSLayoutConstraint.activate([
            coachingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coachingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coachingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addTracePlane() {
        let drawingBounds = validDrawingBounds
        let aspectRatio = drawingBounds.width / drawingBounds.height
        let planeWidth: CGFloat = 0.3
        let planeHeight = planeWidth / max(aspectRatio, 0.01)

        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        let material = SCNMaterial()
        material.diffuse.contents = drawing.image(from: drawingBounds, scale: 1)
        material.isDoubleSided = true
        material.transparency = CGFloat(currentOpacity)
        plane.materials = [material]

        let node = SCNNode(geometry: plane)
        node.position = defaultPlanePosition
        sceneView.scene.rootNode.addChildNode(node)
        planeNode = node
    }

    private var validDrawingBounds: CGRect {
        let bounds = drawing.bounds

        guard !bounds.isNull, bounds.width > 0, bounds.height > 0 else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }

        return bounds
    }

    private func addGestures() {
        sceneView.addGestureRecognizer(
            UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        )
        sceneView.addGestureRecognizer(
            UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        )
        sceneView.addGestureRecognizer(
            UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        )
        sceneView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        )
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let planeNode, !isLocked else {
            return
        }

        switch gesture.state {
        case .began:
            baseScale = planeNode.scale.x
        case .changed:
            let scale = ARTraceTransform.scale(
                base: baseScale,
                gesture: Float(gesture.scale)
            )
            planeNode.scale = SCNVector3(scale, scale, scale)
        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let planeNode, !isLocked else {
            return
        }

        switch gesture.state {
        case .began:
            basePosition = planeNode.position
        case .changed:
            let translation = gesture.translation(in: sceneView)
            planeNode.position = SCNVector3(
                basePosition.x + Float(translation.x) / 500,
                basePosition.y - Float(translation.y) / 500,
                basePosition.z
            )
        default:
            break
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let planeNode, !isLocked else {
            return
        }

        switch gesture.state {
        case .began:
            baseRotation = planeNode.eulerAngles.z
        case .changed:
            planeNode.eulerAngles.z = ARTraceTransform.rotation(
                base: baseRotation,
                gesture: Float(gesture.rotation)
            )
        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard !isLocked else {
            return
        }

        guard let planeNode,
              let query = sceneView.raycastQuery(
                from: gesture.location(in: sceneView),
                allowing: .estimatedPlane,
                alignment: .any
              ),
              let result = sceneView.session.raycast(query).first else {
            recenter()
            return
        }

        let worldTransform = result.worldTransform
        let surfaceOrientation = simd_quatf(worldTransform)
        let surfaceNormal = simd_act(surfaceOrientation, SIMD3<Float>(0, 1, 0))
        let surfacePosition = SIMD3(
            worldTransform.columns.3.x,
            worldTransform.columns.3.y,
            worldTransform.columns.3.z
        )

        // SCNPlane has a local +Z normal, while a raycast surface uses local +Y.
        planeNode.simdWorldOrientation = surfaceOrientation * simd_quatf(
            angle: -.pi / 2,
            axis: SIMD3<Float>(1, 0, 0)
        )
        planeNode.simdWorldPosition = surfacePosition + surfaceNormal * 0.001
    }
}
