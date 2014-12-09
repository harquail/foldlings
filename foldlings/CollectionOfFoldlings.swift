//
//  CollectionOfFoldlings.swift
//  foldlings
//
//  Created by nook on 11/30/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation
import UIKit

class CollectionOfFoldlings: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var names = ArchivedEdges.archivedSketchNames()
    var cells = [Int:FoldlingCell]()
    
    override init() {
        super.init()
        self.dataSource = self
        self.delegate = self
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.dataSource = self
        self.delegate = self
        //invalidate sketches once every second

    }
    
    override func reloadData() {
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
            
            let cell =  collectionView.dequeueReusableCellWithReuseIdentifier("foldlingsCell", forIndexPath: indexPath) as FoldlingCell
            
            let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
            
            
            //            let picture = UIImage()
            //            let label = UILabel()
            
            let index = indexPath.row
            let cellName = names![index]

     

            
            if let archivedImage = ArchivedEdges.archivedImage(index){
                cell.image?.image = archivedImage
            }
            
            cell.label!.text = cellName
            cell.label!.sizeToFit()
            cell.addGestureRecognizer(tapRecognizer)
            cell.index = index
            
            var view = cell.contentView
            
            view.backgroundColor = UIColor.whiteColor()
            //            view.addSubview(label)
            view.sizeToFit()
            
            
            cells[index] = cell
            return cell
    }
    
    
    func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            for (index, cell) in cells{
                
                if(cell.gestureRecognizers != nil && cell.gestureRecognizers!.contains(sender)){

                    
                    let story = UIStoryboard(name: "Main", bundle: nil)
                    let vc = story.instantiateViewControllerWithIdentifier("sketchView") as SketchViewController
                    self.window?.rootViewController?.presentViewController(vc, animated: true, completion: {
                        vc.sketchView.sketch = ArchivedEdges.loadSaved(dex: cell.index)
                        vc.sketchView.sketch.removeEdge(vc.sketchView.sketch.drivingEdge) //remove master fold
                        vc.sketchView.forceRedraw()
                    })
                    
                    Flurry.logEvent("opened foldling", withParameters: NSDictionary(dictionary: ["named":cell.label!.text!]))
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
                    Flurry.logEvent("deleted foldling", withParameters: NSDictionary(dictionary: ["named":cell.label!.text!]))
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
    
    
    
    
    ///invalidate cells when view loads
    func invalidateCells() {
        for cell in cells{
        }
    }

    
}
