
import Foundation

class BoxFold:FoldFeature{

    override func getEdges() -> [Edge] {
      
        if let returnee = cachedEdges {
            println("BOX: cache hit")
            return returnee
        }
        println("   BOX: cache MISS")

        
        // make h0, h1, and h2 first.  Then s0, s1, s2, e0, e1, e2
        //
        //                  h0
        //            S- - - - -
        //         s0 |         | e0
        //            |     h1  |
        //            - - - - - -
        //         s1 |         | e1
        //     _ _ _ _|         |_ _ _ _ _ master
        //            |         |
        //         s2 |     h2  | e2
        //            - - - - - E
        //
        var returnee:[Edge] = []
        let h0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Fold)
        let h2 = Edge.straightEdgeBetween(CGPointMake(startPoint!.x, endPoint!.y), end:endPoint!, kind: .Fold)
        horizontalFolds = [h0,h2]
        
        returnee.append(h0)
        returnee.append(h2)
        
        
        //if there's a master fold
        if let master = drivingFold{
            let masterDist = endPoint!.y - master.start.y
            let h1 = Edge.straightEdgeBetween(CGPointMake(startPoint!.x, startPoint!.y + masterDist), end:CGPointMake(endPoint!.x, startPoint!.y + masterDist), kind: .Fold)
            returnee.append(h1)
            horizontalFolds.append(h1)
            
            if(h1.start.y < master.start.y){
                
                let s0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, startPoint!.y + masterDist), kind: .Cut)
                
                let s2 = Edge.straightEdgeBetween(h2.start, end:CGPointMake(startPoint!.x, master.start.y), kind: .Cut)
                
                let s1 = Edge.straightEdgeBetween(s0.end, end:s2.end, kind: .Cut)
                
                let e2 = Edge.straightEdgeBetween(endPoint!, end: CGPointMake(endPoint!.x, endPoint!.y - masterDist),kind:.Cut)
                
                let e1 = Edge.straightEdgeBetween(e2.end, end: CGPointMake(e2.end.x, h1.end.y), kind: .Cut)
                
                let e0 = Edge.straightEdgeBetween(e1.end, end: h0.end, kind: .Cut)
                
                returnee.append(s0)
                returnee.append(s2)
                returnee.append(s1)
                returnee.append(e0)
                returnee.append(e1)
                returnee.append(e2)
            }
                
                //                  h0
                //            S- - - - -
                //            |         |
                //         s0 |         | e0
                //     _ _ _ _|         |_ _ _ _ _ master
                //            |         |
                //         s1 |    h1   | e1
                //            - - - - - -
                //            |         |
                //         s2 |    h2   | e2
                //            - - - - - E
                //
                // leftmost and topmost
                // rightmost and bottommost
            else{
                
                let s0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, master.start.y), kind: .Cut)//checked
                
                let s2 = Edge.straightEdgeBetween(h2.start, end:CGPointMake(startPoint!.x, h1.start.y), kind: .Cut)
                
                let s1 = Edge.straightEdgeBetween(s0.end, end:s2.end, kind: .Cut)//WRONG
                
                
                
                let e0 = Edge.straightEdgeBetween(h0.end, end: CGPointMake(h0.end.x, master.end.y), kind: .Cut)//checked
                let e1 = Edge.straightEdgeBetween(e0.end, end: CGPointMake(h1.end.x, s1.end.y), kind: .Cut)
                let e2 = Edge.straightEdgeBetween(h1.end, end: endPoint!,kind:.Cut)
                
                
                
                returnee.append(s0)
                returnee.append(s1)
                returnee.append(s2)
                returnee.append(e0)
                returnee.append(e1)
                returnee.append(e2)
            }
            
            
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
        
        cachedEdges = returnee
        claimEdges()
        return returnee

        
    }
    
    override func boundingBox() -> CGRect? {
        if (startPoint == nil || endPoint == nil){
            return nil;
        }
        return CGRectMake(startPoint!.x, startPoint!.y, endPoint!.x - startPoint!.x, endPoint!.y - startPoint!.y)
    }
    
}