//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Ronald Tong on 30/8/18.
//  Copyright © 2018 StokeDesign. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var searchResults = [SearchResult]()
    private var firstTime = true
    private var downloadTasks = [URLSessionDownloadTask()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove automatic constraints from main view, pageControl and scrollVIew to allow custom layout
        //translatesAutoresizingMaskConstraints allows manual positioning and sizing of frames (UIKit converts manual layout into constraints)
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        
        // Hides page control when there are no search results
        pageControl.numberOfPages = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillLayoutSubviews() {
        // UIKit calls this during layout when view controller first appears on screen. Use this to change frames manually.
        
        super.viewWillLayoutSubviews()
        
        // Scroll view is set to be as large as the screen (main view bounds)
        // Bounds describes the rectangle that makes up the inside of a view (from perspective of scroll view). Frame describes outside of the view (from perspective of main view).
        scrollView.frame = view.bounds
        
        // Page control is set at the bottom of screen and spans the width
        pageControl.frame = CGRect(x: 0, y: view.frame.size.height - pageControl.frame.size.height, width: view.frame.size.width, height: pageControl.frame.size.height)
        
        if firstTime {
            firstTime = false
            tileButtons(searchResults)
        }
    }
    
    private func tileButtons(_ searchResults: [SearchResult]) {
        // STEP 1: Determine number, size, and positioning of grid squares
        
        // 480pt scrollViewWidth, 3.5 inch device. 3 rows, 5 columns, grid squares 96 x 88, row starts at Y = 20
        var columnsPerPage = 5
        var rowsPerPage = 3
        var itemWidth: CGFloat = 96
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 0
        var marginY: CGFloat = 20
        
        let scrollViewWidth = scrollView.bounds.size.width
        
        switch scrollViewWidth {
        // 4-inch device. 3 rows, 6 columns, 94pt squares. MarginX moved across as 568 does not divide by 6
        case 568:
            columnsPerPage = 6
            itemWidth = 94
            marginX = 2
        
        // 4.7-inch device. 3 rows, 7 columns, 98pt high squares, extra Y margin
        case 667:
            columnsPerPage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
            
        // 5.5-inch device. 4 rows, 8 columns.
        case 736:
            columnsPerPage = 8
            rowsPerPage = 4
            itemWidth = 92
            
        default: break
        }
        
        // STEP 2: Declare size of buttons that fit in grid spaces. Each button is 82x82pts, add padding space between buttons
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth) / 2
        let paddingVert = (itemHeight - buttonHeight) / 2
        
        // STEP 3: CREATE UIButton for each SearchResult object
        var row = 0
        var column = 0
        var x = marginX
        
        
        for (index, searchResult) in searchResults.enumerated() {
            // for in enumerated() uses a tuple of SearchResult object and index in the array
            
            // Create UIButton
            let button = UIButton(type: .custom)
            downloadImage(for: searchResult, andPlaceOn: button)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), for: .normal)
            
            // Set frame of button and add as a subview of UIScrollView
            button.frame = CGRect(x: x + paddingHorz, y: marginY + CGFloat(row)*itemHeight + paddingVert, width: buttonWidth, height: buttonHeight)
            scrollView.addSubview(button)
            
            // Use x and row variables to position buttons. If row reaches bottom of ScrollView (row = rowsPerPage) set row to 0 and skip to the next column (column +1). If column reaches end of ScrollView then set column to 0
            row += 1
            if row == rowsPerPage {
                row = 0; x += itemWidth; column += 1
                
                if column == columnsPerPage {
                    column = 0; x += marginX * 2
                }
            }
        }
        // Calculate contentSize for scroll view based on number of buttons and searchResult objects that fit the page. Always make content width a multiple of screen width (480, 568, 667, 736)
        let buttonsPerPage = columnsPerPage * rowsPerPage
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
        
        scrollView.contentSize = CGSize(width: CGFloat(numPages)*scrollViewWidth, height: scrollView.bounds.size.height)
        print("Number of pages: \(numPages)")
        
        // Displays the number of dots on page control
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
    }
    
    private func downloadImage(for searchResult: SearchResult, andPlaceOn button: UIButton) {
        
        // Obtain URL object ad create a download task. Use completion handler to put downloaded file into UIImage. Use DispatchQueue to place image on a button.
        // Use weak reference so buttons are deallocated if LandscapeVC is deallocated
        if let url = URL(string: searchResult.artworkSmallURL) {
            let session = URLSession.shared
            let downloadTask = session.downloadTask(with: url) { [weak button] url, response, error in
                if error == nil,
                let url = url,
                let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let button = button {
                            button.setImage(image, for: .normal)
                        }
                    }
                }
            }
            downloadTask.resume()
            // Use downloadTasks to keep track of active URLSessionDownloadTask objects
            downloadTasks.append(downloadTask)
        }
    }
    
    @IBAction func pageChanged(_ sender: UIPageControl) {
        // When user taps Page Control, update current Page property to calculate new contentOffset for scrollView
        // Place code in an animation block using UIView.animate(options)
        
        UIView.animate(withDuration: 0.9, delay: 0, options: [.curveEaseInOut], animations: {
            self.scrollView.contentOffset = CGPoint(x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage), y: 0)
        }, completion: nil)
    }
    
    deinit {
        // Cancel any download tasks still in operation
        print("deinit \(self)")
        for task in downloadTasks {
            task.cancel()
        }
    }
}

extension LandscapeViewController: UIScrollViewDelegate {
    // Make view controller a delegate of Scroll View so it is notified when user flicks through pages
 
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Determine current page using contentOffset property.
        
        let width = scrollView.bounds.size.width
        // contentOffset determines how far scroll view has been scrolled. If offset goes beyond halfway on the page then scroll view will flick to the next page
        let currentPage = Int((scrollView.contentOffset.x + width/2) / width)
        pageControl.currentPage = currentPage
    }
}
