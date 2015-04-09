//
//  SketchViewController.swift
//  foldlings
//
//

import Foundation
import SceneKit

class SketchViewController: UIViewController, UIPopoverPresentationControllerDelegate{
    
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
            
            // evaluate newer features first
            // but maybe what we should really do is do depth first search
            let fsBackwards = fs.reverse()
            
            for f in fsBackwards{
                
                //delete tapped feature
                if(f.boundingBox()!.contains(touchPoint)){
                    
                    
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
            self.sketchView.sketch.refreshFeatureEdges()
            self.sketchView.forceRedraw()
        }
        
    }
    
    override func viewDidLoad() {
        
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

    
    @IBAction func PlaceholderFeatureButtonClicked(sender:UIButton){
        Flurry.logEvent("slider button clicked")
        sketchView.statusLabel.text = "Drag the shape"
        sketchView.showXCheck()
        selected.frame = CGRectMake(sender.frame.origin.x - 27, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.BoxFold
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "PreviewSegue") {
            
            let viewController:GameViewController = segue.destinationViewController as! GameViewController
            
            let img = sketchView.bitmap(grayscale: false, circles: false)
            let imgNew = img.copy() as! UIImage
            
            viewController.setButtonBG(imgNew)
            
            
            viewController.laserImage = sketchView.bitmap(grayscale: true)
            viewController.svgString = sketchView.svgImage()
            viewController.planes = sketchView.sketch.planes
            viewController.parentButton = sketchView.previewButton
        
            // pass data to next view
        }
    }
    // hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    
}