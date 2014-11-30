//
//  CollectionOfFoldlings.swift
//  foldlings
//
//  Created by nook on 11/30/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation

class CollectionOfFoldlings: NSObject, UICollectionViewDataSource {
    
    
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int{
            return 1;
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
    
            return UICollectionViewCell()
    }
    
    
}
