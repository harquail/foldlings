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

    let names = ArchivedEdges.archivedSketchNames()!
    
    override init() {
        super.init()
        self.dataSource = self
        self.delegate = self
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.dataSource = self
        self.delegate = self

    }

    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int{
            
            println("saved sketches: \(names.count)")
            return names.count
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
    
            let cell =  collectionView.dequeueReusableCellWithReuseIdentifier("foldlingsCell", forIndexPath: indexPath) as FoldlingCell
//            let picture = UIImage()
//            let label = UILabel()
            
            let index = indexPath.row
            let cellName = names[index]
//            label.text =
            
            cell.label!.text = cellName
            cell.label!.sizeToFit()

            var view = cell.contentView
            
            view.backgroundColor = UIColor.whiteColor()
//            view.addSubview(label)
            view.sizeToFit()
            
            return cell
    }
    
    
}
