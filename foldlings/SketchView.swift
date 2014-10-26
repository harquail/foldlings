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
    
    
    let kLineWidth:CGFloat = 2.0
    
    var path: UIBezierPath!
    var incrementalImage: UIImage!
    var pts: [CGPoint]! // we now need to keep track of the four points of a Bezier segment and the first control point of the next segment
    var ctr: Int = 0
    var tempStart:CGPoint = CGPointZero
    var sketchMode:  Mode = Mode.Cut
    var redraw: Bool = false
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
        path.lineWidth = kLineWidth
        pts = [CGPoint](count: 5, repeatedValue: CGPointZero)
        sketch = Sketch()
    }
    
//    override init(frame: CGRect)
//    {
//        super.init(frame: frame)
//        self.multipleTouchEnabled = false
//        path = UIBezierPath()
//        path.lineWidth = kLineWidth
//        pts = [CGPoint](count: 5, repeatedValue: CGPointZero)
//    }
    
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
            var touchPoint: CGPoint = touch.locationInView(self)
            erase(touchPoint);

        case .Cut, .Fold:
            ctr = 0
            pts[0] = touch.locationInView(self)
            tempStart = touch.locationInView(self)
        default:
            break
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent)
    {
        var touch = touches.anyObject() as UITouch
        switch sketchMode
        {
        case .Erase: // if in erase mode
            var touchPoint: CGPoint = touch.locationInView(self)
            erase(touchPoint);

            
        case .Cut, .Fold:
            ctr=ctr+1
            pts[ctr] = touch.locationInView(self)
            if (ctr == 4)
            {
                makeBezier() //create bezier curves
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
            let newPath = UIBezierPath(CGPath: path.CGPath);
            newPath.lineWidth=kLineWidth
            self.sketch.addEdge(tempStart, end: touch.locationInView(self), path: newPath)//, type: EdgeType.Cut)
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
        
        if(incrementalImage == nil) ///first time; paint background white
        {
            var rectpath = UIBezierPath(rect: self.bounds)
            UIColor.whiteColor().setFill()
            rectpath.fill()
            
            // this will draw all possibly set paths
            UIColor.blackColor().setStroke()
            for e in sketch.edges
            {
                e.path.stroke()
            }
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
    
    func erase(touchPoint: CGPoint)
    {
        for e in sketch.edges
        {
            if  (e.hitTest(touchPoint))
            {
                println( "got touchpoint: \(touchPoint)"  )
                //remove points and force a redraw by setting incrementalImage to nil
                // incremental image is a bitmap so that we don't ahve to stroke the paths every single draw call
                e.path.removeAllPoints()
                incrementalImage = nil
                self.setNeedsDisplay() //draw to clear the deleted path
                drawBitmap() //redraw full bitmap
                //TODO: better way of handling this?
            }
        }

    }
    
    //makes bezier by stringing segments together
    //creatse segments from ctrl pts
    func makeBezier()
    {
        if ( sketchMode == .Fold){    //makes only straight horizontal fold lines
            pts[3] = CGPointMake(pts[4].x,  pts[0].y) // only use first y-value
            path.moveToPoint(pts[0])
            path.addLineToPoint(pts[3])// add the line to last point
        }
            
        else{
        pts[3] = CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0 ) // move the endpoint to the middle of the line joining the second control point of the first Bezier segment and the first control point of the second Bezier segment
        path.moveToPoint(pts[0])

        path.addCurveToPoint(pts[3], controlPoint1: pts[1], controlPoint2: pts[2])// add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
        }
        
        self.setNeedsDisplay()
        // replace points and get ready to handle the next segment
        pts[0] = pts[3]
        pts[1] = pts[4]
        ctr = 1
    }
    

}
