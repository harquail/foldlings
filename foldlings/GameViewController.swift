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
    var theOneSphere = SCNNode()

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
        makeScene()
        
    }

    /// this runs every graphics update and can be used to animate stuffs
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval)
    {
        
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
        ambientLightNode.light!.color = UIColor.lightGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        scene.physicsWorld.gravity.y = 0.0
        
        // main loop for defining plane things
        // add each plane to the scene
        for (i, plane) in enumerate(planes.planes) {
            
            plane.clearNode()
            
            var parent = scene.rootNode
            // if plane is a hole, it's parent should be the plane that contains it
            if(plane.kind == Plane.Kind.Hole) {
                
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
        if var topPlane = planes.topPlane {
            createPlanesBFS(topPlane)
        }
        
        // make bottomPlane manually
        if var bottomPlane = planes.bottomPlane {
            let bottomPlaneNode = bottomPlane.lazyNode()
            let masterSphere = parentSphere(bottomPlane, node:bottomPlaneNode, bottom: false)
            scene.rootNode.addChildNode(masterSphere)
            masterSphere.addChildNode(bottomPlaneNode)
            undoParentTranslate(masterSphere, child: bottomPlaneNode)
            bottomPlaneNode.addAnimation(fadeIn(), forKey: "fade in")
        }
        
        // retrieve the SCNView
        let scnView = self.view as SCNView
        scnView.delegate = self
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = false
        
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
    
    
    ///breadth first search
    /// walk tree, save path, record fold and hill or valley, place hinge into visited
    func createPlanesBFS(plane:Plane) {
        
        let bottom = planes.bottomPlane!
        visited.append(bottom) // never consider bottom
        
        
        let colors:[UIColor] = [
            UIColor(hue: 1.0, saturation: 1.0, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.75, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.50, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.25, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
            UIColor(hue: 1.0, saturation: 0.0, brightness: 1.0, alpha: 0.8)
        ]
        
        //new queue
        var graphQueue: Queue<Plane> = Queue<Plane>()
        
        //queue a starting plane
        graphQueue.enQueue(plane)
        
        var level = 0
        var hill = false
        var lastSphere : SCNNode = scene.rootNode
        
        while(!graphQueue.isEmpty()) {
            println("level: \(level)")

            //traverse the next queued vertex
            let nplane = graphQueue.deQueue() as Plane!
            let nplanenode = nplane.lazyNode()
            let nsphere = parentSphere(nplane, node:nplanenode, bottom: (level == 0))
            
            //TODO: check undoParentTranslate look at convertPosition for Node
            nsphere.addChildNode(nplanenode)
            undoParentTranslate(nsphere, child: nplanenode) //imp
            lastSphere.addChildNode(nsphere)
            undoParentTranslate(lastSphere, child: nsphere) //imp

            
            let m = SCNMaterial()
            m.diffuse.contents = colors[level]
            nplanenode.geometry?.firstMaterial = m
            nsphere.geometry?.firstMaterial = m

            // different based on orientation
            if hill {
                nsphere.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegreesNeg), forKey: "anim")
            } else {
                nsphere.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegrees), forKey: "anim")
            }

            //add unvisited  planes
            for neighborPlane in planes.adjacency[nplane]! {
                if !contains(visited, neighborPlane) {
                    println("adding plane to queue..")
                    graphQueue.enQueue(neighborPlane)
                }
            }

            lastSphere = nsphere
            level++
            visited.append(nplane)
            hill = !hill
        }
        
        println("graph traversal complete..")
    }
    
    
//    // if plane is second plane, don't add physics body
//    // walk tree, save path, record fold and hill or valley, place hinge into visited
//    func createPlaneTree(plane: Plane, hill:Bool, recurseCount:Int) -> SCNNode?
//    {
//        let bottom = planes.bottomPlane!
//        let colors:[UIColor] = [
//            UIColor(hue: 1.0, saturation: 1.0, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.75, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.50, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.25, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
//            UIColor(hue: 1.0, saturation: 0.0, brightness: 1.0, alpha: 0.8)
//        ]
//        
//        if plane == bottom {
//            println("bottomed out")
//            return nil
//        }
//        if contains(visited, plane) {
//            println("been here")
//            return nil
//        }
//        
//        // functionality here
//        var node = plane.lazyNode()
//        
//        if(plane.kind != .Hole){
//            node.addAnimation(fadeIn(), forKey: "fade in")
//        }
//        var useBottom = (recurseCount == 0)
//        let masterSphere = parentSphere(plane, node:node, bottom: useBottom)
//        plane.masterSphere = masterSphere
//        masterSphere.addChildNode(node)
//        undoParentTranslate(masterSphere, child: node)
//        
//        let m = SCNMaterial()
//        m.diffuse.contents = colors[recurseCount]
//        node.geometry?.firstMaterial = m
//        masterSphere.geometry?.firstMaterial = m
//        
//        // different based on orientation
//        if hill {
////            masterSphere.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegreesNeg), forKey: "anim")
//        } else {
////            masterSphere.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegrees), forKey: "anim")
//        }
//        
//        
//        var adj = planes.adjacency[plane]!
//        visited.append(plane)
//        // loop through the adj starting with top plane
//        for p in adj
//        {
//            let rc = recurseCount + 1
//            if let childSphere = createPlaneTree(p, hill:!hill, recurseCount:rc) {
//                // child hasn't reached bottom so do something to it
//                masterSphere.addChildNode(childSphere)
//                undoParentTranslate(masterSphere, child: childSphere)
//
//            }
//        }
//        return masterSphere
//    }
    
    
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
            scene.rootNode.addChildNode(makeSphere(atPoint: anchorStart))
            scene.rootNode.addChildNode(makeSphere(atPoint: anchorEnd))
        }
    }

    
    private func parentSphere(plane:Plane, node:SCNNode, bottom:Bool = true) -> SCNNode {
        
        var edge:Edge
        
        if(bottom){
            edge = plane.bottomFold()!
        }
        else{
            edge = plane.topFold()!
        }
        
        let startPoint = SCNVector3Make(makeMid(edge.start.x, b:edge.end.x), Float(edge.start.y), Float(0.0))
        let anchorStart = node.convertPosition(startPoint, toNode: nil)
        let masterSphere = makeSphere(atPoint: anchorStart)
        
//        let m = SCNMaterial()
//        m.diffuse.contents = UIColor.clearColor()
//        masterSphere.geometry?.firstMaterial = m

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
    
    func makeMid(a:CGFloat, b:CGFloat) -> Float{
        return Float((a + b)/2.0)
    }
    
    
}