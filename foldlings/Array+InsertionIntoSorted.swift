//
//  Array+InsertionIntoSorted.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved



import Foundation



extension Array {
    /// gets the insertion index into a sorted array at the appropriate place
    /// using binary insertion search
    private func insertionIndexOf(elem: T, isOrderedBefore: (T, T) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
    
    // inserts an element into an ordered array
    mutating func insertIntoOrdered(x: T, ordering: (T, T) -> Bool){
        
        let index = self.insertionIndexOf(x, isOrderedBefore: ordering)
        
        self.insert(x, atIndex: index)
    }
}
