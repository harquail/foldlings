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
        case VFold
        case Polygon
        
    }
    
    var path: UIBezierPath! //currently drawing path
    var incrementalImage: UIImage!  //this is a bitmap version of everything
    
    var sketchMode:  Mode = Mode.BoxFold
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
                    println("init deltaY: \(tappedF.deltaY)")
                }
                else{
                    println("No Edge Here...")
                }
            }
            else if(gesture.state == UIGestureRecognizerState.Changed){
                
                if let e = sketch.draggedEdge{
                    tappedF.deltaY = gesture.translationInView(self).y
                    println("delta: \(tappedF.deltaY)")
                    forceRedraw()
                }
                
            }
            else if(gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled){
                
                //end the drag by clearing tapped feature
                if let e = sketch.draggedEdge{
                    tappedF.deltaY = gesture.translationInView(self).y
                    sketch.tappedFeature?.activeOption = nil
                    sketch.tappedFeature = nil
                    forceRedraw()
                }
            }
        }
    }
    
    func handleFreeFormPan(sender: AnyObject){
        
        let gesture = sender as! UIPanGestureRecognizer
        if(gesture.state == UIGestureRecognizerState.Began){
            
            
            if(sketch.tappedFeature == nil){
                // make a shape with touchpoint
                var touchPoint: CGPoint = gesture.locationInView(self)
                let shape = FreeForm(start:touchPoint)
                sketch.currentFeature = shape
                sketch.currentFeature?.startPoint = gesture.locationInView(self)
                shape.endPoint = touchPoint
            }
            return
        }
        
        if sketch.tappedFeature == nil{
            
            let shape = sketch.currentFeature as! FreeForm
            // if it's been a few microseconds since we tried to add a point
            let multiplier = Float(CalculateVectorMagnitude(gesture.velocityInView(self))) * 0.5
            if(gesture.state == UIGestureRecognizerState.Changed && (Float(shape.lastUpdated.timeIntervalSinceNow) < multiplier)){
                var touchPoint: CGPoint = gesture.locationInView(self)
                shape.endPoint = touchPoint
                //set the path to a curve through the points
                path = shape.pathThroughTouchPoints()
                shape.path = path
                forceRedraw()
            }
                //close the shape when the pan gesture ends
            else if(gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled){
                
                
                path = UIBezierPath.interpolateCGPointsWithCatmullRom(shape.interpolationPoints, closed: true, alpha: 1)
                shape.path = path
                //reset path
                path = UIBezierPath()
                
                if let drawingFeature = sketch.currentFeature{
                    
                    //for feature in features -- check folds for spanning
                    drawingFeature.drivingFold = nil
                    drawingFeature.parent = nil
                    for feature in sketch.features!{
                        
                        for fold in feature.horizontalFolds{
                            if(drawingFeature.featureSpansFold(fold)){
                                
                                drawingFeature.drivingFold = fold
                                drawingFeature.parent = feature
                                
                                //set parents if the fold spans drivinf
                                if (drawingFeature.parent!.children != nil){
                                    drawingFeature.parent!.children!.append(drawingFeature)
                                }
                                else{
                                    drawingFeature.parent!.children = []
                                    drawingFeature.parent!.children!.append(drawingFeature)
                                }
                                
                                
                                //#TODO: maybe refactor this
                                
                                //fragments are the pieces of the fold created splitFoldByOcclusion
                                let fragments = drawingFeature.splitFoldByOcclusion(fold)
                                drawingFeature.parent?.replaceFold(fold, folds: fragments)
                                
                                //set cached edges
                                shape.cachedEdges = []
                                //create truncated folds
                                shape.truncateWithFolds()
                                //split paths at intersections
                                shape.cachedEdges!.extend(shape.freeFormEdgesSplitByIntersections())
                                
                                
                                println("===EDGES===")
                                println(shape.cachedEdges!)
                                
                                
                                //orphaned edges have start or end points that are not shared with any other edge
                                func printOrphanedEdges(){
                                    
                                    for edge in shape.cachedEdges!{
                                        var foundStart = false
                                        var foundEnd = false
                                        
                                        for edge2 in shape.cachedEdges!{
                                            
                                            if (edge != edge2){
                                                if(CGPointEqualToPoint(edge.start, edge2.end) || CGPointEqualToPoint(edge.start, edge2.start)){
                                                    foundStart = true
                                                }
                                                if(CGPointEqualToPoint(edge.end, edge2.start) || CGPointEqualToPoint(edge.end, edge2.end)){
                                                    foundEnd = true
                                                }
                                            }
                                            
                                        }
                                        if(!(foundStart && foundEnd)){
                                            println(edge)
                                        }
                                    }
                                }
                                
                                println("===ORPHANS===")
                                printOrphanedEdges()
                                
                            }
                        }
                    }
                }
                
                
                
                //add edges from the feature to the sketch
                sketch.features?.append(sketch.currentFeature!)
                sketch.currentFeature = nil
                sketch.refreshFeatureEdges()
                self.sketch.getPlanes()
                forceRedraw()
            }
        }
        
    }
    
    
    func handleBoxFoldPan(sender: AnyObject){
        
        let gesture = sender as! UIPanGestureRecognizer
        
        if(gesture.state == UIGestureRecognizerState.Began){
            
            var touchPoint = gesture.locationInView(self)
            
            var goodPlaceToDraw = true
            //            if let children = sketch.masterFeature?.children{
            //                for child in children{
            //                    if(child.boundingBox()!.contains(touchPoint)){
            //
            //                        //get the edge & nearest point to hit
            //                        let edge = child.featureEdgeAtPoint(touchPoint)
            //                        if let e = edge{
            //
            //                            //this is really only right for horizontal folds, not cuts...
            //                            //maybe limit to fold for now?
            //                            sketch.draggedEdge = e
            //                            e.deltaY = gesture.translationInView(self).y
            //                            println("init deltaY: \(e.deltaY)")
            //                        }
            //                        else{
            //                            println("No Edge Here...")
            //                        }
            //                        goodPlaceToDraw = false
            //                        break
            //                    }
            //                }
            //            }
            
            if(goodPlaceToDraw){
                //start a new box-fold feature
                sketch.currentFeature = BoxFold(start: touchPoint)
            }
            
        }
            //
        else if(gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled){
            
            var touchPoint: CGPoint = gesture.locationInView(self)
            
            
            
            //            if var e = sketch.draggedEdge{
            //
            //                e.start.y += e.deltaY!
            //                e.end.y += e.deltaY!
            //                let eNew =  Edge.straightEdgeBetween(e.start,end:e.end, kind:e.kind)
            //                eNew.deltaY = nil
            //
            //                sketch.addEdge(eNew)
            //
            ////                sketch.masterFeature!.invalidateEdges()
            //
            //            }
            
            //if feature spans fold, sets the drawing feature's driving fold and parent
            if let drawingFeature = sketch.currentFeature{
                
                
                //invalidate the current and master features
                drawingFeature.invalidateEdges()
                //                sketch.masterFeature!.invalidateEdges()
                drawingFeature.fixStartEndPoint()
                
                //add edges from the feature to the sketch
                sketch.features?.append(sketch.currentFeature!)
                
                if(drawingFeature.drivingFold != nil){
                    
                    let drawParent = drawingFeature.parent!
                    
                    if (drawParent.children != nil){
                        drawParent.children!.append(drawingFeature)
                    }
                    else{
                        drawParent.children = []
                        drawParent.children!.append(drawingFeature)
                        
                    }
                    drawParent.replaceFold(drawingFeature.drivingFold!,folds: drawingFeature.splitFoldByOcclusion(drawingFeature.drivingFold!))
                    
                    //                    drawingFeature.parent!.invalidateEdges()
                }
                else{
                    drawingFeature.removeFromSketch(sketch)
                    AFMInfoBanner.showWithText("Box Folds must span a single fold", style: AFMInfoBannerStyle.Error, andHideAfter: NSTimeInterval(2.5))
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
            
            
            if let drawingFeature = sketch.currentFeature{
                
                //disallow features outside the master card
                if(sketch.masterFeature!.boundingBox()!.contains(touchPoint)){
                    drawingFeature.endPoint = touchPoint
                }
                
                //for feature in features -- check folds for spanning
                drawingFeature.drivingFold = nil
                drawingFeature.parent = nil
                for feature in sketch.features!{
                    
                    // if spanning, set parent (but not children), because the feature has not been finalized
                    for fold in feature.horizontalFolds{
                        if(drawingFeature.featureSpansFold(fold)){
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
                
                
                //iterate trhough features and draw them
                if var currentFeatures = sketch.features{
                    
                    if(sketch.currentFeature != nil){
                        currentFeatures.append(sketch.currentFeature!)
                    }
                    
                    for feature in currentFeatures{
                        
                        //draw the tapped feature preview differently
                        if (feature == sketch.tappedFeature){
                            let foldHeights = feature.uniqueFoldHeights()
                            for height in foldHeights{
                                let edge = Edge.straightEdgeBetween(CGPointMake(0, height + feature.deltaY!), end: CGPointMake(10000, height + feature.deltaY!), kind: .Fold)
                                setPathStyle(edge.path, edge:edge, grayscale:grayscale).setStroke()
                                edge.path.stroke()
                
                                let fpath = (feature as! FreeForm).path!
                                setPathStyle(fpath, edge:nil, grayscale:grayscale).setStroke()
                                fpath.stroke()

                            }
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
                
                //                //print all edges
                //                for e in sketch.edges
                //                {
                //                    setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                //
                //                    //don't draw twin edges
                //                    if(!twinsOfVisited.contains(e)){
                //                        e.path.stroke()
                //                        twinsOfVisited.append(e.twin)
                //                    }
                //
                //
                //                }
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
    
    
    
    
    //this creates a popup dialog box to send the SVG version
    // this gets the path and SVG to print and then be sent to
    // a laser cutter by user.
    // TODO:save this path to a file
    func svgImage() -> String{
        // get CGPaths from edges and map to string of svgs
        var edgesVisited:[Edge] = []
        var paths:[String] = sketch.edges.map({
            if(!edgesVisited.contains($0)){
                edgesVisited.append($0.twin)
                edgesVisited.append($0)
                // if it is a fold then create dash stroke
                if $0.kind == .Fold{
                    return "\n<path stroke-dasharray=\"2,10\" d= \"" + SVGPathGenerator.svgPathFromCGPath($0.path.CGPath) + "\"/> "
                }
                // if not, normal stroke
                return "\n<path d= \"" + SVGPathGenerator.svgPathFromCGPath($0.path.CGPath) + "\"/> "
            }
            return ""
        })
        paths.append("\n</g>\n</svg>")
        let svgString = paths.reduce("<svg version=\"1.1\" \nbaseProfile=\"full\" \nheight=\" \(self.bounds.height)\" width=\"\(self.bounds.width)\"\nxmlns=\"http://www.w3.org/2000/svg\"> \n<g fill=\"none\" stroke=\"black\" stroke-width=\".5\">") { $0 + $1 }// concatenate the string
        
        return svgString
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
