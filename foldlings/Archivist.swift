//
//  Archivist.swift
//  foldlings
//
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
    
    let pathToDesktop = "/Users/nook/Desktop/data.plist"

    NSKeyedArchiver.archiveRootObject(data, toFile: pathToDesktop)
    println(data.writeToFile(path, atomically: false))
 
    
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