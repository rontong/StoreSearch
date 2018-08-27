//
//  SearchResult.swift
//  StoreSearch
//
//  Created by Ronald Tong on 21/8/18.
//  Copyright © 2018 StokeDesign. All rights reserved.
//

class SearchResult {
    var name = ""
    var artistName = ""
    
    var artworkSmallURL = ""
    var artworkLargeURL = ""
    var storeURL = ""
    var kind = ""
    var currency = ""
    var price = 0.0
    var genre = ""
}

// Operator overloading: use standard operator and apply to objects

func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
}
