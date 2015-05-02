//
//  SketchViewController.swift
//  foldlings
//
//

import Foundation
import SceneKit

class SketchViewController: UIViewController, UIPopoverPresentationControllerDelegate{
    
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
        let gesture = sender as! UITapGestureRecognizer
        
        var touchPoint = gesture.locationInView(sketchView)
        
        if let fs = sketchView.sketch.features{
            println(sketchView.path)
            
            // evaluate newer features first
            // but maybe what we should really do is do depth first search
            let fsBackwards = fs.reverse()
            
            for f in fsBackwards{
                
                //detect tapped feature
                if(f.boundingBox()!.contains(touchPoint)){
                    
                    // if freeform shape, reject points outside bounds
                    if let freeForm = f as? FreeForm{
                        if(!freeForm.path!.containsPoint(touchPoint)){
                            continue
                        }
                    }
                    
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
                    
                    
                    sketchView.statusLabel.text = "TOUCHED FEATURE: \(f)"
                    return
                }
                
            }
            
        }
        sketchView.statusLabel.text = ""
    }
    
    
    /// do the thing specified by the option
    func handleTapOption(feature:FoldFeature, option:FeatureOption){
        
        switch option{
        case .AddFolds :
            break
        case .DeleteFeature :
            feature.removeFromSketch(self.sketchView.sketch)
            //            feature.parent?.healFold(feature.drivingFold!)
            self.sketchView.sketch.refreshFeatureEdges()
            self.sketchView.forceRedraw()
        case .MoveFolds:
            sketchView.sketch.tappedFeature = feature
            feature.activeOption = .MoveFolds;
        }
        
    }
    
    override func viewDidLoad() {
        
        box.image = UIImage(named:"box-fold-selected-icon")
        let singleFingerTap = UITapGestureRecognizer(target: self,action: "handleTap:")
        sketchView.addGestureRecognizer(singleFingerTap)
        
        let draggy = UIPanGestureRecognizer(target: self,action: "handlePan:")
        sketchView.addGestureRecognizer(draggy)
        
    }
    
    
    // TODO: Should store index elsewhere, possibly in sketch
    @IBAction func CardsButtonClicked(sender: UIButton) {
        Flurry.logEvent("moved to 3d land")
        
        let arch = ArchivedEdges(sketch:sketchView.sketch)
        ArchivedEdges.setImage(sketchView.sketch.index, image:sketchView.bitmap(grayscale: false, circles: false))
        arch.save()
        sketchView.hideXCheck()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    //box fold button selected
    // #TODO: flurry logging here
    @IBAction func boxFold(sender: UIBarButtonItem) {
        resetButtonImages()
        sketchView.sketchMode = .BoxFold
        sender.image =  UIImage(named:"box-fold-selected-icon")
    }
    
    //box free-form selected
    @IBAction func freeForm(sender: UIBarButtonItem) {
        resetButtonImages()
        sketchView.sketchMode = .FreeForm
        sender.image =  UIImage(named:"freeform-selected-icon")
    }
    
    @IBAction func vFold(sender: UIBarButtonItem) {
        resetButtonImages()
        sketchView.sketchMode = .VFold
        sender.image =  UIImage(named:"vfold-selected-icon")
    }
    
    @IBAction func polygon(sender: UIBarButtonItem) {
        resetButtonImages()
        sketchView.sketchMode = .Polygon
        sender.image =  UIImage(named:"polygon-selected-icon")
    }
    
    func resetButtonImages(){
        box.image = UIImage(named:"box-fold-icon")
        v.image = UIImage(named:"vfold-icon")
        free.image = UIImage(named:"freeform-icon")
        polygon.image = UIImage(named:"polygon-icon")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "PreviewSegue") {
            
            //this retains a reference to the sketch view
            let vew = self.sketchView
            let sketch = self.sketchView.sketch
            
            let img = vew.bitmap(grayscale: false, circles: false)
            let imgNew = img.copy() as! UIImage
            
            let viewController:GameViewController = segue.destinationViewController as! GameViewController
//            
            viewController.setButtonBG(imgNew)
            
            viewController.laserImage = vew.bitmap(grayscale: true)
            viewController.svgString = vew.svgImage()
            viewController.planes = sketch.planes

        }
    }
    // hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func unWindToSketchViewController(segue: UIStoryboardSegue) {
        //nothing goes here
    }
    
    
}