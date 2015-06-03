//
//  CollectionOfFoldlings.swift
//  foldlings
//
// © 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import Foundation
import UIKit

class CollectionOfFoldlings: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var names = ArchivedEdges.archivedSketchNames()
    var cells = [Int:FoldlingCell]()
    var tapped = false
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.dataSource = self
        self.delegate = self
        
    }
    
    override func reloadData() {
        tapped = false
        super.reloadData()
        names = ArchivedEdges.archivedSketchNames()
    }
    
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int{
            
            if (names != nil){
                return names!.count
            }
            else{
                return 0
            }
    }
    
    
    override func didMoveToSuperview() {
        self.reloadData()
    }
    
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
            
            let cell =  collectionView.dequeueReusableCellWithReuseIdentifier("foldlingsCell", forIndexPath: indexPath) as! FoldlingCell
            
            let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
            
            let index = indexPath.row
            // show cells in reverse order
            let cellName = names![names!.count-1 - index]
            
            if let archivedImage = ArchivedEdges.archivedImage(names!.count-1 - index){
                cell.image?.image = archivedImage
            }
            
            cell.label!.text = cellName
            cell.label!.sizeToFit()
            cell.addGestureRecognizer(tapRecognizer)
            cell.index = names!.count-1 - index
            
            var view = cell.contentView
            
            view.backgroundColor = UIColor.whiteColor()
            view.sizeToFit()
            
            cells[index] = cell
            return cell
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            for (index, cell) in cells{
                
                if(cell.gestureRecognizers != nil && cell.gestureRecognizers!.contains(sender) && !tapped){
                    
                    tapped = true
                    
                    let story = UIStoryboard(name: "Main", bundle: nil)
                    let vc = story.instantiateViewControllerWithIdentifier("sketchView") as! SketchViewController
                    vc.index = cell.index
                    vc.restoredFromSave = true
                    (self.window?.rootViewController as! UINavigationController).pushViewController(vc, animated: true)
                    
                    Flurry.logEvent("opened foldling", withParameters: NSDictionary(dictionary: ["named":cell.label!.text!]) as [NSObject : AnyObject])
                    println("Clicked: \(cell.label!.text)")
                    
                }
            }
        }
    }
    
    func handlePress(sender: UILongPressGestureRecognizer) {
        if sender.state == .Ended {
            for (index, cell) in cells{
                
                if(cell.gestureRecognizers != nil && cell.gestureRecognizers!.contains(sender)){
                    println("Clicked: \(cell.label!.text)")
                    Flurry.logEvent("deleted foldling", withParameters: NSDictionary(dictionary: ["named":cell.label!.text!]) as [NSObject : AnyObject])
                }
            }
            
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) -> Bool {
        
        println(NSStringFromSelector(action))
        
        if (NSStringFromSelector(action) == "cut:" || NSStringFromSelector(action) ==  "delete:"){
            return true
        }
        return false
        
    }
    
    func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) {
        
        ArchivedEdges.removeAtIndex(indexPath.row)
        names?.removeAtIndex(indexPath.row)
        self.deleteItemsAtIndexPaths([indexPath])
        for (index, cell) in cells{
            if(cell.index > indexPath.row){
                cell.index -= 1
                println("index moved to \(cell.index)")
            }
        }
        
        
    }
    
    
}
