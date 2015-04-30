//
//
import Foundation
import UIKit
//import Armchair

class SplashViewController: UIViewController, UIAlertViewDelegate {
    
    @IBOutlet var slider:UISwitch!
    @IBOutlet var slider2:UISwitch!
    
    @IBOutlet var collectionOfFoldlings: CollectionOfFoldlings!
    
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
    
    
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if (alertView.tag == 1) {
            if (buttonIndex == 1) {
                let textField = alertView.textFieldAtIndex(0)
                transitionToFreshSketch(textField!.text)
            }
            
        }
    }
    
    
    func transitionToFreshSketch(name:String){
        
        println("transitioned to fresh sketch")
        //        collectionOfFoldlings.r
        
        let story = UIStoryboard(name: "Main", bundle: nil)
        let vc = story.instantiateViewControllerWithIdentifier("sketchView") as! SketchViewController
        self.presentViewController(vc, animated: true, completion: {
            vc.sketchView.forceRedraw()
        })
        
        
        if let archEdges = ArchivedEdges.archivedSketchNames(){
            
            let index = archEdges.count
            vc.sketchView.sketch.index = index + 1
            vc.sketchView.sketch.name = name
            println(vc.sketchView.sketch.index)
            Flurry.logEvent("new sketch created", withParameters: NSDictionary(dictionary: ["named":name]) as [NSObject : AnyObject])
        }

    }
    
    func toggleMode(switcher:UISwitch,key:String){
        var isOn = switcher.on
        isOn = !isOn
        Flurry.logEvent("\(key) toggled", withParameters: NSDictionary(dictionary: ["on":isOn]) as [NSObject : AnyObject])
        switcher.setOn(isOn, animated: true)
        NSUserDefaults.standardUserDefaults().setBool(isOn, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    override func viewDidLoad() {
//        Armchair.showPromptIfNecessary()
        let on:Bool = NSUserDefaults.standardUserDefaults().boolForKey("proMode")
        slider?.setOn(on, animated: true)
        
        let on2:Bool = NSUserDefaults.standardUserDefaults().boolForKey("templateMode")
        slider?.setOn(on2, animated: true)
        
        super.viewDidLoad()
        
        let names = ArchivedEdges.archivedSketchNames()
        //create test sketches if we're not in template mode
        if((names == nil || names!.count < 5)  && on2){
            createTestSketches()
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        collectionOfFoldlings.reloadData()
    }
    
    /// we probably have to store the screenshots of our test scenes somewhere, because we can't instantiate their views easily here
    func createTestSketches(){
        
        ArchivedEdges.removeAll()
        var vc = self.storyboard?.instantiateViewControllerWithIdentifier("sketchView") as! SketchViewController
        
        // this makes the pre-fab sketches
        var localSketch:Sketch
        for (var i = 0; i < 10; i++){
            localSketch = Sketch(at: i, named: "Sketch \(i)")
            let arch = ArchivedEdges(sketch:localSketch)
            arch.save()
        }
        
    }
    
    func makeSketch(num:Int){
        
        var vc = self.storyboard?.instantiateViewControllerWithIdentifier("sketchView") as! SketchViewController
        self.presentViewController(vc, animated: true, completion: nil)
        
        (vc.view as! SketchView).forceRedraw()
    }
    
    //hides nav bar on splash screen
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        super.viewWillDisappear(animated)
    }
    
}

