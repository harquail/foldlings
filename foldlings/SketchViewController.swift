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

    @IBOutlet var selected: UIImageView!

    

    @IBAction func EraseButtonClicked(sender: UIButton) {
        
        
//        [UIView beginAnimations:@"MoveView" context:nil];
//        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
//        [UIView setAnimationDuration:0.5f];
//        self.BigView.frame = CGRectMake(newXPoistion, newYPosistion, samewidth, sameheight);
//        [UIView commitAnimations];
        
        
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
            
            viewController.setButtonBG(sketchView.previewImage())
            viewController.laserImage = sketchView.bitmap(grayscale: true)
            viewController.planes = sketchView.sketch.planes
            viewController.parentButton = sketchView.previewButton
//            viewController.
            // pass data to next view
        }
    }
    
    
    
}