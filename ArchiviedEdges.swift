//
//  ArchiviedEdges.swift
//  foldlings
//
//  Created by nook on 11/19/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation


//TODO: NSCoding
class ArchivedEdges : NSCoder {
    
    var adj : [CGPoint: [Edge]] = [CGPoint:[Edge]]()
    var edges: [Edge] = []
    var folds: [Edge] = []
    var tabs: [Edge] = []
    
    class func appendToFile(edges:ArchivedEdges)
    {
        var data = NSMutableDictionary()
        data.setObject(self, forKey: "edges")
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let path = paths.stringByAppendingPathComponent("data.plist")
        var fileManager = NSFileManager.defaultManager()
        
        let pathToDesktop = "/Users/nook/Desktop/data.plist"
        println(pathToDesktop)
        
        NSKeyedArchiver.archiveRootObject(data, toFile: pathToDesktop)
    }
    
    
    
    
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
    
    required init(coder aDecoder: NSCoder) {
        
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
    }
    
}
