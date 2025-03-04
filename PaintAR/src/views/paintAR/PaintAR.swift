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
        return ViewController(canvas: canvas) // Passe o canvas para o ViewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}

class ViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var selectedNode: SCNNode?
    var canvasView: PKCanvasView
    var planeNode: SCNNode?
    
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
        
        addCanvasPlane()
        addPinchGesture()
        addPanGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func addCanvasPlane() {
        // Obtém as dimensões do desenho
        let drawingBounds = canvasView.bounds
        let drawingWidth = drawingBounds.width
        let drawingHeight = drawingBounds.height
        
        // Mantém a proporção no AR
        let aspectRatio = drawingWidth / drawingHeight
        let arWidth: CGFloat = 0.3  // Define um tamanho base
        let arHeight: CGFloat = arWidth / aspectRatio  // Calcula altura proporcional
        
        let plane = SCNPlane(width: arWidth, height: arHeight)
        let material = SCNMaterial()
        
        // Gera a textura com o tamanho correto
        let image = canvasView.drawing.image(from: drawingBounds, scale: 1.0)
        material.diffuse.contents = image
        plane.materials = [material]
        
        let node = SCNNode(geometry: plane)
        node.position = SCNVector3(0, 0.1, -0.8)
        
        sceneView.scene.rootNode.addChildNode(node)
        self.planeNode = node // Guarda referência do nó
    }

    
    func addPinchGesture() {
         let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
         sceneView.addGestureRecognizer(pinchGesture)
     }
     
     func addPanGesture() {
         let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
         sceneView.addGestureRecognizer(panGesture)
     }
     
     @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
         guard let node = planeNode else { return }
         
         let scale = Float(gesture.scale)
         node.scale = SCNVector3(scale, scale, scale)
         
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
}
