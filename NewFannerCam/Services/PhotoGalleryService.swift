//
//  PhotoGalleryService.swift
//  NewFannerCam
//
//  Created by Jin on 2/25/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit
import Photos

class PhotoGalleryService: NSObject {
    
    func saveVideo(of url: URL, _ completion: @escaping(Bool, String) -> Void) {
        DispatchQueue.global().async {
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                if newStatus ==  PHAuthorizationStatus.authorized {
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    }) { (succeed, error) in
                        if succeed {
                            let fetchOptions = PHFetchOptions()
                            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                            let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                            PHImageManager().requestAVAsset(forVideo: fetchResult!, options: nil, resultHandler: { (avAsset, audioMix, dict) in
                                let newObj = avAsset as! AVURLAsset
                                print(newObj.url)
                                completion(true, newObj.url.path)
                            })
                        } else {
                            completion(false, error?.localizedDescription ?? String())
                        }
                    }
                }
            })
        }
    }
    
}
