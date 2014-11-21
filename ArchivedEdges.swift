//
//  ArchiviedEdges.swift
//  foldlings
//
//  Created by nook on 11/19/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation


class ArchivedEdges : NSCoding {
    
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
    
    init(adj:[CGPoint: [Edge]], edges:[Edge], folds:[Edge], tabs:[Edge]){
        self.adj = adj
        self.edges = edges
        self.folds = folds
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
        folds = aDecoder.decodeObjectForKey("edges") as [Edge]
        tabs = aDecoder.decodeObjectForKey("edges") as [Edge]

        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        var keys = adj.keys.array as [CGPoint]
        var nsKeys = Dictionary<NSValue,[Edge]>()

        for key in keys {
            
            nsKeys[NSValue(CGPoint: key)] = adj[key]
            
        }
        aCoder.encodeObject(nsKeys, forKey: "adj")
        aCoder.encodeObject (edges, forKey: "edges")
        aCoder.encodeObject (folds, forKey: "folds")
        aCoder.encodeObject (tabs, forKey: "tabs")

        
    }
    
    func save() {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        println(data)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "achivedEdges")
    }
    
    class func loadSaved() -> Sketch? {
        
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("achivedEdges") as? NSData {
            if let unarchived = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? ArchivedEdges{
                let sktch = Sketch(named:"saved")
                sktch.adjacency = unarchived.adj
                sktch.edges = unarchived.edges
                sktch.folds = unarchived.folds
                sktch.tabs = unarchived.tabs
            }
            
        }
        return nil
    }
    
    func clear() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("achivedEdges")
    }

    
}
