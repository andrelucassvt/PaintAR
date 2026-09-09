import SwiftUI
import ARKit
import SceneKit
import PencilKit

struct PaintAR: View {
    let canvas: PKCanvasView
    var body: some View {
        ARViewContainer(canvas: canvas)
    }
}

#Preview {
    PaintAR(canvas: .init())
}

struct ARViewContainer: UIViewControllerRepresentable {
    let canvas: PKCanvasView
    
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController(canvas: canvas)
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}



class ViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var selectedNode: SCNNode?
    var canvasView: PKCanvasView
    var planeNode: SCNNode?
    private var textureCache: UIImage?
    
    init(canvas: PKCanvasView) {
        self.canvasView = canvas
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: view.frame)
        view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.autoenablesDefaultLighting = true
        
        // Performance optimizations
        sceneView.antialiasingMode = .multisampling2X
        sceneView.preferredFramesPerSecond = 60
        
        addCanvasPlane()
        addPinchGesture()
        addPanGesture()
        addRotationGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        configuration.isLightEstimationEnabled = false
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func addCanvasPlane() {
        let drawingBounds = canvasView.bounds
        let drawingWidth = drawingBounds.width
        let drawingHeight = drawingBounds.height
        
        let aspectRatio = drawingWidth / drawingHeight
        let arWidth: CGFloat = 0.3
        let arHeight: CGFloat = arWidth / aspectRatio
        
        let plane = SCNPlane(width: arWidth, height: arHeight)
        let material = SCNMaterial()
        
        // Cache texture generation
        if textureCache == nil {
            textureCache = canvasView.drawing.image(from: drawingBounds, scale: 1.0)
        }
        material.diffuse.contents = textureCache
        material.isDoubleSided = false
        plane.materials = [material]
        
        let node = SCNNode(geometry: plane)
        node.position = SCNVector3(0, 0.1, -0.8)
        
        sceneView.scene.rootNode.addChildNode(node)
        self.planeNode = node
    }

    
    func addPinchGesture() {
         let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
         sceneView.addGestureRecognizer(pinchGesture)
     }
     
    func addPanGesture() {
         let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
         sceneView.addGestureRecognizer(panGesture)
     }
    
    func addRotationGesture() {
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        sceneView.addGestureRecognizer(rotationGesture)
    }
     
     @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
         guard let node = planeNode else { return }
         
         if gesture.state == .changed {
             let scale = Float(gesture.scale)
             node.scale = SCNVector3(scale, scale, scale)
         }
         
         if gesture.state == .ended {
             gesture.scale = 1.0
         }
     }
     
     @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
         guard let node = planeNode else { return }
         
         let translation = gesture.translation(in: sceneView)
         let newX = Float(translation.x) / 500.0
         let newY = Float(-translation.y) / 500.0
         
         node.position.x += newX
         node.position.y += newY
         
         gesture.setTranslation(.zero, in: sceneView)
     }
    
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let node = planeNode else { return }
        
        if gesture.state == .changed {
            node.eulerAngles.z = Float(gesture.rotation)
        }
    }
}
