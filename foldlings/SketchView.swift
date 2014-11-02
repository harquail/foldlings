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
    var tempStart:CGPoint = CGPointZero
    var sketchMode:  Mode = Mode.Cut
    var cancelledTouch: UITouch?
    var sketch: Sketch!
    
    
    //TODO: while drawing:
    //      identify intersecting bounding boxes
    //      check for nearest points in matching 
    //      show user some indication (say a circle) that they are within range for a valid intersection
    //          (ie if they end line would snap to said point)
    //      if intersection found then on completion
    //          modify one edge with new intersection endpoint and add a new line
    //      add line to Sketch
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.multipleTouchEnabled = false;
        self.backgroundColor = UIColor.whiteColor()
        path = UIBezierPath()
        path.lineWidth = kLineWidth
        pts = [CGPoint](count: 5, repeatedValue: CGPointZero)
        sketch = Sketch()
        drawBitmap()
    }
    
    override func drawRect(rect: CGRect)
    {
        if (incrementalImage != nil)
        {
            incrementalImage.drawInRect(rect)

            setPathStyle(path, edge:nil).setStroke()
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
            setPathStyle(path, edge:nil)
        default:
            break
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent)
    {
        var touch = touches.anyObject() as UITouch
        
        // ignore cancelledTouch
        if cancelledTouch == nil || cancelledTouch! != touch {
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
                    if makeBezier() {//create bezier curves
    //                    self.touchesCancelled(touches, withEvent:event)
                        cancelledTouch = touch
                    }
                }
                
            default:
                break
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        var endPoint = touch.locationInView(self)
        let startPoint = tempStart
        switch sketchMode
        {
        case .Erase:
            break
        case .Cut, .Fold:
            //self.drawBitmap()
            if ( dist(startPoint, endPoint) > kHitTestRadius)
            {
                let newPath = UIBezierPath(CGPath: path.CGPath)
                let edgekind = (sketchMode == .Cut) ? Edge.Kind.Cut : Edge.Kind.Fold
                setPathStyle(newPath, edge:nil)
                if (sketchMode == .Fold)
                {
                   endPoint = CGPoint(x: endPoint.x, y: startPoint.y)
                }
                self.sketch.addEdge(startPoint, end: endPoint, path: newPath, kind: edgekind)
                self.setNeedsDisplay()

            }
            path.removeAllPoints()
            ctr = 0
            forceRedraw()

        default:
            break
        }
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        self.touchesEnded(touches, withEvent: event)
    }
    
    func drawBitmap() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        var color:UIColor = UIColor.blackColor()
        
        if(incrementalImage == nil) ///first time; paint background white
        {
            var rectpath = UIBezierPath(rect: self.bounds)
            UIColor.whiteColor().setFill()
            rectpath.fill()
            
            // this will draw all possibly set paths
            
            for e in sketch.edges
            {
                setPathStyle(e.path, edge:e).setStroke()
                e.path.stroke()
            }
            incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        incrementalImage.drawAtPoint(CGPointZero)
        //set the stroke color
        setPathStyle(path, edge:nil).setStroke()
        path.stroke()
        incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
    func erase(touchPoint: CGPoint)
    {
        for (i,e) in enumerate(sketch.edges)
        {
            if  e.hitTest(touchPoint) && i > 4
            {
                //remove points and force a redraw by setting incrementalImage to nil
                // incremental image is a bitmap so that we don't ahve to stroke the paths every single draw call
                e.path.removeAllPoints()
                forceRedraw()
                //TODO: better way of handling this?
                //  need to also: refine to specific line if there are more than 1
                //  and actually remove from list?

            }
        }

    }
    
    //makes bezier by stringing segments together
    //creatse segments from ctrl pts
    // returns true if its force closed the path
    func makeBezier() -> Bool
    {
        var closed:Bool = false
        // only use first y-value
        // or
        // move the endpoint to the middle of the line joining the second control point of the first Bezier segment and the first control point of the second Bezier segment
        var newEnd = (sketchMode == .Fold) ? CGPointMake(pts[4].x,  tempStart.y) : CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0 )
        
        // test for self intersections
        if Edge.hitTest(path, point:newEnd) {
            println("self intersection: \(newEnd)")
            path.closePath() //TODO: change close path to closest point
            newEnd = tempStart
            closed = true
        } else {
            // test for intersections
            for edge in sketch.edges
            {
                if edge.hitTest(newEnd) {
                    println("intersection: \(newEnd)")
                }
            }
        }
        
        if ( sketchMode == .Fold)
        {
            // makes only straight horizontal fold lines
            // basically make a completely new line every movement so its only 2 points ever
            path = UIBezierPath()
            path.moveToPoint(tempStart)
            path.addLineToPoint(CGPointMake(newEnd.x,  newEnd.y))
            setPathStyle(path, edge:nil)
        } else {
            pts[3] = newEnd
            path.moveToPoint(pts[0])
            path.addCurveToPoint(pts[3], controlPoint1: pts[1], controlPoint2: pts[2])// add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
        }
        
        
        self.setNeedsDisplay()
        // replace points and get ready to handle the next segment
        pts[0] = pts[3]
        pts[1] = pts[4]
        ctr = 1
        
        return closed
    }
    
    
    // this will set the path style as well as return the color of the path to be stroked
    func setPathStyle(path:UIBezierPath, edge:Edge?) -> UIColor
    {
        
        var edgekind:Edge.Kind!
        var fold:Edge.Fold!
        var color:UIColor!
        
        if let e = edge
        {
            edgekind = e.kind
            fold = e.fold
            color = e.getColor()
        } else {
            edgekind = (sketchMode == .Cut) ? Edge.Kind.Cut : Edge.Kind.Fold
            fold = Edge.Fold.Unknown
            color = Edge.getColor(edgekind, fold:fold)
        }
        
        if edgekind == Edge.Kind.Fold {
            path.setLineDash([10,5], count: 2, phase:0)
        } else {
            path.setLineDash(nil, count: 0, phase:0)
        }
        
        
        path.lineWidth=kLineWidth
        
        return color
    }
    
    
    func forceRedraw()
    {
        incrementalImage = nil
        self.setNeedsDisplay() //draw to clear the deleted path
        drawBitmap() //redraw full bitmap
    }
    
    func previewImage() -> UIImage{
        

        let size = CGSizeMake(self.bounds.width,self.bounds.width)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        
        self.drawViewHierarchyInRect(CGRectMake(0,0,self.bounds.width,self.bounds.width), afterScreenUpdates:true)
        let copied = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        
//        var croppedImage = CGImageCreateWithImageInRect(copied.CGImage, CGRectMake(0,0,self.bounds.width,self.bounds.width));
  //      var crop = UIImage.imageWithCGImage(croppedImage, resizedImagesize, interpolationQuality: kCGInterpolationHigh);
        

        
//        
//        UIGraphicsBeginImageContext(self.bounds.size)
//        self.layer.renderInContext(UIGraphicsGetCurrentContext())
//        var img = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext();
//        
        return copied;

    }

}
