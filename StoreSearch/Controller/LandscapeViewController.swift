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
            
            // Create UIButton with a title (for debugging)
            let button = UIButton(type: .system)
            button.backgroundColor = UIColor.white
            button.setTitle("\(index)", for: .normal)
            
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
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    deinit {
        print("deinit \(self)")
    }
}
