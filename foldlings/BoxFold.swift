
import Foundation

class BoxFold:FoldFeature{
    
    override func getEdges() -> [Edge]
    {
        
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
        
        
        if let returnee = featureEdges {
            return returnee
        }
        //else make a new boxfold
        var returnee:[Edge] = []
        let h0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Fold, feature: self)
        let h2 = Edge.straightEdgeBetween(CGPointMake(startPoint!.x, endPoint!.y), end:endPoint!, kind: .Fold, feature: self)
        
        
        //if there's a driving fold
        horizontalFolds = [h0,h2]
        
        // add to the edges
        returnee.append(h0)
        returnee.append(h2)
        
        //if there's a driving fold, create the centerfold for a boxfold
        if let master = drivingFold{
            
            let masterDist = endPoint!.y - master.start.y
            let h1 = Edge.straightEdgeBetween(CGPointMake(startPoint!.x, startPoint!.y + masterDist), end:CGPointMake(endPoint!.x, startPoint!.y + masterDist), kind: .Fold, feature: self)
            returnee.append(h1)
            horizontalFolds.insertIntoOrdered(h1, ordering: {$0.start.y < $1.start.y})
            
            // this is fine because the box is a rectangle; in the future we'll have to get intersections
            // getting intersections on every drag might be too expensive...
            let tempMasterStart = CGPointMake(startPoint!.x, master.start.y)
            let tempMasterEnd = CGPointMake(endPoint!.x, master.start.y)
            let tempMaster = Edge.straightEdgeBetween(tempMasterStart, end: tempMasterEnd, kind: .Fold, feature:self)
            horizontalFolds.insertIntoOrdered(tempMaster, ordering: {$0.start.y < $1.start.y})
            
            //all hfolds are "drawn" left to right
            //this recreates the vertical cuts
            // #TODO: in the future, we'll have to skip some of these, which will be replaced with user-defined cuts
            var foldsToAppend = [Edge]()
            
            for (var i = 0; i < (horizontalFolds.count - 1); i++)
            {
                
                let leftPoint = horizontalFolds[i].start
                let nextLeftPoint = horizontalFolds[i + 1].start
                
                let rightPoint =  horizontalFolds[i].end
                let nextRightPoint = horizontalFolds[i + 1].end
                
                let leftEdge = Edge.straightEdgeBetween(leftPoint,end:nextLeftPoint,kind: .Cut, feature: self)
                let rightEdge = Edge.straightEdgeBetween(rightPoint,end:nextRightPoint,kind: .Cut, feature: self)
                
                returnee.append(leftEdge)
                returnee.append(rightEdge)
            }
            
            horizontalFolds.remove(tempMaster)
        }
            
            // otherwise, we only have 4 edges
            //
            //               h0
            //            S------
            //         s0 |      | e0
            //            |      |
            //            -------E
            //               h2
            
        else
        {
            let s0 = Edge.straightEdgeBetween(endPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Cut, feature: self)
            let e0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, endPoint!.y), kind: .Cut, feature: self)
            
            returnee.append(s0)
            returnee.append(e0)
        }
        
        featureEdges = returnee
        //claimEdges()
        return returnee
    }
    
    
    // for box folds, this always creates two folds
    override func splitFoldByOcclusion(edge: Edge) -> [Edge] {
        
        
        let start = [edge.start,edge.end].minBy({$0.x})!
        let end = [edge.start,edge.end].maxBy({$0.x})!
        var returnee = [Edge]()
        
        //make two pieces between the end points of the split fold and the place the intersect with box fold
        let piece = Edge.straightEdgeBetween(start, end: CGPointMake(self.startPoint!.x, start.y), kind: .Fold, feature: self.parent!)
        let piece2 = Edge.straightEdgeBetween(CGPointMake(self.endPoint!.x, start.y), end: end, kind: .Fold, feature: self.parent!)
        
        returnee = [piece,piece2]
        return returnee
        
    }
    
    // bounding box is between start & end point corners
    override func boundingBox() -> CGRect? {
        if (startPoint == nil || endPoint == nil){
            return nil;
        }
        return CGRectMake(startPoint!.x, startPoint!.y, endPoint!.x - startPoint!.x, endPoint!.y - startPoint!.y)
    }
    
    
//
/// boxFolds can be deleted
/// folds can be added only to leaves
override func tapOptions() -> [FeatureOption]?{
    var options:[FeatureOption] = super.tapOptions() ?? []
    options.append(.DeleteFeature)
    if(self.isLeaf()){
        options.append(.MoveFolds);
    }
    
    return options
    

}
    
//converts a boxfold into a freeform shape
func toFreeForm() -> FreeForm{
    var shape = FreeForm(start: self.startPoint!)
    
    shape.path = UIBezierPath(rect: self.boundingBox()!)
    shape.children = self.children
    shape.parent = self.parent

    
    return shape
}

}