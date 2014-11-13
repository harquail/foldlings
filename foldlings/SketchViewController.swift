//
//  SketchViewController.swift
//  foldlings
//
//  Created by nook on 10/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation
import SceneKit

class SketchViewController: UIViewController{
    
    
    
    @IBOutlet var sketchView: SketchView!
    
    @IBAction func CardsButtonClicked(sender: UIButton) {
        
        Archivist.appendSketchToFile(sketchView.sketch)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func EraseButtonClicked(sender: UIButton) {
        sketchView.sketchMode = SketchView.Mode.Erase
    }
    
    @IBAction func CutButtonClicked(sender: UIButton)
    {
        sketchView.sketchMode = SketchView.Mode.Cut
    }
    
    @IBAction func FoldButtonClicked(sender: UIButton)
    {
        sketchView.sketchMode = SketchView.Mode.Fold
    }
    
    @IBAction func TabButtonClicked(sender: UIButton) {
        sketchView.sketchMode = SketchView.Mode.Tab
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "PreviewSegue") {

            let viewController:GameViewController = segue.destinationViewController as GameViewController
            
            viewController.setButtonBG(sketchView.previewImage())
            viewController.laserImage = sketchView.bitmap(true)
//            viewController.
            // pass data to next view
        }
    }
    
    
    
}