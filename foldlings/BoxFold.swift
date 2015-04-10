
import Foundation

class BoxFold:FoldFeature{
    
    override func getEdges() -> [Edge] {
        
        // make h0, h1, and h2 first.  Then s0, s1, s2, e0, e1, e2....
        //
        //                  h0
        //            S- - - - -
        //         s0 |         | e0
        //            |     h1  |
        //            - - - - - -
        //         s1 |         | e1
        //     _ _ _ _|         |_ _ _ _ _ driving
        //            |         |
        //         s2 |     h2  | e2
        //            - - - - - E
        //
        
        //if boxfold has already been created, return its edges
        if let returnee = cachedEdges {
            return returnee
        }
        
        //else make a new boxfold
        var returnee:[Edge] = []
        
        //create top and bottom horizontal folds
        let h0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Fold)
        let h2 = Edge.straightEdgeBetween(CGPointMake(startPoint!.x, endPoint!.y), end:endPoint!, kind: .Fold)
        horizontalFolds = [h0,h2]
        
        // add to the edges
        returnee.append(h0)
        returnee.append(h2)

        //if there's a master driving fold, create the centerfold for a boxfold
        if let master = drivingFold{
            let masterDist = endPoint!.y - master.start.y
            let h1 = Edge.straightEdgeBetween(CGPointMake(startPoint!.x, startPoint!.y + masterDist), end:CGPointMake(endPoint!.x, startPoint!.y + masterDist), kind: .Fold)
            returnee.append(h1)
            horizontalFolds.append(h1)
            
            // this is fine because the box is a rectangle; in the future we'll have to get intersections
            // getting intersections on every drag might be too expensive...
            let tempMasterStart = CGPointMake(startPoint!.x, master.start.y)
            let tempMasterEnd = CGPointMake(endPoint!.x, master.start.y)
            let tempMaster = Edge.straightEdgeBetween(tempMasterStart, end: tempMasterEnd, kind: .Fold)
            horizontalFolds.append(tempMaster)
            
            //sort horizontal folds by y height
            horizontalFolds.sort({ (a:Edge, b:Edge) -> Bool in
                return a.start.y < b.start.y
            })
            
            //all hfolds are "drawn" left to right
            //this recreates the vertical cuts
            // #TODO: in the future, we'll have to skip some of these, which will be replaced with user-defined cuts
            var foldsToAppend = [Edge]()
            
            for (var i = 0; i < (horizontalFolds.count - 1); i++){
                
                let leftPoint = horizontalFolds[i].start
                let nextLeftPoint = horizontalFolds[i + 1].start
                
                let rightPoint =  horizontalFolds[i].end
                let nextRightPoint = horizontalFolds[i + 1].end
                
                let leftEdge = Edge.straightEdgeBetween(leftPoint,end:nextLeftPoint,kind: .Cut)
                let rightEdge = Edge.straightEdgeBetween(rightPoint,end:nextRightPoint,kind: .Cut)
                
                returnee.append(leftEdge)
                returnee.append(rightEdge)
                
            }
            
            horizontalFolds.remove(tempMaster)
        }
            
            // otherwise, we only have 4 edges
            //
            //               h0
            //            S------
            //            |      |
            //         s0 |      | e0
            //            |      |
            //            -------E
            //               h2
        
        else{
            
            let s0 = Edge.straightEdgeBetween(endPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Cut)
            let e0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, endPoint!.y), kind: .Cut)
            
            returnee.append(s0)
            returnee.append(e0)
            
        }
        
        
        // split folds by feature children
        for fold in horizontalFolds{
            if let childs = children{
                let fragments = edgeSplitByChildren(fold)
                horizontalFolds.remove(fold)
                returnee.remove(fold)
                horizontalFolds.extend(fragments)
                returnee.extend(fragments)
                
            }
            
        }
        //cache the edges
        cachedEdges = returnee
        //assign edges to feature
        claimEdges()
        return returnee
        
    }
    
    // bounding box is start & end point
    override func boundingBox() -> CGRect? {
        if (startPoint == nil || endPoint == nil){
            return nil;
        }
        return CGRectMake(startPoint!.x, startPoint!.y, endPoint!.x - startPoint!.x, endPoint!.y - startPoint!.y)
    }
    
    /// boxFolds can be deleted
    /// folds can be added only to leaves
    override func tapOptions() -> [FeatureOption]?{
        var options:[FeatureOption] = []
        options.append(.DeleteFeature)
        if(self.isLeaf()){
            options.append(.AddFolds)
        }
        return options
    }
    
}