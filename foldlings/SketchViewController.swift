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
    
    // TODO: Should store index elsewhere, possibly in sketch
    @IBAction func CardsButtonClicked(sender: UIButton) {
        let arch = ArchivedEdges(adj: sketchView.sketch.adjacency, edges: sketchView.sketch.edges, tabs: sketchView.sketch.tabs, index:0, name:"archive")
        arch.save()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func EraseButtonClicked(sender: UIButton) {
        
        //TODO: Animate frame movement
        selected.frame = CGRectMake(105, 885, selected.frame.width, selected.frame.height)
        
        sketchView.sketchMode = SketchView.Mode.Erase
    }
    
    @IBAction func CutButtonClicked(sender: UIButton)
    {
        selected.frame = CGRectMake(306, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Cut
    }
    
    @IBAction func FoldButtonClicked(sender: UIButton)
    {
        selected.frame = CGRectMake(203, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Fold
    }
    
    @IBAction func TabButtonClicked(sender: UIButton) {
        selected.frame = CGRectMake(399, 885, selected.frame.width, selected.frame.height)
        sketchView.sketchMode = SketchView.Mode.Tab
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
    
    
    
}