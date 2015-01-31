//
//
import Foundation
import UIKit
import Armchair

class SplashViewController: UIViewController, UIAlertViewDelegate {
    
    @IBOutlet var slider:UISwitch!
    
    @IBOutlet var collectionOfFoldlings: CollectionOfFoldlings!
    
    @IBAction func proButtonTouched(sender: AnyObject) {
        toggleProMode()
    }
    
    @IBAction func sliderSlid(sender: AnyObject) {
        toggleProMode()
    }
    
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
        let vc = story.instantiateViewControllerWithIdentifier("sketchView") as SketchViewController
        self.presentViewController(vc, animated: true, completion: {
            vc.sketchView.forceRedraw()
        })
        
        vc.sketchView.sketch.index = ArchivedEdges.archivedSketchNames()!.count + 1
        vc.sketchView.sketch.name = name
        println(vc.sketchView.sketch.index)
        Flurry.logEvent("new sketch created", withParameters: NSDictionary(dictionary: ["named":name]))
        


    }
    
    func toggleProMode(){
        var isOn = slider.on
        isOn = !isOn
             Flurry.logEvent("pro mode toggled", withParameters: NSDictionary(dictionary: ["on":isOn]))
        slider.setOn(isOn, animated: true)
        NSUserDefaults.standardUserDefaults().setBool(isOn, forKey: "proMode")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    override func viewDidLoad() {
        Armchair.showPromptIfNecessary()
        let on:Bool = NSUserDefaults.standardUserDefaults().boolForKey("proMode")
        slider?.setOn(on, animated: true)
        super.viewDidLoad()
        
        let names = ArchivedEdges.archivedSketchNames()
        if(true){
            //names == nil || names!.count < 5
            createTestSketches()
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        collectionOfFoldlings.reloadData()
    }
    
    /// we probably have to store the screenshots of our test scenes somewhere, because we can't instantiate their views easily here
    func createTestSketches(){
        
        ArchivedEdges.removeAll()
        var vc = self.storyboard?.instantiateViewControllerWithIdentifier("sketchView") as SketchViewController
        
        var localSketch:Sketch
        for (var i = 0; i < 10; i++){
            localSketch = Sketch(at: i, named: "Sketch \(i)")
            switch(i){
            case 0:
                boringTestPlaneInSketch(localSketch, xStart:100, topXStart: 100, foldHeightBelowMaster:300, midFoldHeight:80, bottomWidth:300, topWidth:300)
            case 1:
                boringTestPlaneInSketch(localSketch, xStart:100, topXStart: 100, foldHeightBelowMaster:100, midFoldHeight:30, bottomWidth:50, topWidth:50)
            case 2:
                boringTestPlaneInSketch(localSketch, xStart:200, topXStart: 100, foldHeightBelowMaster:200, midFoldHeight:90, bottomWidth:200, topWidth:200)

            case 3:
                boringTestPlaneInSketch(localSketch, xStart:150, topXStart: 100, foldHeightBelowMaster:150, midFoldHeight:100, bottomWidth:150, topWidth:150)
            default:
                boringTestPlaneInSketch(localSketch, xStart:150, topXStart: 100, foldHeightBelowMaster:150, midFoldHeight:100, bottomWidth:150, topWidth:150)
            }
            let arch = ArchivedEdges(sketch:localSketch)
            arch.save()
        }
        
    }
    
    func makeSketch(num:Int){
        
        var vc = self.storyboard?.instantiateViewControllerWithIdentifier("sketchView") as SketchViewController
        self.presentViewController(vc, animated: true, completion: nil)
        
        switch(num){
        case 0:
            boringTestPlaneInSketch(vc.sketchView.sketch, xStart:100, topXStart: 100, foldHeightBelowMaster:300, midFoldHeight:80, bottomWidth:300, topWidth:300)
            
        case 1:
            boringTestPlaneInSketch(vc.sketchView.sketch, xStart:100, topXStart: 100, foldHeightBelowMaster:100, midFoldHeight:30, bottomWidth:50, topWidth:50)
        case 2:
            boringTestPlaneInSketch(vc.sketchView.sketch, xStart:200, topXStart: 100, foldHeightBelowMaster:200, midFoldHeight:90, bottomWidth:200, topWidth:200)
        case 3:
            boringTestPlaneInSketch(vc.sketchView.sketch, xStart:200, topXStart: 100, foldHeightBelowMaster:200, midFoldHeight:90, bottomWidth:200, topWidth:200)
        case 4:
            boringTestPlaneInSketch(vc.sketchView.sketch, xStart:150, topXStart: 100, foldHeightBelowMaster:150, midFoldHeight:100, bottomWidth:150, topWidth:150)
        default:
            break
            //            boringTestPlaneInSketch(vc.sketchView.sketch, xStart:150, foldHeightBelowMaster:150, midFoldHeight:100, bottomWidth:400, topWidth:150)
            
        }
        (vc.view as SketchView).forceRedraw()
    }
    
    func simpleSketch(s:Sketch)
    {
        var fold1 = UIBezierPath()
        var cut1 = UIBezierPath()
        var cut2 = UIBezierPath()
        var fold2 = UIBezierPath()
        var cut3 = UIBezierPath()
        var cut4 = UIBezierPath()
        var cfold1 = UIBezierPath()
        var cfold2 = UIBezierPath()
        var cfold3 = UIBezierPath()
        
        var top = UIBezierPath()
        var rside1 = UIBezierPath()
        var rside2 = UIBezierPath()
        var bottom = UIBezierPath()
        var lside1 = UIBezierPath()
        var lside2 = UIBezierPath()
        
        //points
        let b1 = CGPointMake(260, 290)
        let b2 = CGPointMake(520, 290)
        let b3 = CGPointMake(520, 512)
        let b4 = CGPointMake(520, 680)
        let b5 = CGPointMake(260, 680)
        let b6 = CGPointMake(260, 512)
        
        // for centerfold
        let c1 = CGPointMake(0, 512)//s6
        let c2 = CGPointMake(260, 512)
        let c3 = CGPointMake(520, 512)
        let c4 = CGPointMake(768, 512)//s3
        
        //for side edges
        let s1 = CGPointMake(0, 0)
        let s2 = CGPointMake(768, 0)
        let s4 = CGPointMake(768, 1024)
        let s5 = CGPointMake(0, 1024)
        
        //        edges
        fold1.moveToPoint(b1)
        fold1.addLineToPoint(b2)
        s.addEdge(b1, end: b2, path: fold1, kind: Edge.Kind.Fold )
        
        cut1.moveToPoint(b2)
        cut1.addLineToPoint(b3)
        s.addEdge(b2, end: b3, path: cut1, kind: Edge.Kind.Cut )
        
        cut2.moveToPoint(b3)
        cut2.addLineToPoint(b4)
        s.addEdge(b3, end: b4, path: cut2, kind: Edge.Kind.Cut )
        
        fold2.moveToPoint(b4)
        fold2.addLineToPoint(b5)
        s.addEdge(b4, end: b5, path: fold2, kind: Edge.Kind.Fold )
        
        cut3.moveToPoint(b5)
        cut3.addLineToPoint(b6)
        s.addEdge(b5, end: b6, path: cut3, kind: Edge.Kind.Cut )
        
        cut4.moveToPoint(b6)
        cut4.addLineToPoint(b1)
        s.addEdge(b6, end: b1, path: cut4, kind: Edge.Kind.Cut )
        
        //centerfold
        cfold1.moveToPoint(c1)
        cfold1.addLineToPoint(c2)
        s.addEdge(c1, end: c2, path: cfold1, kind: Edge.Kind.Fold )
        
        cfold2.moveToPoint(c2)
        cfold2.addLineToPoint(c3)
        s.addEdge(c2, end: c3, path: cfold2, kind: Edge.Kind.Fold )
        
        cfold3.moveToPoint(c3)
        cfold3.addLineToPoint(c4)
        s.addEdge(c3, end: c4, path: cfold3, kind: Edge.Kind.Fold )
        
        
    }
    
    
    func boringTestPlaneInSketch(s:Sketch, xStart:CGFloat, topXStart:CGFloat, foldHeightBelowMaster:CGFloat, midFoldHeight:CGFloat, bottomWidth:CGFloat, topWidth:CGFloat) {
        
        //for now, assuming topWidth == bottomWidth
        
        //first draw bottom fold below Master
        //then draw mid fold
        // measure distance between midfold and master
        // use points known to generate cuts n folds (top fold and connections)
        // optionally, delete master fold segment inside plane
        
        let drivingEdgeStart = s.drivingEdge.start
        let drivingEdgeEnd = s.drivingEdge.end
        s.removeEdge(s.drivingEdge) //remove master fold
        
        let bottomFoldStart = CGPointMake(drivingEdgeStart.x + xStart ,drivingEdgeStart.y + foldHeightBelowMaster)
        let bottomFoldEnd = CGPointMake(bottomFoldStart.x + bottomWidth, bottomFoldStart.y)
        let bottomFold = Edge.straightEdgeBetween(bottomFoldStart, end: bottomFoldEnd, kind: .Fold)
        s.addEdge(bottomFold)
        
        
        let midFoldStart = CGPointMake(bottomFoldStart.x, drivingEdgeStart.y - midFoldHeight)
        let midFoldEnd = CGPointMake(bottomFoldEnd.x, midFoldStart.y)
        let midFold = Edge.straightEdgeBetween(midFoldStart, end: midFoldEnd, kind: .Fold)
        s.addEdge(midFold)
        
        
        let masterFoldLeftStart = CGPointMake(drivingEdgeStart.x, drivingEdgeStart.y)
        let masterFoldLeftEnd = CGPointMake(midFoldStart.x, drivingEdgeStart.y)
        let masterFoldLeft = Edge.straightEdgeBetween(masterFoldLeftStart, end: masterFoldLeftEnd, kind: .Fold)
        s.addEdge(masterFoldLeft)
        
        let masterFoldRightStart = CGPointMake(drivingEdgeEnd.x, drivingEdgeStart.y)
        let masterFoldRightEnd = CGPointMake(midFoldEnd.x, drivingEdgeStart.y)
        let masterFoldRight = Edge.straightEdgeBetween(masterFoldRightStart, end: masterFoldRightEnd, kind: .Fold)
        s.addEdge(masterFoldRight)
        
        let masterMinusMid = masterFoldLeft.yDistTo(bottomFold)
        
        let topFoldStart = CGPointMake(midFoldStart.x, midFoldStart.y - masterMinusMid)
        let topFoldEnd = CGPointMake(midFoldEnd.x, topFoldStart.y)
        let topFold = Edge.straightEdgeBetween(topFoldStart, end: topFoldEnd, kind: .Fold)
        s.addEdge(topFold)
        
        let connectionOne = Edge.straightEdgeBetween(topFoldStart, end: midFoldStart, kind: .Cut)
        s.addEdge(connectionOne)
        
        let connectionTwo = Edge.straightEdgeBetween(topFoldEnd, end: midFoldEnd, kind: .Cut)
        s.addEdge(connectionTwo)
        
        let connectionThree = Edge.straightEdgeBetween(midFoldStart, end: masterFoldLeftEnd, kind: .Cut)
        s.addEdge(connectionThree)
        
        let connectionFour = Edge.straightEdgeBetween(midFoldEnd, end: masterFoldRightEnd, kind: .Cut)
        s.addEdge(connectionFour)
        
        let connectionFive = Edge.straightEdgeBetween(masterFoldLeftEnd, end: bottomFoldStart, kind: .Cut)
        s.addEdge(connectionFive)
        
        let connectionSix = Edge.straightEdgeBetween(masterFoldRightEnd, end: bottomFoldEnd, kind: .Cut)
        s.addEdge(connectionSix)
        
    }
}

