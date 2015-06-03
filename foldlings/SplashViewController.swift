// SplashViewController.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import Foundation
import UIKit

class SplashViewController: UIViewController, UIAlertViewDelegate {

    var sketchName = "place holder from splash"
    
    @IBOutlet var collectionOfFoldlings: CollectionOfFoldlings!
    
    // show dialog box to name sketch
    @IBAction func newButtonPressed(sender: AnyObject) {
        let alert = UIAlertView(title: "Sketch Name", message: "", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "OK")
        alert.alertViewStyle = UIAlertViewStyle.PlainTextInput
        alert.tag = 1
        alert.show()
    }
    
    // hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // when ok is pressed, on sketch naming dialog, make a new sketch
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if (alertView.tag == 1) {
            if (buttonIndex == 1) {
                let textField = alertView.textFieldAtIndex(0)
                transitionToFreshSketch(textField!.text)
            }
            
        }
    }
    
    // make a new sketch
    func transitionToFreshSketch(name:String){
        println("transitioned to fresh sketch")
        sketchName = name
        let story = UIStoryboard(name: "Main", bundle: nil)
        
        self.performSegueWithIdentifier("newSketchSegue", sender: self)

    }
    

    // when moving to a new sketch
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "newSketchSegue") {
                println("Sender \(sender)")
            
            let viewController = segue.destinationViewController as! SketchViewController
            viewController.name = sketchName
            
            // set index to one greater than last saved
            if let archEdges = ArchivedEdges.archivedSketchNames(){
                            let index = archEdges.count
                viewController.index = index
            }

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let names = ArchivedEdges.archivedSketchNames()
    }
    
    //hides nav bar on splash screen
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // refresh the cards
        collectionOfFoldlings.reloadData()
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        super.viewWillDisappear(animated)
    }
    
}

