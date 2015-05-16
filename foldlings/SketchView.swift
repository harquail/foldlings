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
    
    //Drawing Modes
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
        sketch = Sketch(at: 0, named:"placeholder")
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
    
    // Draws Free-form Shape
    func handleFreeFormPan(sender: AnyObject)
    {
        //println("handle")
        let gesture = sender as! UIPanGestureRecognizer
        
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
                sketch.addFeatureToSketch(shape, parent: shape.parent!)
            
            sketch.currentFeature = nil
            self.sketch.getPlanes()
            forceRedraw()
            
            println(sketch.almostCoincidentEdgePoints())
            
        default:
            break
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
                /// what happens if I make this a while loop
                outer:for feature in sketch.features
                {
                    // if spanning, set parent (but not children), because the feature has not been finalized
                    for fold in feature.horizontalFolds
                    {
                        if(drawingFeature.featureSpansFold(fold))
                        {
                            drawingFeature.drivingFold = fold
                            drawingFeature.parent = feature
                if(foldsCrossed > 1){
                    drawingFeature.drivingFold = nil
                    drawingFeature.parent = nil
                }
                
        case UIGestureRecognizerState.Began:
            // make a shape with touchpoint
            var touchPoint: CGPoint = gesture.locationInView(self)
            var shape: FreeForm = FreeForm(start:touchPoint)
            sketch.currentFeature = shape
            sketch.currentFeature?.startPoint = gesture.locationInView(self)
            
            shape.endPoint = touchPoint
            
            var touchPoint: CGPoint = gesture.locationInView(self)
            
            //if feature spans fold, sets the drawing feature's driving fold and parent
            {
            
            if(Float(shape.lastUpdated.timeIntervalSinceNow) < multiplier){
                
                // if is a complete boxfold with driving fold in middle
                if(drawingFeature.drivingFold != nil)
                {
                    let drawParent = drawingFeature.parent!
                                        
            
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
                            shape.parent = feature
                            break outer;
                            
                            
    //    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!)
    {
                // if feature didn't span a fold, then make it a hole?
                // find parent for hole
                if shape.parent == nil
                {
                    shape.parent = sketch.featureHitTest(shape.path!.firstPoint())
                }
                sketch.addFeatureToSketch(shape, parent: shape.parent!)
            
            sketch.currentFeature = nil
            self.sketch.getPlanes()
            forceRedraw()
            
            println(sketch.almostCoincidentEdgePoints())
            
        default:
            break
        {
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
            // while user is dragging
        case UIGestureRecognizerState.Changed:
                var twinsOfVisited = [Edge]()
                
            if let drawingFeature = sketch.currentFeature
            {
                //add most recent feature if it exists
                if(sketch.currentFeature != nil)
                {
                    currentFeatures.append(sketch.currentFeature!)
                }
                
                for feature in currentFeatures
                {
                    if(feature.startPoint != nil && feature.endPoint != nil)
                /// what happens if I make this a while loop
                outer:for feature in sketch.features
                {
                    // if spanning, set parent (but not children), because the feature has not been finalized
                    for fold in feature.horizontalFolds
                    {
                        if(drawingFeature.featureSpansFold(fold))
                        {
                    }
                }
                            break outer;
                // all edges
                for e in sketch.edges
                {
                    setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                    
                    //don't draw twin edges
                    if(!twinsOfVisited.contains(e))
                    {
                        e.path.stroke()
                        twinsOfVisited.append(e.twin)
                // box folds have different behaviors if they span the driving edge
                }
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
    /// erase hitpoint edge
    /// needs to be refactored for features
    //    func erase(touchPoint: CGPoint)
    //    {
    //        if var feature = sketch.planeHitTest(touchPoint)?.feature
    //        {
    //            if feature.parent != nil {
    //                sketch.removeFeatureFromSketch(feature)
    //                sketch.getPlanes()
    //                forceRedraw()
    //            }
    //        }
    //    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!)
    {
        
        path.lineWidth=kLineWidth
        return color
    // creates a bitmap preview image of sketch
    func bitmap(#grayscale:Bool, circles:Bool = true) -> UIImage
    {
    
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
                for feature in currentFeatures
                {
                    if(feature.startPoint != nil && feature.endPoint != nil)
                    {
                        let edges = feature.getEdges()
                        for e in edges
                        {
                            setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                            e.path.stroke()
                        for e in edges
                        
                            setPathStyle(e.path, edge:e, grayscale:grayscale).setStroke()
                            e.path.stroke()
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
    
    
    func modeToEdgeKind(sketchMode: Mode) -> Edge.Kind
    {
        switch sketchMode
        {
        case .Cut:
            return Edge.Kind.Cut
        default:
            return Edge.Kind.Cut
        }
        
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
