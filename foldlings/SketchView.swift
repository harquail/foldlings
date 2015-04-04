//
//  DrawView.swift
//  foldlings
//
//
//

import UIKit

class SketchView: UIView {
    
    @IBOutlet var previewButton: UIButton!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var xButton: UIButton!
    
    enum Mode {
        case Erase
        case Cut
        case Fold
        case Tab
        case Mirror
        case Track
        case Slider
        case BoxFold
    }
    
    @IBOutlet var normalButtons: [UIButton]!
    @IBOutlet var templatingButtons: [UIButton]!
    
    var path: UIBezierPath! //currently drawing path
    var incrementalImage: UIImage!  //this is a bitmap version of everything
    var pts: [CGPoint]! // we now need to keep track of the four points of a Bezier segment and the first control point of the next segment
    var ctr: Int = 0
    var tempStart:CGPoint = CGPointZero // these keep track of point while drawing
    var tempEnd:CGPoint = CGPointZero
    var sketchMode:  Mode = Mode.Cut
    var cancelledTouch: UITouch?  //if interrrupted say on intersection
    var sketch: Sketch!
    var startEdgeCollision:Edge?
    var endEdgeCollision:Edge?
    var gameView = GameViewController()
    
    let redrawPriority = DISPATCH_QUEUE_PRIORITY_DEFAULT
    let redrawLockQueue = dispatch_queue_create("com.foldlings.LockGetPlanesQueue", nil)
    var redrawing:Bool = false
    var canPreview:Bool = true
    
    
    
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
        sketch = Sketch(at: 0, named:"placeholder")
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
    
    func handleLongPress(sender: AnyObject) {
        print("\nLOOOONG PRESSS\n")
        
    }
    
    func handlePan(sender: AnyObject) {
        
        let gesture = sender as! UIPanGestureRecognizer
        
        if(gesture.state == UIGestureRecognizerState.Began){
            
            var touchPoint = gesture.locationInView(self)
            
            //meow?
            //            gesture.translationInView(<#view: UIView#>)
            //if this is a good place to draw a new feature
            var goodPlaceToDraw = true
            if let children = sketch.masterFeature?.children{
                
                for child in children{
                    if(child.boundingBox()!.contains(touchPoint)){
                        
                        //get the edge & nearest point to hit
                        let edge = child.featureEdgeAtPoint(touchPoint)
                        if let e = edge{
                            
                            //this is really only right for horizontal folds, not cuts...
                            //maybe limit to fold for now?
                            sketch.draggedEdge = e
                            e.deltaY = gesture.translationInView(self).y
                            
                            println("init deltaY: \(e.deltaY)")
                        }
                        else{
                            println("No Edge Here...")
                        }
                        
                        //                        println("OUTSIDE LOOP")
                        goodPlaceToDraw = false
                        break
                    }
                }
            }
            
            
            if(goodPlaceToDraw){
                //start a new box-fold feature
                sketch.currentFeature = BoxFold(start: touchPoint)
            }
            
        }
        else if(gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled){
            
            var touchPoint: CGPoint = gesture.locationInView(self)
            
            if var e = sketch.draggedEdge{
                
                e.start.y += e.deltaY!
                e.end.y += e.deltaY!
                let eNew =  Edge.straightEdgeBetween(e.start,end:e.end, kind:e.kind)
                eNew.deltaY = nil
                
                sketch.addEdge(eNew)

                sketch.masterFeature!.invalidateEdges()

            }
            
            
            if let drawingFeature = sketch.currentFeature{
                
                //invalidate the current and master features
                drawingFeature.invalidateEdges()
                sketch.masterFeature!.invalidateEdges()
                drawingFeature.fixStartEndPoint()
                                
                //add edges from the feature to the sketch
                sketch.features?.append(sketch.currentFeature!)
                
                if(drawingFeature.drivingFold != nil){
                    
                    if (drawingFeature.parent!.children != nil){
                        drawingFeature.parent!.children!.append(drawingFeature)
                    }
                    else{
                        drawingFeature.parent!.children = []
                        drawingFeature.parent!.children!.append(drawingFeature)
//                        print("~~~ADDED FIRST CHILD~~~\n\n")
                        
                    }
                    drawingFeature.parent!.invalidateEdges()
                    
                }
                
                sketch.refreshFeatureEdges()
                
                //clear the current feature
                sketch.currentFeature = nil
            }
            
            self.sketch.getPlanes()
            forceRedraw()
            
        }
        else if(gesture.state == UIGestureRecognizerState.Changed){
            
            var touchPoint: CGPoint = gesture.locationInView(self)
            
            if let e = sketch.draggedEdge{
                e.deltaY = gesture.translationInView(self).y
                println("delta: \(e.deltaY)")
            }
            
            if let drawingFeature = sketch.currentFeature{
                
                //disallow features outside the master card
                if(sketch.masterFeature!.boundingBox()!.contains(touchPoint)){
                    drawingFeature.endPoint = touchPoint
                }
                
                
                //for feature in features -- check folds for spanning
                drawingFeature.drivingFold = nil
                drawingFeature.parent = nil
                for feature in sketch.features!{
                    
                    for fold in feature.horizontalFolds{
                        if(featureSpansFold(sketch.currentFeature, fold:fold)){
                            drawingFeature.drivingFold = fold
                            drawingFeature.parent = feature
                            
                            break;
                        }
                    }
                    
                }

                // box folds have different behaviors if they span the driving edge
                
                drawingFeature.invalidateEdges()
                
                forceRedraw()
                
            }
        }
        
    }
    
    

    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        self.touchesEnded(touches, withEvent: event)
    }
    
    
    func featureSpansFold(feature:FoldFeature!,fold:Edge)->Bool{
        
        //feature must be inside fold x bounds
        if(!(feature.startPoint!.x > fold.start.x && feature.endPoint!.x > fold.start.x  &&  feature.startPoint!.x < fold.end.x && feature.endPoint!.x < fold.end.x   )){
            return false
        }
        
        func pointsByY(a:CGPoint,b:CGPoint)->(min:CGPoint,max:CGPoint){
            return (a.y < b.y) ? (a,b) : (b,a)
        }
        
        let sorted = pointsByY(feature.startPoint!, feature.endPoint!)
        return (sorted.min.y < fold.start.y  && sorted.max.y > fold.start.y)
        
    }
    
    /// constructs a greyscale bitmap preview image of the sketch
    func bitmap(#grayscale:Bool, circles:Bool = true) -> UIImage {
        
        let startTime = CFAbsoluteTimeGetCurrent()/// taking time
        
        
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
                // print planes first if exist
                for plane in sketch.planes.planes {
                    let c = plane.color
                    //set pleasing colors here based on orientation
                    c.setFill()
                    plane.path.usesEvenOddFillRule = false
                    plane.path.fill()
                }
                
                var twinsOfVisited = [Edge]()
                

                //iterrte trhough features and draw them
                if var currentFeatures = sketch.features{
                        
                        if(sketch.currentFeature != nil){
                            currentFeatures.append(sketch.currentFeature!)
                        }
                        
                        for feature in currentFeatures{
                            //                    if let feature = currentFeature{
                            if(feature.startPoint != nil && feature.endPoint != nil){
                                let edges = feature.getEdges()
                                
                                for e in edges
                                {
                                    setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                                    e.path.stroke()
                                    //                                //don't draw twin edges
                                    //                                if(!twinsOfVisited.contains(e)){
                                    //                                    e.path.stroke()
                                    //                                    twinsOfVisited.append(e.twin)
                                    //                                }
                                    
                                    
                                }
                                
                            }
                        }
                }
                
                //print all edges
                for e in sketch.edges
                {
                    setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                    
                    //don't draw twin edges
                    if(!twinsOfVisited.contains(e)){
                        e.path.stroke()
                        twinsOfVisited.append(e.twin)
                    }
                    
                    
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
        
        //taking time
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        //        println("Time elapsed for bitmap: \(timeElapsed) s")
        
        return tempIncremental
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
        if sketchMode == .Tab {
            tempEnd = CGPointMake(endpoint.x,  tempStart.y)
        }
            // allow non-horizontal folds, snapping to horizonal & vertical
        else if sketchMode == .Fold {
            let snapThreshold = 10
            if(abs(Int(tempStart.x) - Int(endpoint.x)) < snapThreshold){
                tempEnd = CGPointMake(tempStart.x, endpoint.y)
            }
            else if(abs(Int(tempStart.y) - Int(endpoint.y)) < snapThreshold){
                tempEnd = CGPointMake(endpoint.x, tempStart.y)
            }
            else{
                tempEnd = endpoint
            }
            
        }
        else {
            tempEnd = endpoint
        }
        
        //ignore intersections if we're just starting a line...
        if ( CGPointGetDistance(tempStart, tempEnd) > kMinLineLength)
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
        var color:UIColor!
        
        if let e = edge
        {
            edgekind = e.kind
            if(grayscale){
                color = e.getLaserColor()
            }
            else{
                color = e.getColor()
            }
        } else {
            edgekind = modeToEdgeKind(sketchMode)
            if(grayscale){
                color = Edge.getLaserColor(edgekind)
            }
            else{
                color = Edge.getColor(edgekind)
            }
        }
        
        if edgekind == Edge.Kind.Fold {
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
    
    
    //    var timeSinceRedraw = NSDate(timeIntervalSinceNow: -0.9)
    //    let krefreshTime = 0.1
    func forceRedraw()
    {
        //        timeSinceRedraw.timeIntervalSinceNow > -krefreshTime
        if(!self.redrawing){
            //            timeSinceRedraw = NSDate(timeIntervalSinceNow: 0)
            dispatch_async(dispatch_get_global_queue(self.redrawPriority, 0), {
                self.redrawing = true
                dispatch_sync(self.redrawLockQueue) {
                    
                    //in template mode, only get planes when features end!
                    

                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    dispatch_sync(self.redrawLockQueue) {
                        self.incrementalImage = nil
                        self.incrementalImage = self.bitmap(grayscale: false) // the bitmap isn't grayscale
                        self.setNeedsDisplay() //draw to clear the deleted path
                        self.redrawing = false
                    }
                })
            })
            
            dispatch_sync(self.redrawLockQueue) {
                self.incrementalImage = nil
                self.incrementalImage = self.bitmap(grayscale: false) // the bitmap isn't grayscale
                self.setNeedsDisplay() //draw to clear the deleted path
            }
        }
        
    }
    
    
    func setGameView(){
        gameView = GameViewController()
        //        gameView.setButtonBG(previewImage())
        gameView.laserImage = bitmap(grayscale: true)
        gameView.planes = sketch.planes
        gameView.makeScene()
        //        previewButton.setBackgroundImage(gameView.previewImage(), forState: UIControlState.Normal)
    }
    
    func simpleSketch(dex:Int, name:String)->Sketch
    {
        var asketch = Sketch(at:dex, named:name)
        
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

    
    
    
    func drawCircle(point: CGPoint) ->UIBezierPath
    {
        UIColor.redColor().setStroke()
        let c = UIBezierPath()
        c.addArcWithCenter(point, radius:5.0, startAngle:0.0, endAngle:CGFloat(2.0*M_PI), clockwise:true)
        c.stroke()
        return c
    }
    
    
    func setButtonBG(image:UIImage){
        //        previewButton.setBackgroundImage(image, forState: UIControlState.Normal)
    }
    
    
    func modeToEdgeKind(sketchMode: Mode) -> Edge.Kind
    {
        switch sketchMode {
        case .Cut:
            return Edge.Kind.Cut
        case .Fold:
            return Edge.Kind.Fold
        default:
            return Edge.Kind.Cut
        }
        
    }
    
    
    func hideXCheck(){
        checkButton.userInteractionEnabled = false
        checkButton.alpha = 0
        xButton.userInteractionEnabled = false
        xButton.alpha = 0
        print("shown")
    }
    
    func showXCheck(){
        checkButton.userInteractionEnabled = true
        checkButton.alpha = 1
        xButton.userInteractionEnabled = true
        xButton.alpha = 1
        print("hidden")
        
    }
    
}
