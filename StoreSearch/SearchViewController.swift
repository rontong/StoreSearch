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
    
    // Static value can be used without an instance (does not need to be instantiated)
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Content inset attribute. Tell tableView to add 64-pt margin at the top (20pt status and 44pt search bar)
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        
        // Set row height to 80 (to match SearchResultCell height)
        tableView.rowHeight = 80
        
        // Load nib and register with the reuse identifier. TableView can automatically make a new cell from the nib when calling dequeueReusableCell(withIdentifier)
        let cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension SearchViewController: UISearchBarDelegate {
   
    // Create an array and add searchBar.text to the array
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        
        searchResults = [SearchResult]()
        
        // %d is a placeholder for integer numbers. %f is for numbers with decimal point. %@is is for objects such as strings.
        if searchBar.text! != "justin bieber" {
        for i in 0...2 {
            let searchResult = SearchResult()
            searchResult.name = String(format: "Fake Result %d for", i)
            searchResult.artistName = searchBar.text!
            searchResults.append(searchResult)
            
        }
        hasSearched = true
        tableView.reloadData()
    }
    }
    
    // Attach search bar to top of the screen
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
        
        // If the search array is empty then display 'Nothing Found'. Otherwise display the search results
        if searchResults.count == 0 {
            cell.nameLabel.text = "(Nothing found)"
            cell.artistNameLabel.text = ""
        } else {
        let searchResult = searchResults[indexPath.row]
        cell.nameLabel.text = searchResult.name
        cell.artistNameLabel.text = searchResult.artistName
        }
        return cell
    }
    
}

extension SearchViewController: UITableViewDelegate {
    
    // Deselect row after a tap
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Only allows rows with search results to be selected
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
}
