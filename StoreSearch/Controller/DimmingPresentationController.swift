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
    
    lazy var dimmingView = GradientView(frame: CGRect.zero)
    
    override func presentationTransitionWillBegin() {
        // Invoke when a new view controller is shown on screen
        
        // Create a GradientView object and make it as big as containerView (new view placed on top). Insert behind everything else in the container view. 
        dimmingView.frame = containerView!.bounds
        containerView!.insertSubview(dimmingView, at: 0)
        
        // Fade effect: Set alpha of gradient view to 0, then animate back to 100% 
        dimmingView.alpha = 0
        
        // Transition Coordinator: animations should be done in a closure passed to animateAlongsideTransition to keep it smooth
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1
            }, completion: nil)
        }
    }
    
    // Fade out: animate alpha back to 0
    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0
            }, completion: nil)
        }
    }
}
