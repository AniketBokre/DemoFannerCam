//
//  ImageProcess.swift
//  NewFannerCam
//
//  Created by Jin on 1/28/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

class ImageProcess {
    typealias SaveImgCallBack = (Bool, String) -> Void
    
    class func getFrame(url: URL, fromTime: Float64) -> UIImage {
        let asset = AVAsset(url: url)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero
        assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero
        let time = CMTimeMakeWithSeconds(fromTime, preferredTimescale: CMTIMESCALE)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: img)
        } catch {
            print(error.localizedDescription)
            return UIImage()
        }
    }
    
    class func save(imgFile image: UIImage, to path: URL, _ completion: SaveImgCallBack? = nil) {
        autoreleasepool {
            do {
                try image.pngData()?.write(to: path, options: .atomic)
                if let handler = completion {
                    handler(true, "Succeed!")
                }
            } catch {
                print(error)
                if let handler = completion {
                    handler(false, error.localizedDescription)
                }
            }
        }
//        DispatchQueue.global().async {
//            let pngImageData = image.pngData()
//            do {
//                try pngImageData?.write(to: path, options: .atomic)
//                if let handler = completion {
//                    handler(true, "Succeed!")
//                }
//            } catch {
//                print(error)
//                if let handler = completion {
//                    handler(false, error.localizedDescription)
//                }
//            }
//        }
    }
    
    class func saveGif(imgFile data: Data, to path: URL, _ completion: SaveImgCallBack? = nil) {
        autoreleasepool {
            do {
                try data.write(to: path, options: .atomic)
                if let handler = completion {
                    handler(true, "Succeed!")
                }
            } catch {
                print(error)
                if let handler = completion {
                    handler(false, error.localizedDescription)
                }
            }
        }
//        DispatchQueue.global().async {
//            let pngImageData = image.pngData()
//            do {
//                try pngImageData?.write(to: path, options: .atomic)
//                if let handler = completion {
//                    handler(true, "Succeed!")
//                }
//            } catch {
//                print(error)
//                if let handler = completion {
//                    handler(false, error.localizedDescription)
//                }
//            }
//        }
    }
    
    class func resize(image: UIImage, scaledToSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return (newImage != nil) ? newImage! : UIImage()
    }
    
    class func image(solidColor color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgimage = image?.cgImage else { return UIImage() }
        return UIImage(cgImage: cgimage)
    }
    
    class func blurImage(of img: UIImage) -> UIImage {
        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let beginImage = CIImage(image: img)
        currentFilter?.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter?.setValue(3, forKey: kCIInputRadiusKey)
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter?.setValue(currentFilter?.outputImage, forKey: kCIInputImageKey)
        cropFilter?.setValue(CIVector(cgRect: (beginImage?.extent)!), forKey: "inputRectangle")
        let output = cropFilter?.outputImage
        let context = CIContext(options: nil)
        let cgImg = context.createCGImage(output!, from: output!.extent)
        let processedImg = UIImage(cgImage: cgImg!)
        return processedImg
    }
    
}
