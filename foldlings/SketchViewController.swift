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
}