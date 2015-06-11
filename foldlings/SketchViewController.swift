//
//  SketchViewController.swift
//
// foldlings
// © 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import Foundation
import SceneKit

class SketchViewController: UIViewController, UIPopoverPresentationControllerDelegate{
    
    var index = 0
    var name = "placeholder"
    var restoredFromSave = false
    
    @IBOutlet var box: UIBarButtonItem!
    @IBOutlet var free: UIBarButtonItem!
    @IBOutlet var v: UIBarButtonItem!
    @IBOutlet var polygon: UIBarButtonItem!
    
    @IBOutlet var sketchView: SketchView!

    @IBOutlet var selected: UIImageView!
    
    @IBAction func checkButtonClicked(sender:UIButton){
    }
    
    @IBAction func xButtonClicked(sender:UIButton){
        
    }
    
    @IBAction func handleLongPress(sender: AnyObject) {
        sketchView.handleLongPress(sender)
    }
    
    
    @IBAction func handlePan(sender: AnyObject) {
        sketchView.handlePan(sender)
    }
    
    @IBAction func handleTap(sender: AnyObject) {
        //set tapped feature to nil, clearing any taps
        sketchView.sketch.tappedFeature = nil

        /// handle polygon taps here, then continue if it didn't happen
        if (sketchView.handleTap(sender)){
            return
        }
        
        let gesture = sender as! UITapGestureRecognizer
        var touchPoint = gesture.locationInView(sketchView)
        println("tapped at: \(touchPoint)")
        
        // get tapped feature
        if let f = self.sketchView.sketch.featureAt(point: touchPoint){
            if let options = f.tapOptions(){
                
                //creates the menu with options
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                
                for option in options{
                    // add a menu item with handler for each option
                    alertController.addAction(UIAlertAction(title: option.rawValue, style: .Default, handler: { alertAction in
                        self.handleTapOption(f, option: option)
                    }))
                    
                }
                
                // presents menu at touchPoint
                alertController.popoverPresentationController?.sourceView = sketchView
                alertController.popoverPresentationController?.delegate = self
                alertController.popoverPresentationController?.sourceRect = CGRectMake(touchPoint.x, touchPoint.y, 1, 1)
                alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up | UIPopoverArrowDirection.Down
                self.presentViewController(alertController, animated: true, completion: nil)
                
            }
        }
    }
    
    
    /// do the thing specified by the option
    func handleTapOption(feature:FoldFeature, option:FeatureOption){
        
        Flurry.logEvent("tap option: \(option.rawValue)")

        
        switch option{
        case .AddFolds :
            break
        case .DeleteFeature :
            //delete feature and redraw
            sketchView.sketch.removeFeatureFromSketch(feature)
            self.sketchView.sketch.getPlanes()
            self.sketchView.forceRedraw()

        case .MoveFolds:
            // toggle moveFolds on
            sketchView.sketch.tappedFeature = feature
            feature.activeOption = .MoveFolds;
            
        // debug cases
        // #TODO: remove on release
        case .PrintEdges:
            print(feature.featureEdges)
        case .PrintPlanes:
            print(feature.featurePlanes)
        case .PrintSketch:
            print(sketchView.sketch)
        case .MovePoints:
            println("implement move points")
        }
        
    }
    
    override func viewDidLoad() {
        
        box.image = UIImage(named:"box-fold-selected-icon")
        let singleFingerTap = UITapGestureRecognizer(target: self,action: "handleTap:")
        sketchView.addGestureRecognizer(singleFingerTap)
        
        let draggy = UIPanGestureRecognizer(target: self,action: "handlePan:")
        sketchView.addGestureRecognizer(draggy)
        sketchView.sketch.name = name
        sketchView.sketch.index = index
        
        let savedMode = NSUserDefaults.standardUserDefaults().objectForKey("mode") as? String ?? "Box Fold"
        sketchView.sketchMode = SketchView.Mode(rawValue:savedMode) ?? .BoxFold
        setSelectedImage(sketchView.sketchMode)
        
        if(restoredFromSave){
            sketchView.sketch = ArchivedEdges.loadSaved(dex: index)
            sketchView.sketch.getPlanes()
            sketchView.forceRedraw()
        }
        self.title = sketchView.sketch.name

    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //each time we leave the view, save the current sketch to s3
        //TODO: probably want to remove or limit this when releasing to many people.  This could be a lot of data
        let uploader = SecretlyUploadtoS3()
        uploader.uploadToS3(sketchView.bitmap(grayscale: false, circles: false),named:sketchView.sketch.name)
        
        NSUserDefaults.standardUserDefaults().setObject(sketchView.sketchMode.rawValue, forKey: "mode")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        let arch = ArchivedEdges(sketch:sketchView.sketch)
        ArchivedEdges.setImage(sketchView.sketch.index, image:sketchView.bitmap(grayscale: false, circles: false))
        arch.save()
        
    }

    // button selections
    @IBAction func boxFold(sender: UIBarButtonItem) {
        sketchView.sketchMode = .BoxFold
        setSelectedImage(.BoxFold)
    }
    
    @IBAction func freeForm(sender: UIBarButtonItem) {
        sketchView.sketchMode = .FreeForm
        setSelectedImage(.FreeForm)
    }
    
    @IBAction func vFold(sender: UIBarButtonItem) {
        sketchView.sketchMode = .VFold
       setSelectedImage(.VFold)
    }
    
    @IBAction func polygon(sender: UIBarButtonItem) {
        sketchView.sketchMode = .Polygon
        setSelectedImage(.Polygon)
    }
    
    func resetButtonImages(){
        box.image = UIImage(named:"box-fold-icon")
        v.image = UIImage(named:"vfold-icon")
        free.image = UIImage(named:"freeform-icon")
        polygon.image = UIImage(named:"polygon-icon")
    }
    
    func setSelectedImage(mode:SketchView.Mode){
        Flurry.logEvent("selected \(mode.rawValue)")
        resetButtonImages()
        switch (mode){
        case .BoxFold:
            box.image = UIImage(named:"box-fold-selected-icon")
        case .FreeForm:
            free.image = UIImage(named:"freeform-selected-icon")
        case .VFold:
            v.image =  UIImage(named:"vfold-selected-icon")
        case .Polygon:
            polygon.image =  UIImage(named:"polygon-selected-icon")
        default:
            break
            
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "PreviewSegue") {
            
            //this retains a reference to the sketch view
            let view = self.sketchView
            let sketch = self.sketchView.sketch
            
            let img = view.bitmap(grayscale: false, circles: false)
            let imgNew = img.copy() as! UIImage
            
            let viewController:GameViewController = segue.destinationViewController as! GameViewController
            
            viewController.setButtonBG(imgNew)
            viewController.laserImage = view.bitmap(grayscale: true)
            viewController.svgString = view.svgImage()
            viewController.planes = sketch.planes
            viewController.name = sketch.name

        }
    }
    // hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func unWindToSketchViewController(segue: UIStoryboardSegue) {
        //nothing goes here, but this function can't be deleted
    }
    
 
    
}