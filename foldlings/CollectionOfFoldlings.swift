//
//
import Foundation
import UIKit

class CollectionOfFoldlings: UIViewController {
    
    
    @IBAction func oneButton(sender: UIButton) {
       makeSketch(0)
        
    }
    
    @IBAction func twoButton(sender: UIButton) {
        makeSketch(1)
    }
    
    @IBAction func threeButton(sender: UIButton) {
        makeSketch(2)
    }
    
    @IBAction func fourButton(sender: UIButton) {
        makeSketch(3)
    }
    
    @IBAction func fiveButton(sender: UIButton) {
      makeSketch(4)    }
    
    func makeSketch(num:Int){
        
        
        var vc = self.storyboard?.instantiateViewControllerWithIdentifier("sketchView") as SketchViewController
        self.presentViewController(vc, animated: true, completion: nil)

        
//        let viewC = SketchViewController()
//        viewC.sketchView = SketchView(frame: self.view.frame)
        println("reached makeSketch switch")
            
//        return viewC

        switch(num){
        case 0:
            simpleSketch(vc.sketchView.sketch)
        case 1:
            break
        case 2:
            break
        case 3:
            break
        case 4:
            break
        default:
            break
        }
        
        (vc.view as SketchView).forceRedraw()
//        return viewC
    }   
    
    func simpleSketch(s:Sketch)
    {
//        var asketch = Sketch(named: "simple sketch")
        
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
        
        
        //border edges
//        top.moveToPoint(s1)
//        top.addLineToPoint(s2)
//        s.addEdge(s1, end: s2, path: top, kind: Edge.Kind.Cut )
//        
//        rside1.moveToPoint(s2)
//        rside1.addLineToPoint(c4)
//        s.addEdge(s2, end: c4, path: rside1, kind: Edge.Kind.Cut )
//        
//        rside2.moveToPoint(c4)
//        rside2.addLineToPoint(s4)
//        s.addEdge(c4, end: s4, path: rside2, kind: Edge.Kind.Cut )
//        
//        bottom.moveToPoint(s4)
//        bottom.addLineToPoint(s5)
//        s.addEdge(s4, end: s5, path: bottom, kind: Edge.Kind.Cut )
//        
//        lside1.moveToPoint(s5)
//        lside1.addLineToPoint(c1)
//        s.addEdge(s5, end: c1, path: lside1, kind: Edge.Kind.Cut )
//        
//        lside2.moveToPoint(c1)
//        lside2.addLineToPoint(s1)
//        s.addEdge(c1, end: s1, path: lside2, kind: Edge.Kind.Cut )
        
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
    
    
    func boringTestPlaneInSketch(s:Sketch, xStart:Float, foldHeightBelowMaster:Float, midFoldHeight:Float, width:Float) {
    
        //first draw bottom fold below Master
        //then draw mid fold
        // measure distance between midfold and master
        // use points known to generate cuts n folds (top fold and connections)
        // optionally, delete master fold segment inside plane
    
    }

    
    
}

