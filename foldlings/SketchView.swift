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
        case Mirror
        case Track
        case Slider
        case BoxFold
        case FreeForm
    }
    
    var path: UIBezierPath! //currently drawing path
    var incrementalImage: UIImage!  //this is a bitmap version of everything
    
    var pts: [CGPoint]! // we now need to keep track of the four points of a Bezier segment and the first control point of the next segment
    var ctr: Int = 0
    var tempStart:CGPoint = CGPointZero // these keep track of point while drawing
    var tempEnd:CGPoint = CGPointZero
    var sketchMode:  Mode = Mode.BoxFold
    var cancelledTouch: UIPanGestureRecognizer?  //if interrrupted say on intersection
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
        
        switch (sketchMode) {
        case .BoxFold:
            handleBoxFoldPan(sender)
        case .FreeForm:
            handleFreeFormPan(sender)
        default:
            break
        }
        
        
    }
    
    func handleFreeFormPan(sender: AnyObject){
        let gesture = sender as! UIPanGestureRecognizer
        
        if(gesture.state == UIGestureRecognizerState.Began){
            
            var touchPoint: CGPoint = gesture.locationInView(self)
            sketch.currentFeature = FreeForm(start:touchPoint)
            startEdgeCollision = nil //reset edge collisions to nil
            endEdgeCollision = nil
            
//            // ignore touch if outside of bounds
//            if !sketch.checkInBounds(touchPoint) {
//                cancelledTouch = gesture
//                return
//            }
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

            
        }
        else if(gesture.state == UIGestureRecognizerState.Changed){
            
            var touchPoint: CGPoint = gesture.locationInView(self)
            
            // ignore cancelledTouch
            if cancelledTouch == nil || cancelledTouch! != gesture {
                    // check if we've snapped or aborted
                    var abort:Bool = checkCurrentEnd(touchPoint)
                    ctr=ctr+1
                    pts[ctr] = tempEnd
                    
                    if (ctr == 4)
                    {
                        makeBezier() //create bezier curves
                    }
                    
                    if abort {
                        cancelledTouch = gesture
                    }
            }
            else{
                println("CANCELLED GESTURE")
            }
        }
        else if(gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled){
            
            
            var endPoint = tempEnd
            let startPoint = tempStart
                if path.bounds.height > kMinLineLength || path.bounds.width > kMinLineLength
                {
                    var se1:Edge?
                    var se2:Edge?
                    //splits edges on collision
                    if let startColEdge = startEdgeCollision {
                        // if there are problems with circles might be here
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
        }
        
        
    }
    
    /// erase hitpoint edge
    /// needs to be refactored for features
    func erase(touchPoint: CGPoint) {
        if var (edge, np) = sketch.edgeHitTest(touchPoint)
        {
            if edge != nil && ( (!edge!.isMaster)){
                sketch.removeEdge(edge!)
                forceRedraw()
            }
        } else if var plane = sketch.planeHitTest(touchPoint) {
            sketch.planes.removePlane(plane)
        }
    }
    
    func handleBoxFoldPan(sender: AnyObject){
        
        let gesture = sender as! UIPanGestureRecognizer
        
        if(gesture.state == UIGestureRecognizerState.Began){
            
            var touchPoint = gesture.locationInView(self)
            
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
                
                //clear all the edges for all features and re-create them.  This is bad, we'll be smarter later
                
                for edge in sketch.edges{
                    sketch.removeEdge(edge)
                }
                
                print("FEATURES: \(sketch.features?.count)\n")
                for feature in sketch.features!{
                    
                    //                print("FEATURE: \(feature.getEdges().count)\n")
                    let edgesToAdd = feature.getEdges()
                    for edge in edgesToAdd{
                        sketch.addEdge(edge)
                    }
                    print("SKETCH: \(sketch.edges.count)\n")
                    
                    
                }
                
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
                        if(FoldFeature.featureSpansFold(sketch.currentFeature, fold:fold)){
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
            
            pts[3] = newEnd
            if path.empty { path.moveToPoint(pts[0]) } //only do moveToPoint for 1st point
            path.addCurveToPoint(pts[3], controlPoint1: pts[1], controlPoint2: pts[2])// add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
            
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
        
       
            tempEnd = endpoint
        
        //ignore intersections if we're just starting a line...
        if ( CGPointGetDistance(tempStart, tempEnd) > kMinLineLength)
        {
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
