//
//  SketchViewController.swift
//  foldlings
//
//

import Foundation
import SceneKit

class SketchViewController: UIViewController{
    
    
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
        sketchView.handlePan(sender)

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
    @IBAction func EraseButtonClicked(sender: UIButton) {
        Flurry.logEvent("erase button clicked")

        //TODO: Animate frame movement
        selected.frame = CGRectMake(sender.frame.origin.x + 12, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Erase
        sketchView.statusLabel.text = "Erase"
        sketchView.hideXCheck()
    }
    
    @IBAction func CutButtonClicked(sender: UIButton)
    {
        Flurry.logEvent("cut button clicked")

        selected.frame = CGRectMake(sender.frame.origin.x, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Cut
        sketchView.statusLabel.text = "Cut"
        sketchView.hideXCheck()
    }
    
    @IBAction func FoldButtonClicked(sender: UIButton)
    {
        Flurry.logEvent("fold button clicked")
        
        selected.frame = CGRectMake(sender.frame.origin.x, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Fold
        sketchView.statusLabel.text = "Fold"
        sketchView.hideXCheck()
    }
    
    @IBAction func TabButtonClicked(sender: UIButton) {
        Flurry.logEvent("tab button clicked")

        selected.frame = CGRectMake(sender.frame.origin.x - 27, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Tab
        sketchView.statusLabel.text = "Tab"
        sketchView.hideXCheck()

    }
    
    @IBAction func MirrorButtonClicked(sender: UIButton) {
        Flurry.logEvent("mirror button clicked")
        sketchView.statusLabel.text = "Select a fold to mirror across"
        sketchView.showXCheck()
        
        selected.frame = CGRectMake(sender.frame.origin.x - 27, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Mirror
    }

    @IBAction func TrackButtonClicked(sender: UIButton) {
        Flurry.logEvent("track button clicked")
        sketchView.statusLabel.text = "Select a cut"
        sketchView.showXCheck()
        
        selected.frame = CGRectMake(sender.frame.origin.x - 27, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Track
    }
    
    @IBAction func SliderButtonClicked(sender: UIButton) {
        Flurry.logEvent("slider button clicked")
        sketchView.statusLabel.text = "Drag a cut"
        sketchView.showXCheck()
        selected.frame = CGRectMake(sender.frame.origin.x - 27, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Slider
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
            
            let viewController:GameViewController = segue.destinationViewController as GameViewController
            
            let img = sketchView.bitmap(grayscale: false, circles: false)
            let imgNew = img.copy() as UIImage
            
            viewController.setButtonBG(imgNew)
            
            
            viewController.laserImage = sketchView.bitmap(grayscale: true)
            viewController.planes = sketchView.sketch.planes
            viewController.parentButton = sketchView.previewButton
            // pass data to next view
        }
    }
    // hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        sketchView.viewWillAppear()
    }
    
    
    
}