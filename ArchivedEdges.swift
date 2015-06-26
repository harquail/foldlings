//
//  ArchiviedEdges.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import Foundation


class ArchivedEdges : NSObject, NSCoding {
    
    var names = [String]()
    var index = 0
    var features: [FoldFeature] = []

    //restoring from saved plist file
    class func initFromFile() -> NSDictionary
    {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let path = paths.stringByAppendingPathComponent("data.plist")
        var fileManager = NSFileManager.defaultManager()
        if (!(fileManager.fileExistsAtPath(path)))
        {
            var bundle : NSString = NSBundle.mainBundle().pathForResource("data", ofType: "plist")!
            fileManager.copyItemAtPath(bundle as String, toPath: path, error:nil)
        }
        
        return NSDictionary(contentsOfFile: path)!
    }

    init(sketch:Sketch){
        super.init()
        self.index = sketch.index
        self.features = sketch.features
        if(index>=fetchNames().count){
            addName(sketch.name)
        }
    }
    
    
    required init(coder aDecoder: NSCoder) {
        features = aDecoder.decodeObjectForKey("features") as! [FoldFeature]
//        for feature in features{
//            println(feature.featureEdges)
//        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(features, forKey: "features")
    }
    
    // adds a neame to list of archived sketch names in nsuserdefaults
    func addName(name:String){
        fetchNames()
        names.append(name)
        NSUserDefaults.standardUserDefaults().setObject(names, forKey: "edgeNames")
    }
    
    // get existing sketch names, and put them in the variable
    func fetchNames() -> [String]{
        
        if(names != []){
            return names
        }
        
        if let data = ArchivedEdges.archivedSketchNames() {
            names = data
        }
        return names
    }
    
    class func archivedSketchNames() -> [String]?{
        
        return NSUserDefaults.standardUserDefaults().objectForKey("edgeNames") as? [String]
    }
    
    // save self to nsuserdefualts
    func save() {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "achivedEdges\(index)")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    //takes the index of the sketch we want to retrieve, and returns a restored sketch
    class func loadSaved(#dex:Int) -> Sketch? {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("achivedEdges\(dex)") as? NSData {
            if let unarchived = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? ArchivedEdges{
                let sktchName = unarchived.fetchNames()[dex]
                let sktch = Sketch(at:dex, named:sktchName, userOriginated:false)
                for feature in unarchived.features{
                   
                    //println("added \(feature)")
                    //set the master feature
                    if(feature is MasterCard){
                        sktch.masterFeature = feature as? MasterCard //this will always succeed
                    }
                    // add features
                    sktch.addFeatureToSketch(feature, parent: feature.parent ?? feature)
//                    sktch.getPlanes()
                }

                return sktch
            }
        }
        return nil
    }
    
    // delete a sketch & card
    class func removeAtIndex(index:Int) {
        var i:Int
        var names = archivedSketchNames()
        
        if(names != nil){
            for(i = index; i<names!.count-1; i++){
                if let next:NSData? =  NSUserDefaults.standardUserDefaults().objectForKey("achivedEdges\(i)") as! NSData?{
                    NSUserDefaults.standardUserDefaults().setObject(next, forKey: "achivedEdges\(i)")
                }
                if let nextImage:String? =  NSUserDefaults.standardUserDefaults().objectForKey("archivedSketchImage\(i)") as! String?{
                    NSUserDefaults.standardUserDefaults().setObject(nextImage, forKey: "archivedSketchImage\(i)")
                }
            }
            
            // remove last
            names!.removeAtIndex(index)
            NSUserDefaults.standardUserDefaults().setObject(names, forKey: "edgeNames")
            NSUserDefaults.standardUserDefaults().removeObjectForKey("achivedEdges\(names?.count)")
            NSUserDefaults.standardUserDefaults().removeObjectForKey("archivedSketchImage\(names?.count)")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    // set preview image for card
    class func setImage(dex:Int, image:UIImage){
        let imageData = UIImageJPEGRepresentation(image, 1)
        let relativePath = "image_\(NSDate.timeIntervalSinceReferenceDate()).jpg"
        let path = self.documentsPathForFileName(relativePath)
        imageData.writeToFile(path, atomically: true)
        NSUserDefaults.standardUserDefaults().setObject(relativePath, forKey: "archivedSketchImage\(dex)")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    // fetches the image for an index
    class func archivedImage(dex:Int) -> UIImage?{
        let possibleOldImagePath = NSUserDefaults.standardUserDefaults().objectForKey("archivedSketchImage\(dex)") as! String?
        if let oldImagePath = possibleOldImagePath {
            let oldFullPath = self.documentsPathForFileName(oldImagePath)
            let oldImageData = NSData(contentsOfFile: oldFullPath)
            // here is your saved image:
            if((oldImageData) != nil){
                return UIImage(data: oldImageData!)
            }
        }
        return nil
    }
    
    // helper function to get file path
    private class func documentsPathForFileName(name: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true);
        let path = paths[0] as! String;
        let fullPath = path.stringByAppendingPathComponent(name)
        return fullPath
    }
    
    // clear all cards
    class func removeAll() {
        if let names = ArchivedEdges.archivedSketchNames(){
            for(var i = 0; i<names.count; i++){
                NSUserDefaults.standardUserDefaults().removeObjectForKey("achivedEdges\(i)")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("archivedSketchImage\(i)")
                
            }
        }
        NSUserDefaults.standardUserDefaults().removeObjectForKey("edgeNames")
        NSUserDefaults.standardUserDefaults().synchronize()
        
    }
    
    
}
