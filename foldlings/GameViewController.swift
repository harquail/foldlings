//
//  GameViewController.swift
//  foldlings
//
//  Created by nook on 10/6/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import Foundation

class GameViewController: UIViewController {
    
    var bgImage:UIImage!
    var laserImage:UIImage!
    var planes:CollectionOfPlanes = CollectionOfPlanes()
    var parentButton = UIButton()
    let scene = SCNScene()

    //constants
    let zeroDegrees =  Float(0.0*M_PI)
    let ninetyDegrees = Float(0.5*M_PI)
    //    var shareRectangle: CGRect
    
    
    @IBOutlet var backToSketchButton: UIButton!
    
    /// back to sketch button clicked
    @IBAction func SketchViewButton(sender: UIButton) {
        
        parentButton.setBackgroundImage(self.previewImage(), forState: UIControlState.Normal)
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
//    @IBAction func CardsButtonClicked(sender: UIButton) {
//        println("CARDS CLICKED")
////        Archivist.appendSketchToFile(sketchView.sketch)
//        self.dismissViewControllerAnimated(true, completion: nil)
//    }
    
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
        
        
        /// subfunction; adds a plane to the scene with a given parent
        func addPlaneToScene(plane:Plane, parent:SCNNode) -> SCNNode{
            
            let node = plane.node()
            
            // move node to where the camera can see it
            node.position.x -= 3.9
            node.position.y += 7.0
            node.position.z -= 4.5
            node.scale = SCNVector3Make(0.01, -0.01, 0.01)
            

            
            // add node to parent (parent's translation/rotation affect this one
            parent.addChildNode(node)

            node.addAnimation(fadeIn(), forKey: "fade in")
            
            //println(node)
            return node;
        }
        
        
        // add each plane to the scene
        for plane in planes.planes {
            // if plane is second plane, don't add physics body
            addPlaneToScene(plane,scene.rootNode)
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
        
        
        // back button
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Normal)
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Highlighted)
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Selected)
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
        anim.values = [NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(startAngle))),NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(endAngle))),NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(endAngle))),NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(startAngle)))]
        anim.keyTimes = [NSNumber(float: Float(0.0)),NSNumber(float: Float(1)),NSNumber(float: Float(1.4)),NSNumber(float: Float(2.4))]
        anim.removedOnCompletion = false;
        anim.fillMode = kCAFillModeForwards;
        anim.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut),CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)]
        
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
            
            
            // pivots around bottom edge
            node.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
            
            //pivots around top edge
//            https://stackoverflow.com/questions/24734200/swift-how-to-change-the-pivot-of-a-scnnode-object
//            http://ronnqvi.st/3d-with-scenekit/
            
            // LIESSSSS
            node.pivot = SCNMatrix4MakeTranslation(0, distance.y/2, 0)
            
            println("plane")
            println(distance.x)
            println(distance.y)
            println(distance.z)
            println()
            
            
            // we have to dealloc the unsafe pointer
            // I hate it
            minVec.dealloc(0)
            maxVec.dealloc(1)
        }
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // sets preview button image
    func setButtonBG(image:UIImage){
        
        bgImage = image;
        
    }
    
    func previewImage() -> UIImage{
//        var sceneView = SCNView()
//        sceneView.scene = scene
////        let image = sceneView.snapshot()
//        let image = self.view.snapshotViewAfterScreenUpdates(false)
//
//        println(image.description)
        
        
        self.backToSketchButton.alpha = 0
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 0.0);
        // [view.layer renderInContext:UIGraphicsGetCurrentContext()]; // <- same result...
        
        view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: true)
//        [viewdrawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
        var img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
//        self.backToSketchButton.alpha = 0

        
        
        return img
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "backtoSketchSegue") {
            
            let viewController:SketchViewController = segue.destinationViewController as SketchViewController
            viewController.sketchView.setButtonBG(previewImage())
            
//            viewController.setButtonBG(sketchView.previewImage())
//            viewController.laserImage = sketchView.bitmap(grayscale: true)
//            viewController.planes = sketchView.sketch.planes
            //            viewController.
            // pass data to next view
        }
    }
    
    
}