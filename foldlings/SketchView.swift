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
    
    
    var path: UIBezierPath! //currently drawing path
    var incrementalImage: UIImage!  //this is a bitmap version of everything
    var pts: [CGPoint]! // we now need to keep track of the four points of a Bezier segment and the first control point of the next segment
    var ctr: Int = 0
    var tempStart:CGPoint = CGPointZero // these keep track of point while drawing
    var tempEnd:CGPoint = CGPointZero
    var sketchMode:  Mode = Mode.Cut
    var cancelledTouch: UITouch?  //if interrrupted say on intersection
    var sketch: Sketch!
    var endPaths: [CGPoint: UIBezierPath] = [CGPoint: UIBezierPath]() //the circles on the ends of paths
    var startEdgeCollision:Edge?
    var endEdgeCollision:Edge?
    
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.multipleTouchEnabled = false;
        self.backgroundColor = UIColor.whiteColor()
        path = UIBezierPath()
        path.lineWidth = kLineWidth
        pts = [CGPoint](count: 5, repeatedValue: CGPointZero)
        
        // TODO: name should be set when creating sketch
        sketch = Sketch(named: "name")
        //simpleSketch()
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
        var touchPoint: CGPoint = touch.locationInView(self)
        startEdgeCollision = nil //reset edge collisions to nil
        endEdgeCollision = nil
        switch sketchMode
        {
        case .Erase:
            erase(touchPoint);
        case .Cut, .Fold:
            for edge in sketch.edges
            {
                if edge.hitTest(touchPoint) {
                    println("intersection: \(touchPoint)")
                    let np = getNearestPointOnPath(touchPoint, edge.path)
                    touchPoint = np
                    startEdgeCollision = edge
                }
            }
            ctr = 0
            pts[0] = touchPoint
            tempStart = touchPoint
            tempEnd = touchPoint //set end to same point at start
            setPathStyle(path, edge:nil)
        default:
            break
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent)
    {
        var touch = touches.anyObject() as UITouch
        var touchPoint: CGPoint = touch.locationInView(self)
        
        // ignore cancelledTouch
        if cancelledTouch == nil || cancelledTouch! != touch {
            switch sketchMode
            {
            case .Erase: // if in erase mode
                erase(touchPoint);
            case .Cut, .Fold:
                var abort:Bool = checkCurrentEnd(touchPoint)
                ctr=ctr+1
                pts[ctr] = tempEnd
                
                if (ctr == 4)
                {
                    makeBezier() //create bezier curves
                }
                
                if abort {
                    cancelledTouch = touch
                }
                
            default:
                break
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        
        var endPoint = tempEnd
        let startPoint = tempStart
        switch sketchMode
        {
        case .Erase:
            break
        case .Cut, .Fold:
            if path.bounds.height > kMinLineLength || path.bounds.width > kMinLineLength
            {
                if let endColEdge = endEdgeCollision {
                    //TODO: make edges separate
                }
                makeBezier(aborted: true)  //do another call to makeBezier to finish the line
                var newPath = UIBezierPath(CGPath: path.CGPath)
                newPath = smoothPath(newPath)
                let edgekind = (sketchMode == .Cut) ? Edge.Kind.Cut : Edge.Kind.Fold
                setPathStyle(newPath, edge:nil)
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
                if e.start == e.end //is a loop draw filled
                {
                    UIColor.blackColor().setFill()
                    e.path.fill()
                }
                setPathStyle(e.path, edge:e).setStroke()
                e.path.stroke()
                // just draw that point to indicate it...
                if !e.path.empty && e.start != e.end {
                    drawEdgePoints(e.start, end:e.end) //these only get drawn when lines are complete
                }

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
            if  e.hitTest(touchPoint) && i > 4 //first 5 edges are special fold plus paper edges
            {
                //remove points and force a redraw by setting incrementalImage to nil
                // incremental image is a bitmap so that we don't ahve to stroke the paths every single draw call
                e.path.removeAllPoints()
                sketch.removeEdge(e) //remove
                forceRedraw()
                //TODO: better way of handling this?
                //  need to also: refine to specific line if there are more than 1

            }
        }

    }
    
    //makes bezier by stringing segments together
    //creatse segments from ctrl pts
    func makeBezier(aborted:Bool=false)
    {
        if !aborted
        {
            // only use first y-value
            // or
            // move the endpoint to the middle of the line joining the second control point of the first Bezier segment and the first control point of the second Bezier segment
            var newEnd = (sketchMode == .Cut) ? CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0 ) : tempEnd
            
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
                if path.empty { path.moveToPoint(pts[0]) } //only do moveToPoint for 1st point
                path.addCurveToPoint(pts[3], controlPoint1: pts[1], controlPoint2: pts[2])// add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
            }
            
            // replace points and get ready to handle the next segment
            pts[0] = pts[3]
            pts[1] = pts[4]
        } else {
            if path.empty { path.moveToPoint(pts[0]) } //only do moveToPoint for 1st point
            path.addLineToPoint(tempEnd)
            if tempEnd == tempStart {
                path.closePath()
            }
        }
        ctr = 1
        self.setNeedsDisplay()

    }
    
    // checks and constrains current endpoint
    func checkCurrentEnd(endpoint: CGPoint) -> Bool {
        var closed:Bool = false
        
        // only use first y-value
        // or
        // move the endpoint to the middle of the line joining the second control point of the first Bezier segment and the first control point of the second Bezier segment
        if sketchMode == .Fold {
            tempEnd = CGPointMake(endpoint.x,  tempStart.y)
        } else {
            tempEnd = endpoint
        }
        
        //ignore intersections if we're just starting a line...
        if ( dist(tempStart, tempEnd) > kMinLineLength)
        {
            // test for self intersections
            if sketchMode != .Fold && Edge.hitTest(path, point:tempEnd) {
                println("self intersection: \(tempEnd)")
                let np = getNearestPointOnPath(tempEnd, path)
                tempEnd = np
                closed = true
            } else {
                // test for intersections
                for edge in sketch.edges
                {
                    if edge.hitTest(tempEnd) {
                        println("intersection: \(tempEnd)")
                        let np = getNearestPointOnPath(tempEnd, edge.path)
                        tempEnd = np
                        closed = true
                        endEdgeCollision = edge
                    }
                }
            }
        } else {
            // check that we're not closing a path
            //  needs to make sure that the path bounds are greater than minlinelength
            if sketchMode == .Cut && (path.bounds.height > kMinLineLength || path.bounds.width > kMinLineLength){
                //lets close the cut path and make a hole
                // well the closing actually takes place in
                println("found closing a path")
                tempEnd = tempStart
                closed = true
            }
        }
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

    
    func simpleSketch()->Sketch
    {
        var asketch = Sketch(named: "simple sketch")
        
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
        
        
        //edges
//        fold1.moveToPoint(b1)
//        fold1.addLineToPoint(b2)
//        asketch.addEdge(b1, end: b2, path: fold1, kind: Edge.Kind.Fold )
//        
//        cut1.moveToPoint(b2)
//        cut1.addLineToPoint(b3)
//        asketch.addEdge(b2, end: b3, path: cut1, kind: Edge.Kind.Cut )
//        
//        cut2.moveToPoint(b3)
//        cut2.addLineToPoint(b4)
//        asketch.addEdge(b3, end: b4, path: cut2, kind: Edge.Kind.Cut )
//        
//        
//        fold2.moveToPoint(b4)
//        fold2.addLineToPoint(b5)
//        asketch.addEdge(b4, end: b5, path: fold2, kind: Edge.Kind.Fold )
//        
//        
//        cut3.moveToPoint(b5)
//        cut3.addLineToPoint(b6)
//        asketch.addEdge(b5, end: b6, path: cut3, kind: Edge.Kind.Cut )
//        
//        cut4.moveToPoint(b6)
//        cut4.addLineToPoint(b1)
//        asketch.addEdge(b6, end: b1, path: cut4, kind: Edge.Kind.Cut )
//        
        //centerfold
        cfold1.moveToPoint(c1)
        cfold1.addLineToPoint(c2)
        asketch.addEdge(c1, end: c2, path: cfold1, kind: Edge.Kind.Fold )
        
        cfold2.moveToPoint(c2)
        cfold2.addLineToPoint(c3)
        asketch.addEdge(c2, end: c3, path: cfold2, kind: Edge.Kind.Fold )
        
        cfold3.moveToPoint(c3)
        cfold3.addLineToPoint(c4)
        asketch.addEdge(c3, end: c4, path: cfold3, kind: Edge.Kind.Fold )
        
        //border edges
        top.moveToPoint(s1)
        top.addLineToPoint(s2)
        asketch.addEdge(s1, end: s2, path: top, kind: Edge.Kind.Cut )
        
        rside1.moveToPoint(s2)
        rside1.addLineToPoint(c4)
        asketch.addEdge(s2, end: c4, path: rside1, kind: Edge.Kind.Cut )
        
        rside2.moveToPoint(c4)
        rside2.addLineToPoint(s4)
        asketch.addEdge(c4, end: s4, path: rside2, kind: Edge.Kind.Cut )
        
        bottom.moveToPoint(s4)
        bottom.addLineToPoint(s5)
        asketch.addEdge(s4, end: s5, path: bottom, kind: Edge.Kind.Cut )
        
        lside1.moveToPoint(s5)
        lside1.addLineToPoint(c1)
        asketch.addEdge(s5, end: c1, path: lside1, kind: Edge.Kind.Cut )
        
        lside2.moveToPoint(c1)
        lside2.addLineToPoint(s1)
        asketch.addEdge(c1, end: s1, path: lside2, kind: Edge.Kind.Cut )
        
        return asketch
    }

    
    func previewImage() -> UIImage {
        
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0);
        
        self.drawViewHierarchyInRect(self.bounds, afterScreenUpdates:true)
        let copied = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

      
//        return RBResizeImage(copied,CGSizeMake(900, 100000))
        
        return copied;

    }
    
    
    func drawEdgePoints(start: CGPoint, end:CGPoint?) {
        endPaths[start]=drawCircle(start)
        if let tempEnd = end? {
            endPaths[tempEnd]=drawCircle(tempEnd)
        }
    }
    
    func drawCircle(point: CGPoint) ->UIBezierPath
    {
        UIColor.redColor().setStroke()
        let c = UIBezierPath()
        c.addArcWithCenter(point, radius:5.0, startAngle:0.0, endAngle:CGFloat(2.0*M_PI), clockwise:true)
        c.stroke()
        return c
    }
}
