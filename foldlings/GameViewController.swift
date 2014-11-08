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
        
        
        
        let awkwardTestNode = nodeFromPath(UIBezierPath(rect: CGRectMake(0, 0, self.view.bounds.width*0.01, self.view.bounds.height/2*0.01)))
        
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
        //        let awkwardRectangle : UIBezierPath = UIBezierPath(rect: CGRectMake(0, 0, self.view.bounds.width*0.01, self.view.bounds.height/2*0.01
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
    
}
