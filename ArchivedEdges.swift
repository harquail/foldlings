//
//  ArchiviedEdges.swift
//  foldlings
//
//

import Foundation


class ArchivedEdges : NSObject, NSCoding {
    
    var adj : [CGPoint: [Edge]] = [CGPoint:[Edge]]()
    var edges: [Edge] = []
    var folds: [Edge] = []
    var tabs: [Edge] = []
    
//    func saveToFile()
//    {
//        var data = NSMutableDictionary()
//        data.setObject(self, forKey: "edges")
//        
//        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
//        let path = paths.stringByAppendingPathComponent("data.plist")
//        var fileManager = NSFileManager.defaultManager()
//        
//        let pathToDesktop = "/Users/nook/Desktop/data.plist"
//        println(pathToDesktop)
//        
//        NSKeyedArchiver.archiveRootObject(data, toFile: pathToDesktop)
//    }
    
    class func initFromFile() -> NSDictionary
    {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let path = paths.stringByAppendingPathComponent("data.plist")
        var fileManager = NSFileManager.defaultManager()
        if (!(fileManager.fileExistsAtPath(path)))
        {
            var bundle : NSString = NSBundle.mainBundle().pathForResource("data", ofType: "plist")!
            fileManager.copyItemAtPath(bundle, toPath: path, error:nil)
        }
        
        return NSDictionary(contentsOfFile: path)!
    }
    
    init(adj:[CGPoint: [Edge]], edges:[Edge], tabs:[Edge]){
        self.adj = adj
        self.edges = edges
        self.tabs = tabs
    
    }
    
    required init(coder aDecoder: NSCoder) {
        
        var nsAdj  = aDecoder.decodeObjectForKey("adjs") as Dictionary<NSValue,[Edge]>
        var keys = nsAdj.keys.array
        
        adj.removeAll(keepCapacity: false)
        
        for key in keys {
            adj[key.CGPointValue()] = nsAdj[key]
        }
        
        edges = aDecoder.decodeObjectForKey("edges") as [Edge]
        folds = aDecoder.decodeObjectForKey("folds") as [Edge]
        tabs = aDecoder.decodeObjectForKey("tabs") as [Edge]

       
    
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        var keys = adj.keys.array as [CGPoint]
        var nsKeys = Dictionary<NSValue,[Edge]>()

        for key in keys {
            
            nsKeys[NSValue(CGPoint: key)] = adj[key]
            
        }
        
        var foundTwins:[Edge] = [Edge]()
        var foundEdges:[Edge] = [Edge]()

        for edge in edges{
            if !foundTwins.contains(edge)  && !foundEdges.contains(edge) {
                foundTwins.append(edge.twin)
                foundEdges.append(edge)
            }
            
        }
        aCoder.encodeObject(nsKeys, forKey: "adjs")
        aCoder.encodeObject (foundEdges, forKey: "edges")
        aCoder.encodeObject (folds, forKey: "folds")
        aCoder.encodeObject (tabs, forKey: "tabs")

    }
    
    
    func save() {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "achivedEdges")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func loadSaved() -> Sketch? {
        
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("achivedEdges") as? NSData {
            if let unarchived = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? ArchivedEdges{
                println("loaded save")
                let sktch = Sketch(named:"saved")
//                sktch.adjacency = unarchived.adj
//                sktch.edges.removeAll(keepCapacity: false)
//                sktch.folds.removeAll(keepCapacity: false)
//                sktch.tabs.removeAll(keepCapacity: false)
//                sktch.adjacency.removeAll(keepCapacity: false)

                
                for edge in unarchived.edges{
                    
                    if !(edge.kind == Edge.Kind.Cut) || !edge.isMaster{
                    sktch.addEdge(edge)
                    }
                }
                
//                sktch.getPlanes()
                return sktch
            }
            
        }
        println("failed to load save")
        return nil
    }
    
    func clear() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("achivedEdges")
    }

    
}
