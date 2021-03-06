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
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var searchResults = [SearchResult]()
    private var hasSearched = false
    private var isLoading = false
    var dataTask: URLSessionDataTask?
    
    var landscapeViewController: LandscapeViewController?
    
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
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        
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
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        print("Segment changed: \(sender.selectedSegmentIndex)")
        performSearch()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        // Rotating device will trigger either showLandscape() or hideLandscape()
        
        super.willTransition(to: newCollection, with: coordinator)
        
        switch newCollection.verticalSizeClass {
        case .compact: showLandscape(with: coordinator)
        case .regular, .unspecified: hideLandscape(with: coordinator)
        }
    }
    
    func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        
        // There should never be a second landscapeVC, so if landscapeVC is not nil then do not continue
        guard landscapeViewController == nil else {return}
        
        // Find the scene with Storyboard ID LandscapeViewController and instantiate it
        landscapeViewController = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
        
        // Set size and position: frame of landscape view is as big as SearchViewController bounds. Give LandscapeVC the searchResults object
        if let controller = landscapeViewController {
            controller.searchResults = searchResults
            controller.view.frame = view.bounds
            controller.view.alpha = 0
            
            // Add landscape controller's view as a subview (on top of the tableview and search bar). Tell SearchVC that LandscapeVC is now in control.
            view.addSubview(controller.view)
            addChildViewController(controller)
            
            // Animate alpha to 1, dismiss keyboard, dismiss detailVC, then call didMove() to tell new VC it has a parent controller (after animations)
            coordinator.animate(alongsideTransition: { _ in
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
            }, completion: { _ in
                controller.didMove(toParentViewController: self)
            })
        }
    }
    
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        // Tell VC it is leaving the VC hierarchy, remove the view from screen, and dispose of VC. Set to nil to remove strong reference.
        
        if let controller = landscapeViewController {
            
            // Call willMove() to let childVC know it is about to be removed
            controller.willMove(toParentViewController: nil)
            
            coordinator.animate(alongsideTransition: { _ in
                
                // Animate alpha to 0
                controller.view.alpha = 0
            }, completion: { _ in
                
                // Call removeFromParentViewController() to send the "did move to parent" message
                controller.view.removeFromSuperview()
                controller.removeFromParentViewController()
                self.landscapeViewController = nil
            })
        }
    }
    
// MARK: - NETWORKING
    
    func performSearch(){
        
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            
            // If there is an active data task, cancel it so old search doesn't get in the way of a new search
            dataTask?.cancel()
            isLoading = true
            tableView.reloadData()
            hasSearched = true
            searchResults = [SearchResult]()
            
            // Create URL object using search text. Create a URLSession object.
            let url = iTunesURL(searchText: searchBar.text!, category: segmentedControl.selectedSegmentIndex)
            let session = URLSession.shared
            
            // Create a data task to Send HTTPS GET requests to the server at url. Returns Data, URL Response, and Error. Completion handler is invoked on a background thread when data task recieves a reply from the server
            dataTask = session.dataTask(with: url, completionHandler: { data, response, error in
                
                print("On main thread? " + (Thread.current.isMainThread ? "Yes" : "No"))
                
                // Exit closure if error code -999 (cancel error)
                if let error = error as? NSError, error.code == -999 {
                    return
                    
                // response is of URLResponse type so has to be cast as HTTPURLResponse to look at the statusCode. The comma combines checks into a single line
                } else if let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 {
                    
                    // Unwrap the optional object from the data parameter, convert it to a dictionary, then convert it to a SearchResult object by parsing. Return exits closure as search is successful.
                    if let data = data, let jsonDictionary = parse(json: data) {
                        self.searchResults = parse(dictionary: jsonDictionary)
                        self.searchResults.sort(by: < )
                        
                        // Use main queue to update UI on the main thread
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.tableView.reloadData()
                        }
                        return
                    }
                } else {
                    print("Failure! \(response)")
                }
                
                // Update UI if there is an error
                DispatchQueue.main.async {
                    self.hasSearched = false
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.showNetworkError()
                }
                
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
    
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
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

// MARK: - SEARCH BAR DELEGATE METHODS

extension SearchViewController: UISearchBarDelegate {
   
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        // Attach search bar to top of the screen
        return .topAttached
    }
}

// MARK: - TABLE VIEW DATA SOURCE

extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // If search term has not been used do not return any rows. If loading return 1 row to display loadingCell. If the search array is empty return 1 row to display nothingFoundCell, if loading then return 1 row to display loadingCell
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
            cell.prepareForReuse()
            let searchResult = searchResults[indexPath.row]
            cell.configure(for: searchResult)
            return cell
            }
    }
}

// MARK: - TABLE VIEW DELEGATE METHODS

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row after a tap and Segue to DetailVC. Send the indexPath through the sender parameter.
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Only allows rows with search results to be selected
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let detailVC = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let searchResult = searchResults[indexPath.row]
            detailVC.searchResult = searchResult
        }
    }
}
