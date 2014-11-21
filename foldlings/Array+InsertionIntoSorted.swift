//
//  Array+InsertionIntoSorted.swift
//  foldlings
//
//let newElement = "c"
//let index = myArray.insertionIndexOf(newElement) { $0 < $1 } // Or: myArray.indexOf(c, <)
//myArray.insert(newElement, atIndex: index)
//

import Foundation


extension Array {
    func insertionIndexOf(elem: T, isOrderedBefore: (T, T) -> Bool) -> Int {
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
}
