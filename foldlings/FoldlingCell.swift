//
//  foldlingCell.swift
//  foldlings
//
// © 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import Foundation


class FoldlingCell: UICollectionViewCell {

    @IBOutlet var image:UIImageView?
    @IBOutlet var label: UILabel?
    var tapGesture =  UITapGestureRecognizer()
    var holdGesture = UILongPressGestureRecognizer()
    var index = 0

    
    
}