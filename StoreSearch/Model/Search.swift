//
//  Search.swift
//  StoreSearch
//
//  Created by Ronald Tong on 5/9/18.
//  Copyright © 2018 StokeDesign. All rights reserved.
//

import Foundation

class Search {
    var searchResults: [SearchResult] = []
    var hasSearched = false
    var isLoading = false
    
    private var dataTask: URLSessionDataTask? = nil
    
    func performSearch(for text: String, category: Int) {
        if !text.isEmpty {
            
            // If there is an active data task, cancel it so old search doesn't get in the way of a new search
            dataTask?.cancel()
            
            isLoading = true
            hasSearched = true
            searchResults = [SearchResult]()
            
            // Create URL object using search text. Create a URLSession object.
            let url = iTunesURL(searchText: text, category: category)
            let session = URLSession.shared
            
            // Create a data task to Send HTTPS GET requests to the server at url. Returns Data, URL Response, and Error. Completion handler is invoked on a background thread when data task recieves a reply from the server
            dataTask = session.dataTask(with: url, completionHandler: { data, response, error in
                
                // print("On main thread? " + (Thread.current.isMainThread ? "Yes" : "No"))
                
                // Search Cancelled: Exit closure if error code -999 (cancel error)
                if let error = error as? NSError, error.code == -999 {
                    return
                }
                
                // response is of URLResponse type so has to be cast as HTTPURLResponse to look at the statusCode. The comma combines checks into a single line
                // Unwrap the optional object from the data parameter, convert it to a dictionary, then convert it to a SearchResult object by parsing. Return exits closure as search is successful.
                 if let httpResponse = response as? HTTPURLResponse,
                        httpResponse.statusCode == 200,
                    let jsonData = data,
                    let jsonDictionary = self.parse(json: data!) {
                        
                        self.searchResults = self.parse(dictionary: jsonDictionary)
                        self.searchResults.sort(by: < )
                    
                        print("Search Success!")
                        self.isLoading = false
                        return
                        }
                print("Failure! \(response)")
                self.hasSearched = false
                self.isLoading = false
                })
            // Call resume to send request to the server once data task is created
            dataTask?.resume()
            }
    }
    
    func iTunesURL(searchText: String, category: Int) -> URL {
        // Convert search text into a URL
        
        // Convert category index from a number to a string to be added to the URL
        let entityName: String
        switch category {
        case 1: entityName = "musicTrack"
        case 2: entityName = "software"
        case 3: entityName = "ebook"
        default: entityName = ""
        }
        
        // Place text from search bar into the url, then turn it into a URL object. Use URL encoding.
        // %d is a placeholder for integer numbers. %f is for numbers with decimal point. %@is is for objects such as strings.
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(format: "https://itunes.apple.com/search?term=%@&limit=200&entity=%@", escapedSearchText, entityName)
        
        let url = URL(string: urlString)
        return url!
    }
    
// MARK: - JSON PARSING
    
    func parse(json data: Data) -> [String: Any]? {
        // Convert JSON Data to a dictionary [String: Any]
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("JSON Error: \(error)")
            return nil
        }
    }
    
    func parse(dictionary: [String: Any]) -> [SearchResult] {
        // Converts JSON Dictionary to a SearchResult object
        
        // If dictionary has a key named "results" then continue, otherwise perform the { closure }
        guard let array = dictionary["results"] as? [Any] else {
            print("Expected 'results' array")
            return []
        }
        
        var searchResults: [SearchResult] = []
        
        // Look at each element in the array. Each element is a dictionary thus is cast as the type [String: Any]
        // Create a SearchResult object by calling parse(track) or parse(audiobook) etc, then add the object to the array
        for resultDict in array {
            if let resultDict = resultDict as? [String: Any] {
                var searchResult: SearchResult?
                
                if let wrapperType = resultDict["wrapperType"] as? String{
                    switch wrapperType {
                    case "track": searchResult = parse(track: resultDict)
                    case "audiobook": searchResult = parse(audiobook: resultDict)
                    case "software": searchResult = parse(software: resultDict)
                    default: break
                    }
                }
                    
                    // E-books do not have a wrapperType field so use the kind field instead
                else if let kind = resultDict["kind"] as? String, kind == "ebook" {
                    searchResult = parse(ebook: resultDict)
                }
                
                if let result = searchResult {
                    searchResults.append(result)
                }
            }
        }
        return searchResults
    }
    
    func parse(track dictionary: [String: Any]) -> SearchResult {
        // Convert Dictionary into a SearchResult object
        
        let searchResult = SearchResult()
        
        // Dictionary has Any values, thus cast properties as String or Double
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["trackPrice"] as? Double {
            searchResult.price = price
        }
        
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    func parse(audiobook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["collectionName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["collectionViewUrl"] as! String
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["collectionPrice"] as? Double {
            searchResult.price = price
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    func parse(software dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["price"] as? Double {searchResult.price = price
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    func parse(ebook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["price"] as? Double {
            searchResult.price = price
        }
        if let genres: Any = dictionary["genres"] {
            searchResult.genre = (genres as! [String]).joined(separator: ", ")
        }
        return searchResult
    }
}
