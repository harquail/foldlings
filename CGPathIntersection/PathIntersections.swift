//
//  PathIntersections.swift
//  foldlings
//
//  Created by nook on 3/24/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

class PathIntersections {
    
    /// all the intersection points between two paths
    class func intersectionsBetweenCGPaths(p:CGPathRef,p2:CGPathRef) ->[CGPoint]? {
        
        
        //ported objective c code from https://github.com/unixpickle/PathIntersection
        var returnee:[CGPoint]?
        let bmp1 = ANPathBitmap(path: p)
        let bmp2 = ANPathBitmap(path: p2)
        
        bmp1.lineCap = kCGLineCapRound;
        bmp2.lineCap = kCGLineCapRound;
        bmp1.lineThickness = 2;
        bmp2.lineThickness = 2;
        bmp1.generateBitmap();
        bmp2.generateBitmap();
        
        let minX = min(floor(bmp1.boundingBox.origin.x), floor(bmp2.boundingBox.origin.x))
        let minY = min(floor(bmp1.boundingBox.origin.y), floor(bmp2.boundingBox.origin.y))
        let maxX = max(floor(bmp1.boundingBox.origin.x + bmp1.boundingBox.size.width),
            floor(bmp2.boundingBox.origin.x + bmp2.boundingBox.size.width))
        let maxY = max(floor(bmp1.boundingBox.origin.y + bmp1.boundingBox.size.height),
            floor(bmp2.boundingBox.origin.y + bmp2.boundingBox.size.height))
        
        for (var x = minX; x <= maxX; x++) {
            for (var y = minY; y <= maxY; y++) {
                
                let point = CGPointMake(x, y);
                let clear1 = bmp1.isTransparentAtPoint(point)
                let clear2 = bmp2.isTransparentAtPoint(point)
                if (!clear1 && !clear2) {
                    
                    if (returnee != nil){
                        returnee!.append(point)
                    }
                    else{
                        returnee = [point]
                    }
                    
                }
            }
            
        }
        
        // the output of this is multiple clusters of very similar points...
        // so, cluster similar points together for convenience
        if let points = returnee{
            returnee = clusterPoints(returnee!)
        }
        
        return returnee
        
    }
    
    //group points that are near each other into a single point
    class func clusterPoints(points:[CGPoint])->[CGPoint]{
        
        var pointBins = [[CGPoint]]()
        
        for point in points{
            
            if(pointBins.isEmpty){
                pointBins = [[point]]
            }
            else{
                var placedInBin = false
                for var index = 0; index<pointBins.count; index++ {
                    // if near a bin point, add to existing bin
                    if nearEachOther(pointBins[index][0],p2:point){
                        pointBins[index].append(point)
                        placedInBin = true
                        break
                    }
                }
                if(!placedInBin){
                pointBins.append([point])
                }
            }
        }
        
        var averagedPointBins:[CGPoint]=[]
        for (i,bin) in enumerate(pointBins){
            averagedPointBins.append(CGPointZero)
            for point in bin{
                averagedPointBins[i] = CGPointAdd(averagedPointBins[i], point)
            }
            //each point bin contains the average of points in pointBins
            averagedPointBins[i] = CGPointMultiply(averagedPointBins[i], 1.0/CGFloat(bin.count))
        }
        return averagedPointBins
        
    }
    
    //points are near each other if they are within kHitTestRadius
    class func nearEachOther(p:CGPoint,p2:CGPoint)->Bool{
        let minDist = kHitTestRadius
            as CGFloat
        if(CGPointGetDistance(p, p2) < minDist){
            return true
        }
        return false
        
    }
}