//
//  AboutViewController.swift
//  foldlings
//
// © 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import UIKit

class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Flurry.logEvent("about viewed")

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func CloseButton(sender: UIButton) {
       self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    private func playVideo(named:String, fromRect:CGRect) {
        let myPlayer = Tutorial.video(named)
        let aPopover =  UIPopoverController(contentViewController: myPlayer)
        aPopover.backgroundColor = UIColor.whiteColor()
        aPopover.presentPopoverFromRect(fromRect, inView: view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
    }
    
    @IBAction func boxButton(sender: UIButton){
        playVideo("boxfold-tutorial",fromRect: sender.frame)
    }
    
    @IBAction func freeFormButton(sender: UIButton){
        playVideo("freeform-tutorial",fromRect: sender.frame)
    }
    
    @IBAction func vFoldButton(sender: UIButton){
        playVideo("vfold-tutorial",fromRect: sender.frame)

    }
    
    @IBAction func polygonButton(sender: UIButton){
        playVideo("polygon-tutorial",fromRect: sender.frame)

    }

}
