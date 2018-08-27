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
    
    struct TableViewCellIdentifiers {
        // Static value can be used without an instance (does not need to be instantiated)

        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// MARK: - NETWORKING
    
    func iTunesURL(searchText: String) -> URL {
        // Place text from search bar into the url, then turn it into a URL object. Use URL encoding. 
        // %d is a placeholder for integer numbers. %f is for numbers with decimal point. %@is is for objects such as strings.
        
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(format: "https://itunes.apple.com/search?term=%@", escapedSearchText)
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
        
    func parse(dictionary: [String: Any]) {
        
        // If dictionary has a key named "results" then continue
        guard let array = dictionary["results"] as? [Any] else {
            print("Expected 'results' array")
            return
        }
        
        // Look at each element in the array. Each element is a dictionary thus is cast as the type [String: Any], then print the wrapperType and kind
        for resultDict in array {
            if let resultDict = resultDict as? [String: Any] {
                if let wrapperType = resultDict["wrapperType"] as? String,
                    let kind = resultDict["kind"] as? String {
                    print("wrapperType: \(wrapperType), kind: \(kind)")
                }
            }
        }
    }

// MARK: - SEARCH BAR DELEGATE METHODS

extension SearchViewController: UISearchBarDelegate {
   
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // If there is a search term then load the text into the iTunesURL
        
        if !searchBar.text!.isEmpty{
        searchBar.resignFirstResponder()
            
        hasSearched = true
        searchResults = [SearchResult]()
        
        let url = iTunesURL(searchText: searchBar.text!)
            print("URL: '\(url)'")
            
            if let jsonString = performStoreRequest(with: url) {
                if let jsonDictionary = parse(json: jsonString) {
                    print("Dictionary \(jsonDictionary)")
                    parse(dictionary: jsonDictionary)
                    tableView.reloadData()
                return
                }
            }
            showNetworkError()
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
        
        // If search term has not been used then do not return any rows. If the search array is empty then return 1 row so the user can see 'Nothing Found'
        if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // If the search array is empty then display .nothingFoundCell. Otherwise display the search results in a .searchResultCell
        if searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            cell.artistNameLabel.text = searchResult.artistName
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
        if searchResults.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
}
