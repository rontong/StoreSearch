//
//  BounceAnimationController.swift
//  StoreSearch
//
//  Created by Ronald Tong on 30/8/18.
//  Copyright © 2018 StokeDesign. All rights reserved.
//

import UIKit

// To be an animation controller: object needs to extend NSObject and implement UIViewControllerAnimatedTransitioning protocol
class BounceAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        // Determine length of animation
        
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Perform animation
        
        // Look at transitionContext parameter to find out what to animate
        if let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
            
            let containerView = transitionContext.containerView
            toView.frame = transitionContext.finalFrame(for: toViewController)
            containerView.addSubview(toView)
            
            // Scale view to 70%
            toView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            
            // Animation: set initial state before the animation block, animate properties that change in the closure
            UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .calculationModeCubic, animations: {
                
                // Bounce effect: Scale view to 120%, then to 90%, then to original size. Each keygrame takes 1/3 of the animation time
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.334, animations: {
                        toView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    })
                
                UIView.addKeyframe(withRelativeStartTime: 0.334, relativeDuration: 0.333, animations: {
                                        toView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    })
                UIView.addKeyframe(withRelativeStartTime: 0.666, relativeDuration: 0.333, animations: {
                                        toView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    })
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
    }
}
