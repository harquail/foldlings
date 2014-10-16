//
//  DrawView.swift
//  foldlings
//
//  Created by Tim Tregubov on 10/14/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import UIKit

class DrawView: UIView {
    
    var path: UIBezierPath!
    var incrementalImage: UIImage!
    var pts: [CGPoint]! // we now need to keep track of the four points of a Bezier segment and the first control point of the next segment
    var ctr: Int = 0
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.multipleTouchEnabled = false;
        self.backgroundColor = UIColor.whiteColor()
        path = UIBezierPath()
        path.lineWidth = 2.0
        pts = [CGPoint](count: 4, repeatedValue: CGPointZero)
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.multipleTouchEnabled = false
        path = UIBezierPath()
        path.lineWidth = 2.0
        pts = [CGPoint](count: 4, repeatedValue: CGPointZero)
    }
    
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
        ctr = 0
        var touch = touches.anyObject() as UITouch
        pts[0] = touch.locationInView(self)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent)
    {
        var touch = touches.anyObject() as UITouch
//        ctr=ctr+1
        pts[ctr] = touch.locationInView(self)
        if (ctr == 4)
        {
            pts[3] = CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0 )// move the endpoint to the middle of the line joining the second control point of the first Bezier segment and the first control point of the second Bezier segment
            path.moveToPoint(pts[0])
            path.addCurveToPoint(pts[3], controlPoint1: pts[1], controlPoint2: pts[2])// add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
            self.setNeedsDisplay()
            // replace points and get ready to handle the next segment
            pts[0] = pts[3]
            pts[1] = pts[4]
            ctr = 1
        }
        
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        self.drawBitmap()
        self.setNeedsDisplay()
        path.removeAllPoints()
        ctr = 0
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        self.touchesEnded(touches, withEvent: event)
    }
    
    func drawBitmap() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        
        if incrementalImage == nil ///first time; paint background white
        {
            var rectpath = UIBezierPath(rect: self.bounds)
            UIColor.whiteColor().setFill()
            rectpath.fill()
        }
        incrementalImage.drawAtPoint(CGPointZero)
        UIColor.blackColor().setStroke()
        path.stroke()
        incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    

}