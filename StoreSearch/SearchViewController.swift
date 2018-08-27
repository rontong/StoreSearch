//
//  ViewController.swift
//  StoreSearch
//
//  Created by Ronald Tong on 20/8/18.
//  Copyright © 2018 StokeDesign. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    
    struct TableViewCellIdentifiers {
        // Static value can be used without an instance (does not need to be instantiated)

        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.becomeFirstResponder()
        
        // Content inset attribute. Tell tableView to add 64-pt margin at the top (20pt status and 44pt search bar)
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        
        // Set row height to 80 (to match SearchResultCell height)
        tableView.rowHeight = 80
        
        // Load and register nibs. TableView can automatically make a new cell from the nib when calling dequeueReusableCell(withIdentifier)
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func kindForDisplay(_ kind: String) -> String {
        switch kind {
        case "album": return "Album"
        case "audiobook": return "Audio Book"
        case "book": return "Book"
        case "ebook": return "E-Book"
        case "feature-movie": return "Movie"
        case "music-video": return "Music Video"
        case "podcast": return "Podcast"
        case "software": return "App"
        case "song": return "Song"
        case "tv-episode": return "TV Episode"
        default: return kind
        }
    }
    
// MARK: - NETWORKING
    
    func iTunesURL(searchText: String) -> URL {
        // Place text from search bar into the url, then turn it into a URL object. Use URL encoding. 
        // %d is a placeholder for integer numbers. %f is for numbers with decimal point. %@is is for objects such as strings.
        
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(format: "https://itunes.apple.com/search?term=%@&limit=200", escapedSearchText)
        let url = URL(string: urlString)
        return url!
    }
    
    func performStoreRequest(with url: URL) -> String? {
        // Return a string object with data received from the server
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Download Error: \(error)")
            return nil
        }
    }
    
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

}

// MARK: - JSON PARSING

    func parse(json: String) -> [String: Any]? {
        // Convert JSON string to a Data object, then to a Dictionary.
        
        // Place JSON string into a Data object. Guard let unwraps the optional json.data(). If it returns nil then execute else block.
        guard let data = json.data(using: .utf8, allowLossyConversion: false)
            else { return nil }
        
        // Convert JSON search results to a dictionary [String: Any]
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("JSON Error: \(error)")
            return nil
        }
}
        
    func parse(dictionary: [String: Any]) -> [SearchResult] {
        // Converse JSON Dictionary to a SearchResult object
        
        // If dictionary has a key named "results" then continue
        guard let array = dictionary["results"] as? [Any] else {
            print("Expected 'results' array")
            return []
        }
        
        var searchResults: [SearchResult] = []
        
        // Look at each element in the array. Each element is a dictionary thus is cast as the type [String: Any]
        // If the item is a "track" then create a SearchResult object using the parse(track) function and add it to the array
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
    // Get values from the given dictionary and place into SearchResult properties
    
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

// MARK: - SEARCH BAR DELEGATE METHODS

extension SearchViewController: UISearchBarDelegate {
   
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // If there is a search term then load the text into the iTunesURL
        
        if !searchBar.text!.isEmpty {
        searchBar.resignFirstResponder()
            
        isLoading = true
        tableView.reloadData()
            
        hasSearched = true
        searchResults = [SearchResult]()
        
        // Asynchronous: Place networking code in a closure to be placed in a queue. UI code should always be performed on the main thread (use main queue).
        
            // Get a reference to the queue
            let queue = DispatchQueue.global()
            
            // Dispatch a closure on the queue. Code inside the { closure } is executed asynchronously in the background.
            queue.async {
                let url = self.iTunesURL(searchText: searchBar.text!)
            
                if let jsonString = self.performStoreRequest(with: url),
                let jsonDictionary = parse(json: jsonString) {
                    
                    self.searchResults = parse(dictionary: jsonDictionary)
                    
                    // Sort search results alphabetically. Closure determines sorting rules; compares SearchResult objects and returns true if result1 comes before result2
                    // ALTERNATIVE: searchResults.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }, OR searchResults.sort(by: <)
                    self.searchResults.sort { $0 < $1 }
               
                    // Use main queue to schedule tasks on the main thread (eg UI code)
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.tableView.reloadData()
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.showNetworkError()
                }
                }
            }
        }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        // Attach search bar to top of the screen

        return .topAttached
    }
}

// MARK: - TABLE VIEW DATA SOURCE

extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // If search term has not been used do not return any rows. If loading return 1 row to display loadingCell. If the search array is empty return 1 row to display nothingFoundCell
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // If loading then display loadingCell and animate the spinner
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
            
        // If the search array is empty then display .nothingFoundCell. Otherwise display the search results in a .searchResultCell
        } else if searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            
            if searchResult.artistName.isEmpty {
                cell.artistNameLabel.text = "Unknown"
            } else {
                cell.artistNameLabel.text = String(format: "%@ (%@)", searchResult.artistName, kindForDisplay(searchResult.kind))
            }

            return cell
            }
    }
}

// MARK: - TABLE VIEW DELEGATE METHODS

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row after a tap
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Only allows rows with search results to be selected
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}
