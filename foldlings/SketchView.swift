//
//  DrawView.swift
//  foldlings
//  
//  Created by Tim Tregubov on 10/14/14.
//

import UIKit

class SketchView: UIView {
    
    enum Mode {
        case Erase
        case Cut
        case Fold
    }

    
    var path: UIBezierPath!
    var incrementalImage: UIImage!
    var pts: [CGPoint]! // we now need to keep track of the four points of a Bezier segment and the first control point of the next segment
    var ctr: Int = 0
//    var tempStart:CGPoint = CGPointZero
    var sketchMode:  Mode = Mode.Cut
    
    
//    var tempStart:CGPoint = nil
    
    var sketch: Sketch!
    //
    //TODO: while drawing:
    //      identify intersecting bounding boxes
    //      check for nearest points in matching 
    //      show user some indication (say a circle) that they are within range for a valid intersection
    //          (ie if they end line would snap to said point)
    //      if intersection found then on completion
    //          modify one edge with new intersection endpoint and add a new line
    //      add line to Sketch
    //TODO:  delete button
    //  identify any intersecting bounding boxes
    //  then refine to specific line if there are more than 1
    //  then remove from data structures
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.multipleTouchEnabled = false;
        self.backgroundColor = UIColor.whiteColor()
        path = UIBezierPath()
        path.lineWidth = 2.0
        pts = [CGPoint](count: 5, repeatedValue: CGPointZero)
        sketch = Sketch()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.multipleTouchEnabled = false
        path = UIBezierPath()
        path.lineWidth = 2.0
        pts = [CGPoint](count: 4, repeatedValue: CGPointZero)
    }
    
    override func drawRect(rect: CGRect)
    {
        if (incrementalImage != nil)
        {
            incrementalImage.drawInRect(rect)
            path.stroke()
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent)
    {
        var touch = touches.anyObject() as UITouch
        switch sketchMode
        {
        case .Erase:
            //var touchPoint = [touch locationInView:self.view];
            var touchPoint: CGPoint = touch.locationInView(self)
            for e in sketch.edges
            {
                if  (e.path).containsPoint(touchPoint)
                {
                    println("fooo")
                    //e.path=nil
                    //e.path=UIBezierPath()
                    path=nil
                    path=UIBezierPath()
                }
            }

            break
        case .Cut, .Fold:
            ctr = 0
            pts[0] = touch.locationInView(self)
        default:
            break
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent)
    {
        var touch = touches.anyObject() as UITouch
        switch sketchMode
        {
        case .Erase:
            //var touchPoint = [touch locationInView:self.view];
            var touchPoint: CGPoint = touch.locationInView(self)
            for e in sketch.edges
            {
                //TODO: fix hittest
                if  (e.hitTest(touchPoint))
                {
                    println( "touchpoint: \(touchPoint)"  )
                    //TODO: somehow don't draw it anymore
                    // supposedly setting the path to nil and then to an empty UIBezierPath and then drawing that will be ok
                }
            }

            break
        case .Cut, .Fold:
            ctr=ctr+1
            pts[ctr] = touch.locationInView(self)
            if (ctr == 4)
            {
                pts[3] = CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0 )// move the endpoint to the middle of the line joining the second control point of the first Bezier segment and the first control point of the second Bezier segment
                path.moveToPoint(pts[0])
                path.addCurveToPoint(pts[3], controlPoint1: pts[1], controlPoint2: pts[2])// add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
                self.setNeedsDisplay()
                // replace points and get ready to handle the next segment
                pts[0] = pts[3]
                pts[1] = pts[4]
                ctr = 1
            }
        default:
            break
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        switch sketchMode
        {
        case .Erase:
            break
        case .Cut, .Fold:
            var touch = touches.anyObject() as UITouch
            self.drawBitmap()
            self.sketch.addEdge(pts[0], end: touch.locationInView(self), path: path)
            self.setNeedsDisplay()
            path.removeAllPoints()
            ctr = 0
        default:
            break
        }
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        self.touchesEnded(touches, withEvent: event)
    }
    
    func drawBitmap() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        
        if incrementalImage == nil ///first time; paint background white
        {
            var rectpath = UIBezierPath(rect: self.bounds)
            UIColor.whiteColor().setFill()
            rectpath.fill()
            incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        incrementalImage.drawAtPoint(CGPointZero)
        UIColor.blackColor().setStroke()
        path.stroke()
        incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
    func setSketchMode(sm: Mode)
    {
        sketchMode = sm;
    }
    

}
