//
//  DrawView.swift
//  foldlings
//
//
//

import UIKit

class SketchView: UIView {
    
    // Buttons
    @IBOutlet var previewButton: UIButton!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var xButton: UIButton!
    var name:String = "placeHolder"
    var index:Int = 0
    
    //Drawing Modes
    enum Mode:String {
        case Erase = "Erase"
        case Cut = "Cut"
        case Mirror = "Mirror"
        case Track = "Track"
        case Slider = "Slider"
        case BoxFold = "BoxFold"
        case FreeForm = "FreeForm"
        case VFold = "VFold"
        case Polygon = "Polygon"
        
    }
    
    //Initiated Global Variables
    var path: UIBezierPath! //currently drawing path
    var incrementalImage: UIImage!  //this is a bitmap version of everything
    var sketchMode:  Mode = Mode.BoxFold
    var sketch: Sketch!
    var startEdgeCollision:Edge?
    var endEdgeCollision:Edge?
    var gameView = GameViewController()
    
    // Threading
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
        sketch = Sketch(at: 0, named:"unitialized")
        sketch.getPlanes()
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
    
    func handleLongPress(sender: AnyObject)
    {
        print("\nLOOOONG PRESSS\n")
        
    }
    
    func handlePan(sender: AnyObject) {
        if(sketch.tappedFeature != nil){
            
            switch(sketch.tappedFeature!.activeOption!){
            case .MoveFolds:
                handleMoveFoldPan(sender)
            default: break
            }
        }
        else{
            switch (sketchMode) {
            case .BoxFold:
                handleBoxFoldPan(sender)
            case .FreeForm:
                handleFreeFormPan(sender)
            default:
                break
            }
        }
        
        
    }
    
    var savedOriginalHeights:[CGFloat] = []
    func handleMoveFoldPan(sender: AnyObject){
        
        let gesture = sender as! UIPanGestureRecognizer
        if let tappedF = sketch.tappedFeature{
            
            if(gesture.state == UIGestureRecognizerState.Began){
                //get the edge & nearest point to hit
                let edge = tappedF.featureEdgeAtPoint(gesture.locationInView(self))
                if let e = edge{
                    // keep track of change to dragged edges
                    sketch.draggedEdge = e
                    tappedF.deltaY = gesture.translationInView(self).y
                    savedOriginalHeights = tappedF.uniqueFoldHeights()
                    
                }
                else{
                    println("No Edge Here...")
                }
            }
            else if(gesture.state == UIGestureRecognizerState.Changed){
                
                if let e = sketch.draggedEdge{
                    tappedF.deltaY = gesture.translationInView(self).y
                    //                    println("delta: \(tappedF.deltaY)")
                    
                    //if boxfold, make new edges & invalidate
                    if let box = tappedF as? BoxFold{
                        boxFoldDragEdge(box)
                    }
                    
                    forceRedraw()
                }
                
            }
            else if(gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled){
                
                //end the drag by clearing tapped feature
                if let e = sketch.draggedEdge{
                    if let shape = tappedF as? FreeForm{
                        
                        tappedF.deltaY = gesture.translationInView(self).y
                        
                        let originalHeights = tappedF.uniqueFoldHeights()
                        //get current heights
                        let heights = shape.foldHeightsWithTransform(savedOriginalHeights, draggedEdge: e, masterFold: tappedF.drivingFold!)
                        // clear intersections & edges
                        shape.featureEdges = []
                        shape.horizontalFolds = []
                        //clear all intersections except those with driving fold
                        shape.intersections = shape.intersectionsWithDrivingFold
                        
                        let shapePath = shape.path!
                        
                        for height in heights{
                            //create
                            
                            let testEdge = Edge.straightEdgeBetween(CGPointMake(shape.boundingBox()!.minX,height), end: CGPointMake(shape.boundingBox()!.maxX,height), kind: .Cut, feature: shape)
                            
                            
                            
                            let success = shape.tryIntersectionTruncation(testEdge.path,testPathTwo: shapePath)
                            if !success{
                                
                                for fold in shape.topTruncations{
                                    shape.tryIntersectionTruncation(fold.path,testPathTwo: shapePath)
                                }
                                
                                for fold in shape.bottomTruncations{
                                    shape.tryIntersectionTruncation(fold.path,testPathTwo: shapePath)
                                    
                                }
                                
                                //                                println("Failed to intersect with fold at \(height)");
                                
                                AFMInfoBanner.showWithText("Failed to intersect with fold at \(height)", style: AFMInfoBannerStyle.Error, andHideAfter: NSTimeInterval(5))
                            }
                            else{
                                println("success: \(height)")
                            }
                        }
                        //                        println("JUST BEFORE FEATUREEDGES EXTEND")
                        
                        sketch.tappedFeature!.featureEdges?.extend(shape.freeFormEdgesSplitByIntersections())
                        //                        println("ADD TABS")
                        shape.addTabs(heights,savedHeights: savedOriginalHeights)
                        
                        
                        sketch.removeFeatureFromSketch(shape,healOnDelete:false)
                        sketch.addFeatureToSketch(shape, parent: shape.parent!)
                        
                        
                        sketch.tappedFeature?.activeOption = nil
                        sketch.tappedFeature = nil
                        
                        self.sketch.getPlanes()
                        forceRedraw()
                    }
                    else if let box = tappedF as? BoxFold{
                        tappedF.deltaY = gesture.translationInView(self).y
                        boxFoldDragEdge(box)
                        
                        /// removing the feature and re-adding it
                        //                        box.invalidateEdges()
                        sketch.removeFeatureFromSketch(box, healOnDelete: false)
                        sketch.addFeatureToSketch(box, parent: box.parent!)
                        
                        sketch.tappedFeature?.activeOption = nil
                        sketch.tappedFeature = nil
                        
                        
                        
                        //                        sketch.refreshFeatureEdges()
                        self.sketch.getPlanes()
                        
                        forceRedraw()
                        
                        
                    }
                    else{
                        println("unexpected feature type")
                    }
                }
            }
        }
    }
    func boxFoldDragEdge(tappedF:BoxFold){
        let originalHeights = tappedF.uniqueFoldHeights()
        
        let newHeights = tappedF.foldHeightsWithTransform(savedOriginalHeights, draggedEdge: sketch.draggedEdge!, masterFold: tappedF.drivingFold!);
        
        let deltaStart = originalHeights[0] - newHeights[0]
        let deltaEnd = originalHeights[2] - newHeights[2]
        
        tappedF.startPoint! = CGPointMake(tappedF.startPoint!.x, tappedF.startPoint!.y - deltaStart)
        tappedF.endPoint! = CGPointMake(tappedF.endPoint!.x, tappedF.endPoint!.y - deltaEnd)
        tappedF.invalidateEdges()
        
    }
    
    // Draws Free-form Shape
    func handleFreeFormPan(sender: AnyObject)
    {
        
        //println("handle")
        let gesture = sender as! UIPanGestureRecognizer
        if sketch.tappedFeature == nil{
            
            switch (gesture.state)
            {
                
            case UIGestureRecognizerState.Began:
                // make a shape with touchpoint
                var touchPoint: CGPoint = gesture.locationInView(self)
                var shape: FreeForm = FreeForm(start:touchPoint)
                sketch.currentFeature = shape
                sketch.currentFeature?.startPoint = gesture.locationInView(self)
                shape.endPoint = touchPoint
                
            case UIGestureRecognizerState.Changed:
                let shape = sketch.currentFeature as! FreeForm
                // if it's been a few microseconds since we tried to add a point
                let multiplier = Float(CalculateVectorMagnitude(gesture.velocityInView(self))) * 0.5
                
                if(Float(shape.lastUpdated.timeIntervalSinceNow) < multiplier){
                    var touchPoint: CGPoint = gesture.locationInView(self)
                    shape.endPoint = touchPoint
                    //set the path to a curve through the points
                    path = shape.pathThroughTouchPoints()
                    shape.path = path
                    forceRedraw()
                }
                
            case UIGestureRecognizerState.Ended, UIGestureRecognizerState.Cancelled:
                
                let shape = sketch.currentFeature as! FreeForm
                path = UIBezierPath.interpolateCGPointsWithCatmullRom(shape.interpolationPoints, closed: true, alpha: 1)
                shape.path = path
                //reset path
                path = UIBezierPath()
                
                //for feature in features -- check folds for spanning
                outer: for feature in sketch.features
                {
                    for fold in feature.horizontalFolds
                    {
                        if(shape.featureSpansFold(fold))
                        {
                            shape.drivingFold = fold
                            shape.parent = feature
                            //set parents if the fold spans driving
                            shape.parent!.children.append(shape)
                            
                            //fragments are the pieces of the fold created splitFoldByOcclusion
                            let fragments = shape.splitFoldByOcclusion(fold)
                            sketch.replaceFold(shape.parent!, fold: fold, folds: fragments)
                            //set cached edges
                            shape.featureEdges = []
                            //create truncated folds
                            shape.truncateWithFolds()
                            //split paths at intersections
                            shape.featureEdges!.extend(shape.freeFormEdgesSplitByIntersections())
                            shape.setTopBottomTruncations()
                            shape.parent = feature
                            break outer;
                            
                        }
                    }
                }
                // if feature didn't span a fold, then make it a hole?
                // find parent for hole
                if shape.parent == nil
                {
                    shape.parent = sketch.featureHitTest(shape.path!.firstPoint())
                }
                
                //                shape.shiftEdgeEndpoints()
                sketch.addFeatureToSketch(shape, parent: shape.parent!)
                
                sketch.currentFeature = nil
                self.sketch.getPlanes()
                forceRedraw()
                
                //                println(sketch.almostCoincidentEdgePoints())
                
            default:
                break
            }
        }
        
    }
    
    //draws boxfolds and adds them to features if valid
    func handleBoxFoldPan(sender: AnyObject)
    {
        var gesture = sender as! UIPanGestureRecognizer
        
        switch gesture.state
        {
            // gesture is just starting create a boxfold where the touch began
        case UIGestureRecognizerState.Began:
            var touchPoint = gesture.locationInView(self)
            sketch.currentFeature = BoxFold(start: touchPoint)
            
            // while user is dragging
        case UIGestureRecognizerState.Changed:
            var touchPoint: CGPoint = gesture.locationInView(self)
            
            if let drawingFeature = sketch.currentFeature
            {
                //disallow features outside the master card
                if(sketch.masterFeature!.boundingBox()!.contains(touchPoint))
                {
                    drawingFeature.endPoint = touchPoint
                }
                
                //for feature in features -- check folds for spanning
                drawingFeature.drivingFold = nil
                drawingFeature.parent = nil
                
                var foldsCrossed = 0
                outer:for feature in sketch.features
                {
                    // if spanning, set parent (but not children), because the feature has not been finalized
                    for fold in feature.horizontalFolds
                    {
                        if(drawingFeature.featureSpansFold(fold))
                        {
                            drawingFeature.drivingFold = fold
                            drawingFeature.parent = feature
                            foldsCrossed++;
                            //                            break outer;
                        }
                    }
                }
                
                
                //box folds that span more than one fold are invalid
                if(foldsCrossed > 1){
                    drawingFeature.drivingFold = nil
                    drawingFeature.parent = nil
                }
                // box folds have different behaviors if they span the driving edge
                drawingFeature.invalidateEdges()
                forceRedraw()
            }
            
            
            
        case UIGestureRecognizerState.Ended, UIGestureRecognizerState.Cancelled:
            
            var touchPoint: CGPoint = gesture.locationInView(self)
            
            //if feature spans fold, sets the drawing feature's driving fold and parent
            if let drawingFeature = sketch.currentFeature
            {
                drawingFeature.invalidateEdges()
                // makes the start point the top left point and sorts horizontal folds
                drawingFeature.fixStartEndPoint()
                
                // if is a complete boxfold with driving fold in middle
                if(drawingFeature.drivingFold != nil)
                {
                    let drawParent = drawingFeature.parent!
                    
                    // splits the driving fold of the parent
                    // removes and adds edges to sketch
                    let newFolds = drawingFeature.splitFoldByOcclusion(drawingFeature.drivingFold!)
                    sketch.replaceFold(drawParent, fold: drawingFeature.drivingFold!,folds: newFolds)
                    // add feature to sketch features and to parent's children
                    sketch.addFeatureToSketch(drawingFeature, parent: drawParent)
                    
                }
                else{
                    //                    sketch.removeFeatureFromSketch(drawingFeature)
                    AFMInfoBanner.showWithText("Box folds must span a single fold", style: .Error, andHideAfter: NSTimeInterval(2.5))
                    
                }
                
                //clear the current feature
                sketch.currentFeature = nil
                //sketch.getPlanes()
                forceRedraw()
            }
            
            
            
        default:
            break
        }
    }
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!)
    {
        self.touchesEnded(touches, withEvent: event)
    }
    
    // creates a bitmap preview image of sketch
    func bitmap(#grayscale:Bool, circles:Bool = true) -> UIImage
    {
        let startTime = CFAbsoluteTimeGetCurrent()/// taking time
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        
        var color:UIColor = UIColor.blackColor()
        var tempIncremental = incrementalImage
        
        if(grayscale){tempIncremental = nil}
        
        if(tempIncremental == nil) ///first time; paint background white
        {
            var rectpath = UIBezierPath(rect: self.bounds)
            UIColor.whiteColor().setFill()
            rectpath.fill()
            
            // this will draw all possibly set paths
            
            if(!grayscale)
            {
                // print planes first if exist
                for plane in sketch.planes.planes
                {
                    let c = plane.color
                    //set pleasing colors here based on orientation
                    c.setFill()
                    plane.path.usesEvenOddFillRule = false
                    plane.path.fill()
                }
                
                var twinsOfVisited = [Edge]()
                //iterate through features and draw them
                var currentFeatures = sketch.features
                
                if sketch.features.count > 0{
                    
                    if(sketch.currentFeature != nil){
                        currentFeatures.append(sketch.currentFeature!)
                    }
                    
                    for feature in currentFeatures{
                        let shape = feature as? FreeForm
                        
                        //draw the tapped feature preview
                        if (feature == sketch.tappedFeature && shape != nil){
                            
                            /// TODO: only for free-form
                            let invertedPath = UIBezierPath(rect: CGRectInfinite)
                            
                            let pathAroundFeature = shape!.path!
                            invertedPath.appendPath(pathAroundFeature)
                            
                            let context =  UIGraphicsGetCurrentContext()
                            CGContextSaveGState(context);
                            
                            CGContextAddPath(context, invertedPath.CGPath);
                            let boundingRect = CGContextGetClipBoundingBox(context);
                            
                            CGContextAddRect(context, boundingRect);
                            CGContextEOClip(context)
                            
                            let foldHeights = feature.foldHeightsWithTransform(feature.uniqueFoldHeights(), draggedEdge: sketch.draggedEdge!, masterFold: feature.drivingFold!)
                            
                            for height in foldHeights{
                                let edge = Edge.straightEdgeBetween(CGPointMake(sketch.masterFeature!.startPoint!.x, height), end: CGPointMake(sketch.masterFeature!.endPoint!.x, height), kind: .Fold, feature:feature)
                                setPathStyle(edge.path, edge:edge, grayscale:grayscale).setStroke()
                                edge.path.stroke()
                            }
                            
                            CGContextRestoreGState(context);
                            
                            //draw path
                            setPathStyle(pathAroundFeature, edge:nil, grayscale:grayscale).setStroke()
                            pathAroundFeature.stroke()
                        }
                        else{
                            if(feature.startPoint != nil && feature.endPoint != nil){
                                let edges = feature.getEdges()
                                for e in edges
                                {
                                    setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                                    e.path.stroke()
                                }
                            }
                        }
                    }
                }
                
                //                // all edges
                //                for e in sketch.edges
                //                {
                //                    setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                //
                //                    // don't draw twin edges
                //                    if(!twinsOfVisited.contains(e))
                //                    {
                //                        e.path.stroke()
                //                        twinsOfVisited.append(e.twin)
                //                    }
                //                }
            }
                
                // if grayscale
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
    
    /// this will set the path style as well as return the color of the path to be stroked
    func setPathStyle(path:UIBezierPath, edge:Edge?, grayscale:Bool) -> UIColor
    {
        var edgekind:Edge.Kind!
        var color:UIColor!
        
        if let e = edge
        {
            edgekind = e.kind
            
            if(grayscale){color = e.getLaserColor()}
            else{color = e.getColor()}
        }
            
        else
        {
            edgekind = .Cut
            
            if(grayscale){color = Edge.getLaserColor(edgekind)}
            else{color = Edge.getColor(edgekind)}
        }
        
        if edgekind == Edge.Kind.Fold {
            
            if grayscale {path.setLineDash([1,10], count: 2, phase:0)}
            else {path.setLineDash([10,5], count: 2, phase:0)}
        }
            
        else {path.setLineDash(nil, count: 0, phase:0)}
        
        path.lineWidth=kLineWidth
        return color
    }
    
    
    func forceRedraw()
    {
        if(!self.redrawing)
        {
            //            dispatch_async(dispatch_get_global_queue(self.redrawPriority, 0),
            //                {
            self.redrawing = true
            //dispatch_sync(self.redrawLockQueue){}
            //
            //                    dispatch_async(dispatch_get_main_queue(),
            //                        {
            //                            dispatch_sync(self.redrawLockQueue)
            //                                {
            self.incrementalImage = nil
            self.incrementalImage = self.bitmap(grayscale: false) // the bitmap isn't grayscale
            self.setNeedsDisplay() //draw to clear the deleted path
            self.redrawing = false
            //                            }
            //                    })
            //            })
        }
        //        dispatch_sync(self.redrawLockQueue)
        //            {
        self.incrementalImage = nil
        self.incrementalImage = self.bitmap(grayscale: false) // the bitmap isn't grayscale
        self.setNeedsDisplay() //draw to clear the deleted path
        //        }
        
    }
    
    //This function creates the contents of the SVG file
    // converts CGPaths into SVG path and organizes
    // it in correct xml format
    func svgImage() -> String
    {
        var edgesVisited:[Edge] = []
        
        var paths:[String] = sketch.edges.map({
            if(!edgesVisited.contains($0))
            {
                edgesVisited.append($0.twin)
                edgesVisited.append($0)
                // if it is a fold then create dash stroke
                // 4, 5 for mountain.  2, 10 for valley
                if $0.kind == .Fold
                {
                    if (self.sketch.isHill($0)){
                        return "\n<path stroke-dasharray=\"20,10\" d= \"" + SVGPathGenerator.svgPathFromCGPath($0.path.CGPath) + "\"/> "
                    }
                    return "\n<path stroke-dasharray=\"20,10,7,5,7,10\" d= \"" + SVGPathGenerator.svgPathFromCGPath($0.path.CGPath) + "\"/> "

                }
                // if not, normal stroke
                return "\n<path d= \"" + SVGPathGenerator.svgPathFromCGPath($0.path.CGPath) + "\"/> "
            }
            return ""
        })
        
        //add closing tags
        paths.append("\n</g>\n</svg>")
        
        // concatenate all the paths into one string and
        // insert beginning tags for svg file
        let svgString = paths.reduce("<svg version=\"1.1\" \nbaseProfile=\"full\" \nheight=\" \(self.bounds.height)\" width=\"\(self.bounds.width)\"\nxmlns=\"http://www.w3.org/2000/svg\"> \n<g fill=\"none\" stroke=\"black\" stroke-width=\".1\">") { $0 + $1 }
        
        return svgString
    }
    
    
    //    func setButtonBG(image:UIImage){
    //        //        previewButton.setBackgroundImage(image, forState: UIControlState.Normal)
    //    }
    
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
    
    
    func hideXCheck()
    {
        checkButton.userInteractionEnabled = false
        checkButton.alpha = 0
        xButton.userInteractionEnabled = false
        xButton.alpha = 0
        print("shown")
    }
    
    func showXCheck()
    {
        checkButton.userInteractionEnabled = true
        checkButton.alpha = 1
        xButton.userInteractionEnabled = true
        xButton.alpha = 1
        print("hidden")
        
    }
    
}
