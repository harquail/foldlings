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

    //constants
    let zeroDegrees =  Float(0.0*M_PI)
    let ninetyDegrees = Float(0.5*M_PI)
//    var shareRectangle: CGRect
    
    
    @IBOutlet var backToSketchButton: UIButton!
    
    @IBAction func SketchViewButton(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func printButton (sender: UIButton){
        
        
        popupShare(bgImage, xposition:273)

        
    }
    
    @IBAction func laserButton (sender: UIButton){
        
        popupShare(laserImage, xposition:100)
       
        
    }
    
    
    func popupShare(image:UIImage, xposition:CGFloat){
    
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController!.sourceView = self.view
        activityViewController.excludedActivityTypes = [UIActivityTypeAssignToContact]
        let popover = activityViewController.popoverPresentationController!
        popover.sourceView = self.view
        popover.sourceRect = CGRectMake(xposition,(self.view.bounds.height - 110),0,0)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    
    // Make fake graph that follows the rules:
    // take edges and adjacency lists
    // search through and make planes
    // put planes in a list
    // send list to another thing
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        rect = CGRectMake(0, 0, 1000, 300)
        
        // create a new scene
        let scene = SCNScene()
        
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
        
        
        
        
        
        
        
        
        
        //new stuff
        //TODO: fix
        
        
        let topRight = CGPointMake(0, self.view.bounds.height/2*0.01)
        
        let topLeft = CGPointMake(self.view.bounds.width*0.01, self.view.bounds.height/2*0.01)
        //        let offTopLeft = CGPointMake(self.view.bounds.width*0.01 + 1, self.view.bounds.height/2*0.01 + 1)
        
        let bottomLeft = CGPointMake(self.view.bounds.width*0.01, 0)
        //        let offBottomLeft = CGPointMake(self.view.bounds.width*0.01 + 1, 0)
        
        let bottomRight = CGPointMake(0, 0)
        
        var path = UIBezierPath();
        path.moveToPoint(topLeft)
        path.addLineToPoint(topRight)
        
        let path2 = UIBezierPath();
        path2.moveToPoint(bottomRight)
        path2.addLineToPoint(bottomRight)
        
        let path3 = UIBezierPath();
        path3.moveToPoint(bottomLeft)
        path3.addLineToPoint(bottomLeft)
        
        let path4 = UIBezierPath();
        path4.moveToPoint(topLeft)
        path4.addLineToPoint(topLeft)
        
        var edges = [Edge(start: topLeft, end: topRight, path: path),Edge(start: topRight, end: bottomRight, path: path2),Edge(start: bottomRight, end: bottomLeft, path: path3),Edge(start: bottomLeft, end: topLeft, path: path4)]
        
        
//        
//        func addPlaneToScene(edges:[Edge], parent:SCNNode) -> SCNNode {
//            
//            let plane = Plane(edges: edges)
//            plane.sanitizePath()
//            
//            let node = plane.node()
//            
//            // TODO: fix magic numbers
////            node.position.x -= 3.9
////            node.position.y -= 3.0
////            node.position.z -= 4.5
//            
//            
//            let zeroDegrees =  Float(0.0*M_PI)
//            let ninetyDegrees = Float(0.5*M_PI)
//            
//            //set rotation to start angle
//            node.rotation = SCNVector4(x: 1, y: 0, z: 0, w:zeroDegrees)
//            parent.addChildNode(node)
//            node.addAnimation(fadeIn(), forKey: "fade in")
//            node.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegrees), forKey: "spin around")
//        
//            return node;
//            
//        }
//        
        func addPlaneToScene(plane:Plane, parent:SCNNode) -> SCNNode{
            
//            let plane = Plane(edges: edges)
//            plane.sanitizePath()
//            plane.kind = .Hole
            
            
            // TODO: duplicated code
            let node = plane.node()

            
            if(plane.kind == .Hole){
            println("hole")
            }
            
            // TODO: fix magic numbers
            node.position.x -= 3.9
            node.position.y -= 3.0
            node.position.z -= 4.5
            //set rotation to start angle
//            changePivot(node)
//            node.rotation = SCNVector4(x: 1, y: 0, z: 0, w:ninetyDegrees)
            parent.addChildNode(node)
            node.addAnimation(fadeIn(), forKey: "fade in")
//            node.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegrees), forKey: "spin around")
         
            println(node)
            node.scale = SCNVector3Make(0.01, 0.01, 0.01)
            
            return node;
        }
        
    
        
//        addPlaneToScene(edges, scene.rootNode)

        
        for plane in planes.planes {
        
            addPlaneToScene(plane,scene.rootNode)
            println("plane addded")
            
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
        scnView.backgroundColor = UIColor.darkGrayColor()
        
        // add a tap gesture recognizer
        
        //        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        //        let gestureRecognizers = NSMutableArray()
        //        gestureRecognizers.addObject(tapGesture)
        //        if let existingGestureRecognizers = scnView.gestureRecognizers {
        //            gestureRecognizers.addObjectsFromArray(existingGestureRecognizers)
        //        }
        //        scnView.gestureRecognizers = gestureRecognizers
        
        
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Normal)
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Highlighted)
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Selected)
        
        
    }
    
    
    func fadeIn() -> CABasicAnimation{
        
        var fadeIn = CABasicAnimation(keyPath:"opacity");
        fadeIn.duration = 2.0;
        fadeIn.fromValue = 0.0;
        fadeIn.toValue = 1.0;
        return fadeIn
    }
    
    
    //back and forth rotation animation
    //TODO: fix magic numbers
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
    
    func changePivot(node:SCNNode){
    
    var minVec = UnsafeMutablePointer<SCNVector3>.alloc(0)
    var maxVec = UnsafeMutablePointer<SCNVector3>.alloc(1)
    if node.getBoundingBoxMin(minVec, max: maxVec) {
        
    let distance = SCNVector3(
    x: maxVec.memory.x - minVec.memory.x,
    y: maxVec.memory.y - minVec.memory.y,
    z: maxVec.memory.z - minVec.memory.z)
        
    


    
    // pivots around bottom edge
    node.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
    
    //pivots around top edge
    node.pivot = SCNMatrix4MakeTranslation(0, distance.y, 0)

        println("plane")
        println(distance.x)
        println(distance.y)
        println(distance.z)
        println()

    minVec.dealloc(0)
    maxVec.dealloc(1)
    }
    
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func setButtonBG(image:UIImage){
        
        bgImage = image;
        
    }
    
    
    
}
