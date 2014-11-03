//
//  Archivist.swift
//  foldlings
//
//  Created by nook on 11/2/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation

class Archivist{

 class func appendSketchToFile(sketch:Sketch)
{
    var data = NSMutableDictionary()
    data.setObject(sketch, forKey: "sketches")
    
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    let path = paths.stringByAppendingPathComponent("data.plist")
    var fileManager = NSFileManager.defaultManager()

    
//    println((data.objectForKey("sketches") as NSMutableDictionary).count)
    
//    print(data.objectForKey("sketches"));
    
    let pathToDesktop = "/Users/nook/Desktop/data.plist"
    println(pathToDesktop)
    
    
    
//    pathToDesktop = NSString stringWithFormat:@"/Users/%@/Desktop/text.txt", NSUserName();

//    var err = NSError()
    NSKeyedArchiver.archiveRootObject(data, toFile: pathToDesktop)
//    println(data.writeToFile(path, atomically: false))
 
    
}


class func sketchesFromFile() -> NSDictionary
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

}