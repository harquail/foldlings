//
//  FoldPreviewViewController.swift
// foldlings
//
// © 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import UIKit
import QuartzCore
import SceneKit
import Foundation
import MessageUI

class GameViewController: UIViewController, SCNSceneRendererDelegate, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate {
    
    /*************image variables***********/
    var bgImage:UIImage!
    var laserImage:UIImage!
    var svgString: String!
    var name: String!
    var planes:CollectionOfPlanes! //= CollectionOfPlanes()
    var parentButton = UIButton()
    let scene = SCNScene()
    
    /**************constants***************/
    let zeroDegrees =  Float(0.0*M_PI)
    let ninetyDegrees = Float(0.5*M_PI)
    let ninetyDegreesNeg = Float(-0.5*M_PI)
    let fourtyFiveDegrees = Float(0.25*M_PI)
    let fourtyFiveDegreesNeg = Float(-0.25*M_PI)
    let thirtyDegrees = Float(M_PI/6.0)
    let thirtyDegreesNeg = Float(-M_PI/6.0)
    let tenDegrees = Float(M_PI/18.0)
    let tenDegreesNeg = Float(-M_PI/18.0)
    let oneSixtyDegrees = Float(M_PI/1.124)
    
    /*****************scene variables*****************/
    var sceneSphere = SCNNode()
    
    var visited: [Plane] = [Plane]()
    //var notMyChild: [Int:[Plane]] =  [Int : [Plane]]() //recursion level -> list of visited planes
    
    /********************color variables*************/
    var debugColor = false
    let debugColors:[UIColor] = [
        UIColor(hue: 1.0, saturation: 1.0, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 1.0, saturation: 0.75, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 1.0, saturation: 0.50, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 1.0, saturation: 0.25, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 1.0, saturation: 0.1, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 0.5, saturation: 1.0, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 0.5, saturation: 0.75, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 0.5, saturation: 0.50, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 0.5, saturation: 0.25, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 0.5, saturation: 0.1, brightness: 1.0, alpha: 0.8),
        UIColor(hue: 0.5, saturation: 0.0, brightness: 1.0, alpha: 0.8)
    ]
    
    /*****************buttons and gestures*****************/
    
    @IBOutlet var backToSketchButton: UIButton!
    var pinch: UIPinchGestureRecognizer!
    var pan: UIPanGestureRecognizer!
    
    /// back to sketch button clicked
    @IBAction func SketchViewButton(sender: UIButton) {
        Flurry.logEvent("back to 2d land")
        
        parentButton.setBackgroundImage(self.previewImage(), forState: UIControlState.Normal)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func printButton (sender: UIButton){
        popupShare(bgImage, xposition:273)
    }
    
    @IBAction func laserButton (sender: UIButton){
        popupSVGShare(svgString, xposition:100)
    }
    
    
    
    /// pop up sharing dialog with an image to share
    /// the send to printer/laser cutter buttons
    func popupShare(image:UIImage, xposition:CGFloat){
        Flurry.logEvent("printed foldling svg")
        
        //activity view controller to share that image
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // creates thing with options
        activityViewController.popoverPresentationController!.sourceView = self.view
        activityViewController.excludedActivityTypes = [UIActivityTypeAssignToContact]
        let popover = activityViewController.popoverPresentationController!
        popover.sourceView = self.view
        popover.sourceRect = CGRectMake(xposition,(self.view.bounds.height - 110),0,0)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    //creates svg pop-up dialog and sends it to user
    func popupSVGShare (svg: String, xposition: CGFloat){
        let svgData: NSData = svg.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        sendMail(svgData)
    }
    
    // creates mailView controller to send svg to user as attechment
    func sendMail(svgData: NSData) {
        if(MFMailComposeViewController.canSendMail()){
            Flurry.logEvent("mailed foldling svg")
            var mailView = MFMailComposeViewController()
            mailView.mailComposeDelegate = self
            mailView.setSubject("Here is your Pop-up Card")
            mailView.setMessageBody("Please open attachment on a computer connected to a laser cutter", isHTML: false)
            mailView.addAttachmentData(svgData, mimeType: "image/svg+xml", fileName:"\(name).svg")
            
            presentViewController(mailView, animated: true, completion: nil)
        }
    }
    
    // hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "backtoSketchSegue") {
            
            let viewController:SketchViewController = segue.destinationViewController as! SketchViewController
            //            viewController.sketchView.setButtonBG(previewImage())
            
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
    
    // log svgs to s3
    //TODO: probably want to remove or limit this when releasing to many people.  This could be a lot of data
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let uploader = SecretlyUploadtoS3()
        uploader.uploadToS3(svgString,named:"\(name)")
    }
    
    
    @IBAction func handlePinch(recognizer : UIPinchGestureRecognizer)
    {
        var currentAngle = zeroDegrees

        // set animation here
        var nextAngle = 1/(Float(recognizer.scale)/2.0) //+ currentAngle //*Float(180/M_PI)
        
        if (currentAngle + nextAngle) > oneSixtyDegrees {
            currentAngle = oneSixtyDegrees
        }
        
        else if (currentAngle + nextAngle < zeroDegrees){
            currentAngle = zeroDegrees
        }
        
        else
        { // should be between 0 and 160
            currentAngle = currentAngle + nextAngle
            // go through list of planes and add animation
            for plane in planes.planes
            {
                
                if plane.masterSphere != nil
                {
                    // determine how the plane bends (backwards/forwards)
                    if plane.NegNinety
                    {
                        plane.masterSphere!.rotation = SCNVector4(x: 1, y: 0, z: 0, w: -currentAngle)
                    }
                    else
                    {
                        plane.masterSphere!.rotation = SCNVector4(x: 1, y: 0, z: 0, w: currentAngle)
                    }
                    
                }
            }
 
            
        }
    }
    
    @IBAction func handlePan(recognizer : UIPanGestureRecognizer)
    {
        println("heelllooow")
    }
    /**************************Create the 3d scene***********************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeScene()
    }
    
    
    func makeScene(){
        // create a new scene
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        scnView.delegate = self
        
        // configure the view
        scnView.backgroundColor = UIColor.whiteColor()
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        
        // create and add a light to the scene
        //        let lightNode = SCNNode()
        //        lightNode.light = SCNLight()
        //        println(lightNode)
        //        lightNode.light!.type = SCNLightTypeOmni
        //        lightNode.light!.color = UIColor.whiteColor()
        //        lightNode.light!.attenuationStartDistance = 100
        //        lightNode.light!.attenuationEndDistance = 1000
        //        lightNode.position = SCNVector3(x: 0, y: 0, z: 10)
        //        scene.rootNode.addChildNode(lightNode)
        //        // create and add an ambient light to the scene
        //        let ambientLightNode = SCNNode()
        //        ambientLightNode.light = SCNLight()
        //        ambientLightNode.light!.type = SCNLightTypeAmbient
        //        ambientLightNode.light!.color = UIColor.whiteColor()
        //        scene.rootNode.addChildNode(ambientLightNode)
        
        scene.physicsWorld.gravity.y = 0.0
        
        //create the sceneShpere
        scene.rootNode.addChildNode(sceneSphere)
        sceneSphere.position.y = sceneSphere.position.y + 4.0
        
        
        //sceneSphere.orientation.y = tenDegreesNeg - (tenDegreesNeg/2)
        sceneSphere.rotation = SCNVector4(x: 1, y: -0.25, z: -0.25, w: fourtyFiveDegreesNeg + tenDegreesNeg + tenDegreesNeg + tenDegreesNeg)
        
        visited = []
        //notMyChild = [Int: [Plane]]()
        //printTree(planes.masterTop)
        if var topPlaneSphere = createPlaneTree(planes.masterTop!, hill: false, recurseCount: 0) {
            sceneSphere.addChildNode(topPlaneSphere)
        }
        
        
        // make bottomPlane manually
        // get bottomPlane from planes list
        if var bottomPlane = planes.masterBottom {
            //  put a check here for !nil node
            var bottomPlaneNode = bottomPlane.node
            var translate = false
            
            if bottomPlane.node == nil{
                bottomPlaneNode = bottomPlane.makeNode()
                translate = true
            }
            
            let masterSphere = parentSphere(bottomPlane, node:bottomPlaneNode!, bottom: false)
            sceneSphere.addChildNode(masterSphere)
            masterSphere.addChildNode(bottomPlaneNode!)
            
            if (translate){
                undoParentTranslate(masterSphere, child: bottomPlaneNode!)
            }
            bottomPlaneNode!.addAnimation(fadeIn(), forKey: "fade in")
        }
        
        
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = SCNAntialiasingMode.Multisampling4X
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = false
        
        
        // add pinch motion to control animation
        //view.userInteractionEnabled = true
        pinch = UIPinchGestureRecognizer(target: self,action: "handlePinch:")
        pan = UIPanGestureRecognizer(target: self,action: "handlePan:")
        //pinch.delegate = self
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(pan)
        
        
        
        // back button
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Normal)
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Highlighted)
        backToSketchButton.setBackgroundImage(bgImage, forState:UIControlState.Selected)
    }
    
    
    /// this undoes any translation between the child and parent
    func undoParentTranslate(parent:SCNNode, child:SCNNode)
    {
        child.position = SCNVector3Make(child.position.x - parent.position.x, child.position.y - parent.position.y, child.position.z - parent.position.z)
        
    }
    
    func printTree(plane: Plane){
        println("parent: \(plane.topEdge)")
        println("children")
        plane.children.map({println($0.topEdge)})
        for p in plane.children{
            printTree(p)
        }
    }
    
    
    
    // if plane is second plane, don't add physics body
    // walk tree, save path, record fold and hill or valley, place hinge into visited
    func createPlaneTree(plane: Plane, hill: Bool, recurseCount:Int)-> SCNNode?
    {
        var translate = false
        
        // base case if bottom
        if plane.masterBottom {
            return nil
        }
        // base case already visited or going back up
        if contains(visited, plane) {
            return nil
        }
        
        // put a check here for !nil node
        var node = plane.node
        
        if plane.node == nil{
            node = plane.makeNode()
            translate = true
        }
        
        
        // add fade-in key for holes
        if(plane.kind != .Hole){
            node!.addAnimation(fadeIn(), forKey: "fade in")
        }
        
        var useBottom = (recurseCount == 0)//check if we hit top plane
        let masterSphere = parentSphere(plane, node:node!, bottom: useBottom)
        plane.masterSphere = masterSphere
        masterSphere.addChildNode(node!)
        
        if (translate){
            undoParentTranslate(masterSphere, child: node!)
        }
        
        let m = SCNMaterial()
        if debugColor {
            m.diffuse.contents = debugColors[recurseCount]
        } else {
            m.diffuse.contents = plane.color
        }
        node!.geometry?.firstMaterial = m

        if hill{
            // set to neg90
            plane.NegNinety = true
        }
        
        
        var children = plane.children
        visited.append(plane)

        // loop through the adj starting with top plane
        for p in children
        {
            let rc = recurseCount + 1
            if let childSphere = createPlaneTree(p, hill:!hill, recurseCount:rc) {
                // child hasn't reached bottom so do something to it
                masterSphere.addChildNode(childSphere)
                if (translate){
                    undoParentTranslate(masterSphere, child: childSphere)
                }
            }
        }
        return masterSphere
        
        
    }
    
    ///returns a list from dict including all previous levels up to but including the one
    func flattenUntil(adj: [Int:[Plane]], level:Int) -> [Plane] {
        var list = [Plane]()
        for (k,v) in adj
        {
            if k < level-1 {
                list = list.union(v)
            }
        }
        return list
    }
    
    
    //
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
    
    // this determines the parent sphere for the plane
    private func parentSphere(plane:Plane, node:SCNNode, bottom:Bool = true) -> SCNNode {
        
        var edge:Edge
        
        if(bottom){// TODO:confused
            //println("bottom/top: \(plane.topEdge)")
            edge = plane.bottomEdge
        }
        else{
            edge = plane.topEdge
        }
        
        let startPoint = SCNVector3Make(Float(makeMid(edge.start.x, edge.end.x)), Float(edge.start.y), Float(0.0))
        let anchorStart = node.convertPosition(startPoint, toNode: nil)
        let masterSphere = makeSphere(atPoint: anchorStart)
        
        let m = SCNMaterial()
        m.diffuse.contents = UIColor.clearColor()
        masterSphere.geometry?.firstMaterial = m
        
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
    
    
    /***********************animation*************************/
    
    /// back and forth rotation animation
    /// this is magical
    /// very sketchy idea of how it works
    func rotationAnimation(startAngle:Float, endAngle:Float) -> CAKeyframeAnimation{
        let anim = CAKeyframeAnimation(keyPath: "rotation")
        anim.duration = 14;
        anim.cumulative = false;
        //anim.repeatCount = .infinity;
        anim.values = [
            NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(startAngle))),
            NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(endAngle))),
            NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(endAngle))),
            NSValue(SCNVector4: SCNVector4(x: 1, y: 0, z: 0, w: Float(startAngle)))]
        anim.keyTimes = [
            NSNumber(float: Float(0.0)),
            NSNumber(float: Float(1)),
            NSNumber(float: Float(1.4)),
            NSNumber(float: Float(2.4))]
        anim.removedOnCompletion = false;
        anim.fillMode = kCAFillModeForwards;
        anim.timingFunctions = [
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut),
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)]
        
        return anim
        
    }
    
    /// fade in animation makes it less jarring
    func fadeIn() -> CABasicAnimation{
        var fadeIn = CABasicAnimation(keyPath:"opacity");
        fadeIn.duration = 2.0;
        fadeIn.fromValue = 0.0;
        fadeIn.toValue = 1.0;
        return fadeIn
    }
    
    
    
    
}