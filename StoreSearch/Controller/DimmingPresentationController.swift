//
//  DimmingPresentationController.swift
//  StoreSearch
//
//  Created by Ronald Tong on 30/8/18.
//  Copyright © 2018 StokeDesign. All rights reserved.
//

import UIKit

class DimmingPresentationController: UIPresentationController {
    
    override var shouldRemovePresentersView: Bool {
        // Override standard UIPresentationController to leave SearchViewController visible
        return false
    }
    
}
