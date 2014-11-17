//
//  GameViewController.swift
//  foldlings
//
//

import UIKit
import QuartzCore
import SceneKit
import Foundation

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    
    var bgImage:UIImage!
    var laserImage:UIImage!
    var planes:CollectionOfPlanes = CollectionOfPlanes()
    var parentButton = UIButton()
    let scene = SCNScene()

    //constants
    let zeroDegrees =  Float(0.0*M_PI)
    let ninetyDegrees = Float(0.5*M_PI)
    let ninetyDegreesNeg = Float(-0.5*M_PI)
    let fourtyFiveDegrees = Float(0.25*M_PI)

    var visited: [Plane] = []
    
    @IBOutlet var backToSketchButton: UIButton!
    
    /// back to sketch button clicked
    @IBAction func SketchViewButton(sender: UIButton) {
        parentButton.setBackgroundImage(self.previewImage(), forState: UIControlState.Normal)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
        
    @IBAction func printButton (sender: UIButton){
        popupShare(bgImage, xposition:273)
    }
    
    @IBAction func laserButton (sender: UIButton){
        popupShare(laserImage, xposition:100)
    }
    
    
    /// pop up sharing dialog with an image to share
    /// the send to printer/laser cutter buttons
    func popupShare(image:UIImage, xposition:CGFloat){
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController!.sourceView = self.view
        activityViewController.excludedActivityTypes = [UIActivityTypeAssignToContact]
        let popover = activityViewController.popoverPresentationController!
        popover.sourceView = self.view
        popover.sourceRect = CGRectMake(xposition,(self.view.bounds.height - 110),0,0)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        makeSceneToTestHinges()
        makeScene()
        
    }

    /// this runs every graphics update and can be used to animate stuffs
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval)
    {
        
    }

    
    func makeSceneToTestHinges(){
    
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
   
        //makes a rectangular node for testing
        func rectangularNode(#color:UIColor,origin:CGPoint,zPosition:Float,size:CGSize, #dynamic:Bool)->SCNNode{
            
            let node = SCNNode()
            let shape = SCNShape(path: UIBezierPath(rect: CGRect(origin: origin, size: size)), extrusionDepth: 1)
            
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.doubleSided = true
            
            node.geometry = shape
            node.geometry?.firstMaterial = material
            node.position = SCNVector3Make(node.position.x, node.position.y, node.position.z + zPosition)
            
            let dynamism = dynamic ? SCNPhysicsBodyType.Dynamic: SCNPhysicsBodyType.Kinematic
            node.physicsBody = SCNPhysicsBody(type: dynamism, shape: SCNPhysicsShape(geometry: node.geometry!, options: nil))
        
            return node
        }

        let rootRect = rectangularNode(color: UIColor.redColor(), CGPointMake(0.0, 0.0), 0, CGSizeMake(5, 1), dynamic:false)
        let friend = rectangularNode(color: UIColor.blueColor(), CGPointMake(0.0,1), 0, CGSizeMake(5, 1), dynamic:true)
        let friendofAFriend = rectangularNode(color: UIColor.greenColor(), CGPointMake(0.0,2), 0, CGSizeMake(5, 1), dynamic:true)
        let hinge = SCNPhysicsHingeJoint(bodyA: rootRect.physicsBody!, axisA: SCNVector3Make(1, 0, 0), anchorA: SCNVector3Make(0, -1, 0), bodyB: friend.physicsBody!, axisB: SCNVector3Make(1, 0, 0), anchorB: SCNVector3Make(0, 1, 0))
        
        
//        rootRect.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(90))
        scene.physicsWorld.addBehavior(hinge)
        
        let nodes = [rootRect, friend]
        
        for node in nodes{
            scene.rootNode.addChildNode(node)
        }

        // retrieve the SCNView
        let scnView = self.view as SCNView
        // set the scene to the view
        scnView.scene = scene
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()
    }

    
    func makeScene(){
    
        // create a new scene
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        scene.physicsWorld.gravity.y = 0.0
        
        // main loop for defining plane things
        // add each plane to the scene
        for (i, plane) in enumerate(planes.planes) {
            
            plane.clearNode()
            
            var parent = scene.rootNode
            // if plane is a hole, it's parent should be the plane that contains it
            if(plane.kind == Plane.Kind.Hole) {
            
                println("hole found")
                
                plane.clearNode()
                
                let parentPlane = plane.containerPlane(planes.planes)
                    
                if parentPlane != nil{
                 
                    let n = plane.lazyNode()
                    
                    n.transform = SCNMatrix4Identity
                    n.scale = SCNVector3Make(1.0, 1.0, 1.0)
                    
                    parent = parentPlane!.lazyNode()
                    
                    parent.addChildNode(n)
                
                }
            }
        }

        
        visited = []
        if var topPlaneNode = createPlaneTree(planes.topPlane!, hill: false) {
//            let masterSphere = parentSphere(planes.topPlane!,node: topPlaneNode)
//            planes.topPlane!.masterSphere = masterSphere
//            masterSphere.addChildNode(topPlaneNode)
//            undoParentTranslate(masterSphere, child: topPlaneNode)
//            topPlaneNode.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegrees), forKey: "anim")
            scene.rootNode.addChildNode(topPlaneNode)
        }
        // make bottomPlane manually
        if var bottomPlane = planes.bottomPlane {
            var bottomPlaneNode = bottomPlane.lazyNode()
            let masterSphere = parentSphere(bottomPlane, node:bottomPlaneNode)
            bottomPlane.masterSphere = masterSphere
            masterSphere.addChildNode(bottomPlaneNode)
            undoParentTranslate(masterSphere, child: bottomPlaneNode)
            bottomPlaneNode.addAnimation(fadeIn(), forKey: "fade in")
            showPlaneCorners(bottomPlane, node: bottomPlaneNode)
            scene.rootNode.addChildNode(masterSphere)
        }
        
        // retrieve the SCNView
        let scnView = self.view as SCNView
        scnView.delegate = self
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()

        // back button
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Normal)
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Highlighted)
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Selected)
    }
    
    
    func undoParentTranslate(parent:SCNNode, child:SCNNode)
    {
        child.position = SCNVector3Make(child.position.x - parent.position.x, child.position.y - parent.position.y, child.position.z - parent.position.z)
    }
    
    
    
    // if plane is second plane, don't add physics body
    // walk tree, save path, record fold and hill or valley, place hinge into visited
    func createPlaneTree(plane: Plane, hill: Bool) -> SCNNode?
    {
        let bottom = planes.bottomPlane!
        // call make joint between curr plane and p using Bool
        
        if plane == bottom || contains(visited, plane){
            if plane == bottom {
                println("bottom!")
                return nil
            } else {
                println("already been here")
                return nil
            }
        }
        
        // functionality here
        var node = plane.lazyNode()
        node.addAnimation(fadeIn(), forKey: "fade in")
        showPlaneCorners(plane, node: node)
        
        let masterSphere = parentSphere(plane, node:node)
        plane.masterSphere = masterSphere
        masterSphere.addChildNode(node)
        undoParentTranslate(masterSphere, child: node)
        // different based on orientation
        if plane.orientation == .Vertical {
            masterSphere.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegrees), forKey: "anim")
        } else {
            masterSphere.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegreesNeg), forKey: "anim")
        }
        
        
        var adj = planes.adjacency[plane]!
        visited.append(plane)
        // loop through the adj starting with top plane
        for p in adj
        {
            if let child = createPlaneTree(p, hill: !hill) {
                // child hasn't reached bottom so do something to it
                node.addChildNode(child)
            }
        }
        return masterSphere
    }
    
    
    /// fade in animation makes it less jarring
    func fadeIn() -> CABasicAnimation{
        var fadeIn = CABasicAnimation(keyPath:"opacity");
        fadeIn.duration = 2.0;
        fadeIn.fromValue = 0.0;
        fadeIn.toValue = 1.0;
        return fadeIn
    }
    
    
    /// back and forth rotation animation
    /// this is magical
    /// very sketchy idea of how it works
    func rotationAnimation(startAngle:Float, endAngle:Float) -> CAKeyframeAnimation{
        let anim = CAKeyframeAnimation(keyPath: "rotation")
        anim.duration = 14;
        anim.cumulative = false;
        anim.repeatCount = .infinity;
        
        
        anim.values = [NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(startAngle))),
            NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(endAngle))),
            NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(endAngle))),
            NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(startAngle)))]
        anim.keyTimes = [NSNumber(float: Float(0.0)),
            NSNumber(float: Float(1)),
            NSNumber(float: Float(1.4)),
            NSNumber(float: Float(2.4))]
        anim.removedOnCompletion = false;
        anim.fillMode = kCAFillModeForwards;
        anim.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut),
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)]
        
        return anim
        
    }
    
    
    /// moves the pivot of a node from the top edge to the bottom edge
    /// but it doesn't seem to work
    func changePivot(node:SCNNode){
        
        // take the bounding box
        var minVec = UnsafeMutablePointer<SCNVector3>.alloc(0)
        var maxVec = UnsafeMutablePointer<SCNVector3>.alloc(1)
        if node.getBoundingBoxMin(minVec, max: maxVec) {
            
            //and get the length of each direction
            let distance = SCNVector3(
                x: maxVec.memory.x - minVec.memory.x,
                y: maxVec.memory.y - minVec.memory.y,
                z: maxVec.memory.z - minVec.memory.z)
            
//            node.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
//            https://stackoverflow.com/questions/24734200/swift-how-to-change-the-pivot-of-a-scnnode-object
//            http://ronnqvi.st/3d-with-scenekit/
            
            // LIESSSSS
            node.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
            
            // we have to dealloc the unsafe pointer
            // I hate it
            minVec.dealloc(0)
            maxVec.dealloc(1)
        }
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // sets preview button image
    func setButtonBG(image:UIImage){
        bgImage = image;
    }
    
    func previewImage() -> UIImage{
        // TODO: clear other buttons here too
        self.backToSketchButton.alpha = 0
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 0.0);
        view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: true)
        var img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return img
    }
    
    
    func showNodePivot(node:SCNNode) {
        makeSphere(atPoint: SCNVector3Make(0, 0, 0), inNode:node)
    }
    
    
    /// function to show plane corners and shows how to get the anchor points
    func showPlaneCorners(plane:Plane, node:SCNNode) {
        for edge in plane.edges {
            let startPoint = SCNVector3Make(Float(edge.start.x), Float(edge.start.y), Float(0.0))
            let endPoint = SCNVector3Make(Float(edge.end.x), Float(edge.end.y), Float(0.0))
            let anchorStart = node.convertPosition(startPoint, toNode: scene.rootNode)
            let anchorEnd = node.convertPosition(startPoint, toNode: scene.rootNode)
            makeSphere(atPoint: anchorStart)
            makeSphere(atPoint: anchorEnd)
        }
    }

    
    // TODO: fail gracefully
    private func parentSphere(plane:Plane, node:SCNNode, bottom:Bool = true) -> SCNNode {
        
        var edge:Edge
        
        if(bottom){
            edge = plane.bottomFold()!
        }
        else{
            edge = plane.topFold()!
        }
        
        let startPoint = SCNVector3Make(Float(edge.start.x), Float(edge.start.y), Float(0.0))
        let anchorStart = node.convertPosition(startPoint, toNode: scene.rootNode)
        let masterSphere = makeSphere(atPoint: anchorStart)

        return masterSphere
        
    }


    
    ///makes a little sphere at the given point in world space
    func makeSphere(#atPoint: SCNVector3) -> SCNNode {
        let sphereGeometry = SCNSphere(radius: 0.15)
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.position = atPoint
        return sphereNode
    }

    ///makes a little sphere at the given point in world space
    func makeSphere(#atPoint: SCNVector3, inNode:SCNNode) {
        let sphereGeometry = SCNSphere(radius: 0.15)
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.position = atPoint
        inNode.addChildNode(sphereNode)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "backtoSketchSegue") {
            
            let viewController:SketchViewController = segue.destinationViewController as SketchViewController
            viewController.sketchView.setButtonBG(previewImage())
        }
    }
    
    
}