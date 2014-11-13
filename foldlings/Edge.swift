//
//  Edge.swift
//  foldlings
//

import Foundation
import CoreGraphics
import UIKit

func == (lhs: Edge, rhs: Edge) -> Bool {
    return lhs === rhs
}

class Edge: NSObject, Printable, Hashable, NSCoding {
    override var description: String {
        return "Start: \(start), End: \(end), \n \(kind.rawValue),\(fold.rawValue), \(path)"
    }
    
    override var hashValue: Int { get {
            return description.hashValue
        }
    }
    
    
    enum Kind: String {
        case Fold = "Fold"
        case Cut = "Cut"
        case Tab = "Tab"
    }
    
    enum Fold: String {
        case Hill = "Hill"
        case Valley = "Valley"
        case Unknown = "Unknown"
    }
    
    struct Color {
        static var Hill:UIColor = UIColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 255.0)
        static var Valley:UIColor = UIColor(red: 0.0, green: 255.0, blue: 0.0, alpha: 255.0)
        static var Fold:UIColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 255.0)
        static var Cut:UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 255.0)
    }
    
    /// color for printing with laser cutter
    struct LaserColor {
        static var Hill:UIColor = UIColor.blackColor()
        static var Valley:UIColor = UIColor.blackColor()
        static var Fold:UIColor = UIColor.blackColor()
        static var Cut:UIColor = UIColor.blackColor()
    }

    var start: CGPoint
    var end: CGPoint
    var path = UIBezierPath()
    var fold = Fold.Unknown
    var kind = Kind.Cut
    var isMaster = false
    
    init(start:CGPoint,end:CGPoint, path:UIBezierPath){
        self.start = start
        self.end = end
        self.path = path
    }
    
    convenience init(start:CGPoint,end:CGPoint, path:UIBezierPath, kind: Kind, fold: Fold = Fold.Unknown, isMaster:Bool = false) {
        self.init(start: start, end: end, path:path)
        self.kind = kind
        self.fold = fold
        self.isMaster = isMaster
    }

    
    required init(coder aDecoder: NSCoder) {
        
        self.start = aDecoder.decodeCGPointForKey("start")
        self.end = aDecoder.decodeCGPointForKey("end")
        self.path = aDecoder.decodeObjectForKey("path") as UIBezierPath
        self.fold = Fold(rawValue: (aDecoder.decodeObjectForKey("fold") as String))!
        self.kind = Kind(rawValue: (aDecoder.decodeObjectForKey("kind") as String))!

    }
    
    func encodeWithCoder(aCoder: NSCoder) {
            aCoder.encodeCGPoint(start, forKey: "start")
            aCoder.encodeCGPoint(end, forKey: "end")
            aCoder.encodeObject(path, forKey: "path")
            aCoder.encodeObject( self.fold.rawValue, forKey:"fold" )
            aCoder.encodeObject( self.kind.rawValue, forKey:"kind")
    }

    class func tapTargetForPath(path:UIBezierPath, radius: CGFloat)->UIBezierPath{
        
        let tapTargetPath = CGPathCreateCopyByStrokingPath(path.CGPath, nil, radius, path.lineCapStyle, path.lineJoinStyle, path.miterLimit)
        let tapTarget = UIBezierPath(CGPath: tapTargetPath)
        
        return tapTarget
        
    }
    
    class func hitTest(path: UIBezierPath, point:CGPoint, radius:CGFloat = kHitTestRadius) -> CGPoint? {
        var np:CGPoint? = nil
        if Edge.tapTargetForPath(path, radius: radius).containsPoint(point) {
            np = getNearestPointOnPath(point, path)
        }
        return np
    }
    
    func hitTest(point:CGPoint, radius:CGFloat = kHitTestRadius) -> CGPoint? {
        return Edge.hitTest(path, point:point, radius:radius)
    }
    
    class func getColor(kind: Edge.Kind, fold: Edge.Fold = Edge.Fold.Unknown) -> UIColor
    {
        var color: UIColor!
        switch kind
        {
        case .Fold:
            switch fold {
                case .Hill:
                    color = Color.Hill
                case .Valley:
                    color = Color.Valley
                default:
                    color = Color.Fold
            }
        case .Cut:
            color = Color.Cut
        default:
            color = Color.Cut
        }
        return color
    }
    
    
    class func getLaserColor(kind: Edge.Kind, fold: Edge.Fold = Edge.Fold.Unknown) -> UIColor
    {
        var color: UIColor!
        switch kind
        {
        case .Fold:
            switch fold {
            case .Hill:
                color = LaserColor.Hill
            case .Valley:
                color = LaserColor.Valley
            default:
                color = LaserColor.Fold
            }
        case .Cut:
            color = LaserColor.Cut
        default:
            color = LaserColor.Cut
        }
        return color
    }
    
    func getLaserColor() -> UIColor
    {
        return Edge.getLaserColor(self.kind, fold:self.fold)
    }
    
    func getColor() -> UIColor
    {
        return Edge.getColor(self.kind, fold:self.fold)
    }
    
    
    
}