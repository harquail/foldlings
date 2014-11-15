//
//  DrawView.swift
//  foldlings
//
//
//

import UIKit

class SketchView: UIView {
    
    @IBOutlet var previewButton: UIButton!
    
    enum Mode {
        case Erase
        case Cut
        case Fold
        case Tab
    }
    
    // this sets simpleMode,  we could refactor and do a sublcass for simple mode but might be quicker to do this
    var simpleMode = true
    
    
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
    var gameView = GameViewController()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
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
        incrementalImage = bitmap(grayscale: false)
    }
    
    override func drawRect(rect: CGRect)
    {
        if (incrementalImage != nil)
        {
            incrementalImage.drawInRect(rect)
            
            setPathStyle(path, edge:nil, grayscale:false).setStroke()
            path.stroke()
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent)
    {
        previewButton.alpha = 0.3
        var touch = touches.anyObject() as UITouch
        var touchPoint: CGPoint = touch.locationInView(self)
        startEdgeCollision = nil //reset edge collisions to nil
        endEdgeCollision = nil
        
        // ignore touch if outside of bounds
        if !sketch.checkInBounds(touchPoint) {
            cancelledTouch = touch
            return
        }
        
        switch sketchMode
        {
        case .Erase:
            erase(touchPoint);
        case .Cut, .Fold, .Tab:
            // simplemode check for fold drawing
            if simpleMode && !simpleModeFoldInBounds(touchPoint, sketchMode: sketchMode)  {
                cancelledTouch = touch
                return
            }
            
            // snap to vertex
            if let np = sketch.vertexHitTest(touchPoint) {
                touchPoint = np
            } // snap to edge
            else if let (edge,np) = sketch.edgeHitTest(touchPoint) {
                touchPoint = np
                startEdgeCollision = edge
            }
            ctr = 0
            pts[0] = touchPoint
            tempStart = touchPoint
            tempEnd = touchPoint //set end to same point at start
            setPathStyle(path, edge:nil, grayscale:false)
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
            case .Cut, .Fold, .Tab:
                // check if we've snapped or aborted
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
        
        previewButton.alpha = 1
        
        var endPoint = tempEnd
        let startPoint = tempStart
        switch sketchMode
        {
        case .Erase:
            break
        case .Cut, .Fold, .Tab:
            if path.bounds.height > kMinLineLength || path.bounds.width > kMinLineLength
            {
                var se1:Edge?
                var se2:Edge?
                //splits edges on collision
                if let startColEdge = startEdgeCollision {
                    // if there are problems with circles might be ehre
                    var (spathOne, spathTwo) = splitPath(startColEdge.path, withPoint:startPoint)
                    se1 = self.sketch.addEdge(startColEdge.start, end: startPoint, path: spathOne, kind: startColEdge.kind, isMaster: startColEdge.isMaster)
                    se2 = self.sketch.addEdge(startPoint, end: startColEdge.end, path: spathTwo, kind: startColEdge.kind, isMaster: startColEdge.isMaster)
                    self.sketch.removeEdge(startColEdge)
                }
                if var endColEdge = endEdgeCollision {
                    // check if we've already split this particular object this is problem so we need to make sure
                    // look at the new edges
                    var cut = false
                    if ((se1 != nil) && (se1!.hitTest(endPoint)) != nil) {
                        endColEdge = se1!
                        cut = true
                    } else if ((se2 != nil) && (se2!.hitTest(endPoint)) != nil) {
                        endColEdge = se2!
                        cut = true
                    }
                    var (epathOne, epathTwo) = splitPath(endColEdge.path, withPoint:endPoint)
                    if cut {
                        // if there are problems with circles might be ehre
                        self.sketch.addEdge(endColEdge.start, end: endPoint, path: epathOne, kind: endColEdge.kind, isMaster: endColEdge.isMaster)
                        self.sketch.addEdge(endPoint, end: endColEdge.end, path: epathTwo, kind: endColEdge.kind, isMaster: endColEdge.isMaster)
                    } else {
                        self.sketch.addEdge(endColEdge.start, end: endPoint, path: epathOne, kind: endColEdge.kind, isMaster: endColEdge.isMaster)
                        self.sketch.addEdge(endPoint, end: endColEdge.end, path: epathTwo, kind: endColEdge.kind, isMaster: endColEdge.isMaster)
                    }
                    self.sketch.removeEdge(endColEdge)
                }
                makeBezier(aborted: true)  //do another call to makeBezier to finish the line
                var newPath = UIBezierPath(CGPath: path.CGPath)
                newPath = smoothPath(newPath)
                setPathStyle(newPath, edge:nil, grayscale:false)
                self.sketch.addEdge(startPoint, end: endPoint, path: newPath, kind: modeToEdgeKind(sketchMode))
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
    
    /// constructs a greyscale bitmap preview image of the sketch
    func bitmap(#grayscale:Bool) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        var color:UIColor = UIColor.blackColor()
        
        var tempIncremental = incrementalImage
        
        if(grayscale){
            tempIncremental = nil
        }
        if(tempIncremental == nil) ///first time; paint background white
        {
            var rectpath = UIBezierPath(rect: self.bounds)
            UIColor.whiteColor().setFill()
            rectpath.fill()
            
            // this will draw all possibly set paths
            
            
            if(!grayscale){
                for e in sketch.edges
                {
//                    if CGPointEqualToPoint(e.start, e.end) //is a loop draw filled
//                    {
//                        UIColor.blackColor().setFill()
//                        e.path.fill()
//                    }
                    setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                    e.path.stroke()
                    // just draw that point to indicate it...
                    if !e.path.empty && e.start != e.end {
                        drawEdgePoints(e.start, end:e.end) //these only get drawn when lines are complete
                    }
                    
                }
                for plane in sketch.planes.planes {
                    let c = plane.color
                    c.setFill()
                    plane.path.usesEvenOddFillRule = false
                    plane.path.fill()
                }
            }
            else // this is a grayscale for print image
            {
                for e in sketch.edges
                {
                    setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                    e.path.stroke()
                }
            }
            tempIncremental = UIGraphicsGetImageFromCurrentImageContext()
        }
        tempIncremental.drawAtPoint(CGPointZero)
        //set the stroke color
        setPathStyle(path, edge:nil, grayscale:grayscale).setStroke()
        path.stroke()
        tempIncremental = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return tempIncremental
    }
    
    
    /// erase hitpoint edge
    func erase(touchPoint: CGPoint)
    {//TODO: refactor this to sketch
        for (i,e) in enumerate(sketch.edges)
        {
            if  e.hitTest(touchPoint) != nil
            {
                sketch.removeEdge(e) //remove
                forceRedraw()
            }
        }
        
    }
    
    ///makes bezier by stringing segments together
    ///creatse segments from ctrl pts
    func makeBezier(aborted:Bool=false)
    {
        if !aborted
        {
            // only use first y-value
            // or
            // move the endpoint to the middle of the line joining the second control point of the first Bezier segment and the first control point of the second Bezier segment
            var newEnd = (sketchMode == .Cut) ? CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0 ) : tempEnd
            
            if ( sketchMode == .Fold || sketchMode == .Tab)
            {
                // makes only straight horizontal fold lines
                // basically make a completely new line every movement so its only 2 points ever
                path = UIBezierPath()
                path.moveToPoint(tempStart)
                path.addLineToPoint(CGPointMake(newEnd.x,  newEnd.y))
                setPathStyle(path, edge:nil, grayscale:false)
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
            if CGPointEqualToPoint(tempEnd, tempStart) {
                path.closePath()
            }
        }
        ctr = 1
        self.setNeedsDisplay()
        
    }
    
    
    /// checks and constrains current endpoint
    func checkCurrentEnd(endpoint: CGPoint) -> Bool {
        var closed:Bool = false
        
        // only use first y-value
        // or
        // move the endpoint to the middle of the line joining the second control point of the first Bezier segment and the first control point of the second Bezier segment
        if sketchMode == .Fold || sketchMode == .Tab {
            tempEnd = CGPointMake(endpoint.x,  tempStart.y)
        } else {
            tempEnd = endpoint
        }
        
        //ignore intersections if we're just starting a line...
        if ( dist(tempStart, tempEnd) > kMinLineLength)
        {
            // test for self intersections
            if let np = Edge.hitTest(path, point:tempEnd) {
                if sketchMode != .Fold && sketchMode != .Tab {
                    tempEnd = np
                    closed = true
                }
            } else {
                // test for intersections
                if let np = sketch.vertexHitTest(tempEnd) {
                    tempEnd = np
                    closed = true
                } else if let (edge,np) = sketch.edgeHitTest(tempEnd)
                {
                    tempEnd = np
                    closed = true
                    endEdgeCollision = edge
                }
            }
        } else {
            // check that we're not closing a path
            //  needs to make sure that the path bounds are greater than minlinelength
            if sketchMode == .Cut && (path.bounds.height > kMinLineLength || path.bounds.width > kMinLineLength){
                //lets close the cut path and make a hole
                //TODO: this needs revisiting once planes is working
                tempEnd = tempStart
                closed = true
            }
        }
        return closed
    }
    
    
    /// this will set the path style as well as return the color of the path to be stroked
    func setPathStyle(path:UIBezierPath, edge:Edge?, grayscale:Bool) -> UIColor
    {
        
        var edgekind:Edge.Kind!
        var fold:Edge.Fold!
        var color:UIColor!
        
        if let e = edge
        {
            edgekind = e.kind
            fold = e.fold
            if(grayscale){
                color = e.getLaserColor()
            }
            else{
                color = e.getColor()
            }
        } else {
            edgekind = modeToEdgeKind(sketchMode)
            fold = Edge.Fold.Unknown
            if(grayscale){
                color = Edge.getLaserColor(edgekind, fold:fold)
            }
            else{
                color = Edge.getColor(edgekind, fold:fold)
            }
        }
        
        if edgekind == Edge.Kind.Fold || edgekind == Edge.Kind.Tab {
            if grayscale {
                path.setLineDash([1,10], count: 2, phase:0)
            } else {
                path.setLineDash([10,5], count: 2, phase:0)
            }
        }
        else {
            path.setLineDash(nil, count: 0, phase:0)
        }
        
        
        path.lineWidth=kLineWidth
        
        return color
    }
    
    
    func forceRedraw()
    {
        incrementalImage = nil
        endPaths.removeAll(keepCapacity: false)
        sketch.getPlanes()//evaluate into planes
        sketch.buildTabs()
        incrementalImage = bitmap(grayscale: false) // the bitmap isn't grayscale
        self.setNeedsDisplay() //draw to clear the deleted path

    //        setGameView()
    }
    
    
    func setGameView(){
    
    gameView = GameViewController()
    gameView.setButtonBG(previewImage())
    gameView.laserImage = bitmap(grayscale: true)
    gameView.planes = sketch.planes
    gameView.makeScene()
    previewButton.setBackgroundImage(gameView.previewImage(), forState: UIControlState.Normal)
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
        fold1.moveToPoint(b1)
        fold1.addLineToPoint(b2)
        asketch.addEdge(b1, end: b2, path: fold1, kind: Edge.Kind.Fold )
        
        cut1.moveToPoint(b2)
        cut1.addLineToPoint(b3)
        asketch.addEdge(b2, end: b3, path: cut1, kind: Edge.Kind.Cut )
        
        cut2.moveToPoint(b3)
        cut2.addLineToPoint(b4)
        asketch.addEdge(b3, end: b4, path: cut2, kind: Edge.Kind.Cut )
        
        
        fold2.moveToPoint(b4)
        fold2.addLineToPoint(b5)
        asketch.addEdge(b4, end: b5, path: fold2, kind: Edge.Kind.Fold )
        
        
        cut3.moveToPoint(b5)
        cut3.addLineToPoint(b6)
        asketch.addEdge(b5, end: b6, path: cut3, kind: Edge.Kind.Cut )
        
        cut4.moveToPoint(b6)
        cut4.addLineToPoint(b1)
        asketch.addEdge(b6, end: b1, path: cut4, kind: Edge.Kind.Cut )
        //
        
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
        
        return asketch
    }
    
    
    func previewImage() -> UIImage {

        return incrementalImage
        
//        UIGraphicsBeginImageContextWithOptions(sketch.drawingBounds.size, false, 0);
//        
//        //        let croppedImage = cropImage(incrementalImage,rect: sketch.drawingBounds)
//        incrementalImage.drawInRect( self.bounds, blendMode: kCGBlendModeNormal, alpha: 1)
//        //        self.drawViewHierarchyInRect(sketch.drawingBounds, afterScreenUpdates:true)
//        let copied = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//        return copied;
        
    }
    
    
    //
    //    func cropImage(image:UIImage, rect:CGRect) -> UIImage{
    //        if (image.scale > 1.0) {
    //            let rect = CGRectMake(rect.origin.x * image.scale,
    //                rect.origin.y * image.scale,
    //                rect.size.width * image.scale,
    //                rect.size.height * image.scale);
    //        }
    //
    //        let imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    //        let result = UIImage(CGImage: imageRef,)!
    //        result.scale = image.scale
    //        return result
    //    }
    
    
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
    
    
    func setButtonBG(image:UIImage){
        previewButton.setBackgroundImage(image, forState: UIControlState.Normal)
    }
    
    ///MARK: simplemode functions
    
    ///checks if can draw above fold for simple mode
    func simpleModeFoldInBounds(point: CGPoint, sketchMode: Mode) -> Bool
    {
        switch sketchMode {
        case .Fold:
            return point.y >= sketch.drivingEdge.start.y
        case .Tab:
            return point.y <= sketch.drivingEdge.start.y
        default:
            return true
        }

    }
    
    func modeToEdgeKind(sketchMode: Mode) -> Edge.Kind
    {
        switch sketchMode {
        case .Cut:
            return Edge.Kind.Cut
        case .Fold:
            return Edge.Kind.Fold
        case .Tab:
            return Edge.Kind.Tab
        default:
            return Edge.Kind.Cut
        }

    }
    
}
