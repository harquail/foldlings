//
//  ArchiviedEdges.swift
//  foldlings
//
//

import Foundation


class ArchivedFeatures {
    
    var features:[FoldFeature]?
    var names = [String]()
    
    
    //    class func initFromFile() -> NSDictionary
    //    {
    //        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    //        let path = paths.stringByAppendingPathComponent("data.plist")
    //        var fileManager = NSFileManager.defaultManager()
    //        if (!(fileManager.fileExistsAtPath(path)))
    //        {
    //            var bundle : NSString = NSBundle.mainBundle().pathForResource("data", ofType: "plist")!
    //            fileManager.copyItemAtPath(bundle as String, toPath: path, error:nil)
    //        }
    //
    //        return NSDictionary(contentsOfFile: path)!
    //    }
    
    init(fs:[FoldFeature]?, index:Int, name:String){
        
        self.features = fs!
        if(index>=fetchNames().count){
            addName(name)
        }
        
        
    }
    
    init(sketch:Sketch){
        
        self.features = sketch.features
        if(sketch.index >= fetchNames().count ){
            addName(sketch.name)
        }
    }
    
    
    func addName(name:String){
        fetchNames()
        names.append(name)
        NSUserDefaults.standardUserDefaults().setObject(names, forKey: "edgeNames")
    }
    
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
    
    func save() {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "achivedFeatures\(index)")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
//    
//    //should take the index of the sketch we want to retrieve...
//    // need to set master feature
//     func loadSaved(dex:Int) -> Sketch {
//        if let data = NSUserDefaults.standardUserDefaults().objectForKey("achivedFeatures\(dex)") as? NSData {
//            if let unarchived = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [FoldFeature]{
//                let sktchName = fetchNames()
//                let sktch = Sketch(at:dex, named:sktchName)
//                sktch.features = features
//                //                for edge in unarchived.edges{
//                //                    //add all folds and non-master cuts
//                //                    if !(edge.kind == Edge.Kind.Cut) || !edge.isMaster{
//                //                        sktch.addEdge(edge)
//                //                    }
//                //                }
//                
//                return sktch
//            }
//        }
//        return nil
//    }
    
    class func removeAtIndex(index:Int) {
        var i:Int
        var names = archivedSketchNames()
        //        println("names\(names)")
        //        println("removing object at \(index)")
        
        if(names != nil){
            for(i = index; i<names!.count-1; i++){
                if let next:NSData? =  NSUserDefaults.standardUserDefaults().objectForKey("achivedEdges\(i)") as! NSData?{
                    NSUserDefaults.standardUserDefaults().setObject(next, forKey: "achivedEdges\(i)")
                }
                //                println("set object for achivedEdges\(i)")
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
    
    
    class func setImage(dex:Int, image:UIImage){
        let imageData = UIImageJPEGRepresentation(image, 1)
        let relativePath = "image_\(NSDate.timeIntervalSinceReferenceDate()).jpg"
        let path = self.documentsPathForFileName(relativePath)
        imageData.writeToFile(path, atomically: true)
        NSUserDefaults.standardUserDefaults().setObject(relativePath, forKey: "archivedSketchImage\(dex)")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
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
    
    private class func documentsPathForFileName(name: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true);
        let path = paths[0] as! String;
        let fullPath = path.stringByAppendingPathComponent(name)
        return fullPath
    }
    
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
