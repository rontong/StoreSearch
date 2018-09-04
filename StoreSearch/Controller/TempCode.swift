////
////  TempCode.swift
////  StoreSearch
////
////  Created by Ronald Tong on 5/9/18.
////  Copyright © 2018 StokeDesign. All rights reserved.
////
//
//import Foundation
//
//func performSearch(){
//
//    if !searchBar.text!.isEmpty {
//        searchBar.resignFirstResponder()
//
//        // If there is an active data task, cancel it so old search doesn't get in the way of a new search
//        dataTask?.cancel()
//        isLoading = true
//        tableView.reloadData()
//        hasSearched = true
//        searchResults = [SearchResult]()
//
//        // Create URL object using search text. Create a URLSession object.
//        let url = iTunesURL(searchText: searchBar.text!, category: segmentedControl.selectedSegmentIndex)
//        let session = URLSession.shared
//
//        // Create a data task to Send HTTPS GET requests to the server at url. Returns Data, URL Response, and Error. Completion handler is invoked on a background thread when data task recieves a reply from the server
//        dataTask = session.dataTask(with: url, completionHandler: { data, response, error in
//
//            print("On main thread? " + (Thread.current.isMainThread ? "Yes" : "No"))
//
//            // Exit closure if error code -999 (cancel error)
//            if let error = error as? NSError, error.code == -999 {
//                return
//
//                // response is of URLResponse type so has to be cast as HTTPURLResponse to look at the statusCode. The comma combines checks into a single line
//            } else if let httpResponse = response as? HTTPURLResponse,
//                httpResponse.statusCode == 200 {
//
//                // Unwrap the optional object from the data parameter, convert it to a dictionary, then convert it to a SearchResult object by parsing. Return exits closure as search is successful.
//                if let data = data, let jsonDictionary = parse(json: data) {
//                    self.searchResults = parse(dictionary: jsonDictionary)
//                    self.searchResults.sort(by: < )
//
//                    // Use main queue to update UI on the main thread
//                    DispatchQueue.main.async {
//                        self.isLoading = false
//                        self.tableView.reloadData()
//                    }
//                    return
//                }
//            } else {
//                print("Failure! \(response)")
//            }
//
//            // Update UI if there is an error
//            DispatchQueue.main.async {
//                self.hasSearched = false
//                self.isLoading = false
//                self.tableView.reloadData()
//                self.showNetworkError()
//            }
//
//        })
//        // Call resume to send request to the server once data task is created
//        dataTask?.resume()
//    }
//}
//
