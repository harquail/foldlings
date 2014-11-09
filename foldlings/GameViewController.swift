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
    
    
    @IBOutlet var backToSketchButton: UIButton!
    
    @IBAction func SketchViewButton(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func printButton (sender: UIButton){
        
        
        let activityViewController = UIActivityViewController(activityItems: [bgImage], applicationActivities: nil)
        activityViewController.popoverPresentationController!.sourceView = self.view
        //should be this:
        //        [UIActivityTypeMail, UIActivityTypeSaveToCameraRoll, UIActivityTypePrint]
        activityViewController.excludedActivityTypes = [UIActivityTypeAssignToContact]
        self.presentViewController(activityViewController, animated: true, completion: nil)
        
    }
    
    
    // Make fake graph that follows the rules:
    // take edges and adjacency lists
    // search through and make planes
    // put planes in a list
    // send list to another thing
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
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
//        let offTopLeft = CGPointMake(0.1, self.view.bounds.height/2*0.01 + 0.1)
        
        
        let topLeft = CGPointMake(self.view.bounds.width*0.01, self.view.bounds.height/2*0.01)
        let bottomLeft = CGPointMake(self.view.bounds.width*0.01, 0)
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
        
//        println(path)

        path.appendPath(path2)
        path.appendPath(path3)
        path.appendPath(path4)
//        path.closePath()
        
       path =  sanitizePath(path)

        
        
        let awkwardTestNode = nodeFromPath(path)
        
        // TODO: fix magic numbers
        awkwardTestNode.position.x -= 3.9
        awkwardTestNode.position.y -= 3.0
        awkwardTestNode.position.z -= 4.5
        
        
        let zeroDegrees =  Float(0.0*M_PI)
        let ninetyDegrees = Float(0.5*M_PI)
        
        //set rotation to start angle
        awkwardTestNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w:zeroDegrees)
        scene.rootNode.addChildNode(awkwardTestNode)
        awkwardTestNode.addAnimation(rotationAnimation(zeroDegrees, endAngle: ninetyDegrees), forKey: "spin around")
        
        // retrieve the SCNView
        let scnView = self.view as SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()
        
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
    
    func nodeFromPath(path:UIBezierPath) -> SCNNode{
        
        let node = SCNNode()
//                let awkwardRectangle : UIBezierPath = UIBezierPath(rect: CGRectMake(0, 0, self.view.bounds.width*0.01, self.view.bounds.height/2*0.01))
        
        
//        0, 0, self.view.bounds.width*0.01, self.view.bounds.height/2*0.01

        
        
        //            ))
        let shape = SCNShape(path: path, extrusionDepth: 0)
        let white = SCNMaterial()
        white.diffuse.contents = UIColor.whiteColor()
        white.doubleSided = true
        
        node.geometry = shape
        node.geometry?.firstMaterial = white
        
        return node
    }
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func setButtonBG(image:UIImage){
        
        //        UIImage *originalImage = [UIImage imageNamed:@"myImage.png"];
        // scaling set to 2.0 makes the image 1/2 the size.
        //        let scaledImage = UIImage(CGImage: image.CGImage,
        //    scale:(image.scale * 3),
        //        orientation:(image.imageOrientation));
        
        bgImage = image;
        
        
        //        self.backToSketch.
        
    }
    
    // remove kCGPathElementMoveToPoint
    func sanitizePath(path:UIBezierPath) -> UIBezierPath{
        
        let elements = path.getPathElements()
//
//        var bezierPoints = [CGPoint]();
//        var subdivPoints = [CGPoint]();
//        
//        var index:Int = 0
        let els = elements as [CGPathElementObj]
        var outPath = UIBezierPath()

        var priorPoint:CGPoint = els[0].points[0].CGPointValue()
        var nextPoint:CGPoint = els[0].points[0].CGPointValue()
        var priorPath:CGPathElementObj = els[0]
        var currPath:CGPathElementObj = els[0]
        
        outPath.moveToPoint(els[0].points[0].CGPointValue())

        for (var i = 1; i < els.count; i++) {
            currPath = els[i]
            switch (currPath.type.value) {
            case kCGPathElementMoveToPoint.value:
                println("moveToPoint")

                let p = currPath.points[0].CGPointValue()
//                outPath.addLineToPoint(p)

            case kCGPathElementAddLineToPoint.value:
                println("subdiv:addLine")
                let p = currPath.points[0].CGPointValue()
                outPath.addLineToPoint(p)
//                bezierPoints.append(p)
//                let pointsToSub:[CGPoint] = [priorPoint, p]
//                subdivPoints  += subdivide(pointsToSub)
//                priorPoint = p
//                index++
            case kCGPathElementAddQuadCurveToPoint.value:
                println("subdiv: addQuadCurve")
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                outPath.addQuadCurveToPoint(p1, controlPoint: p2)
//                bezierPoints.append(p1)
//                bezierPoints.append(p2)
//                priorPoint = p2
//                index += 2
            case kCGPathElementAddCurveToPoint.value:
                println("subdiv: addCurveToPoint")
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                let p3 = currPath.points[2].CGPointValue()
                outPath.addCurveToPoint(p1, controlPoint1: p2, controlPoint2: p2)
//                bezierPoints.append(p1);
//                bezierPoints.append(p2);
//                bezierPoints.append(p3);
//                let pointsToSub:[CGPoint] = [priorPoint, p1, p2, p3]
//                subdivPoints  += subdivide(pointsToSub)
//                priorPoint = p3
//                index += 3
            default:
                println("other: \(currPath.type.value)")
            }
        }
        println(outPath)
//        outPath.closePath()

        return outPath
        
    }
    
//    func pathFromElements(elements:[CGPathElementObj]) -> UIBezierPath{
//        
//        cgpathadd
//        
//    
//    }
    
}
