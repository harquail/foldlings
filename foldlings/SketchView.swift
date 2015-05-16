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
//            case .MoveFolds:
//                handleMoveFoldPan(sender)
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
                    if $0.kind == .Fold
                    {
                        return "\n<path stroke-dasharray=\"10,10\" d= \"" + SVGPathGenerator.svgPathFromCGPath($0.path.CGPath) + "\"/> "
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
