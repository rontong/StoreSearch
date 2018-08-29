//
//  UIImageView+DownloadImage.swift
//  StoreSearch
//
//  Created by Ronald Tong on 30/8/18.
//  Copyright © 2018 StokeDesign. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func loadImage(url: URL) -> URLSessionDownloadTask {
        
        // Create a shared URLSession and downloadTask. downloadTask saves downloaded content to a temporary location on disk and then calls completion handler
        
        let session = URLSession.shared
        let downloadTask = session.downloadTask(with: url) { [weak self] url, response, error in
            
            // If request is successful, error is nil and location parameter in the completion handler block (url) contains the location of the local temp file
            // Use local url to load file into a Data object and then an image
            if error == nil,
                let url = url,
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data) {
                
                // Use main thread to load the image into UIImageView. Check is self (UIImageView) still exists, if not there is now UIImageView to set the image on
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        strongSelf.image = image
                    }
                }
            }
        }
        downloadTask.resume()
        return downloadTask
    }
}

