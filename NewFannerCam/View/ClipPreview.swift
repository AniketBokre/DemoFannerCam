//
//  ClipPreview.swift
//  NewFannerCam
//
//  Created by Jin on 3/13/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

class ClipPreview: UIView {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func draw(_ rect: CGRect) {
//
//    }
    
    private var previewImgView  : UIImageView!
    private var previewPlayBtn  : UIButton!
    private var previewView     : UIView!
    private var bannerImgView   : UIImageView!
    private var removeBannerBtn : UIButton!
    private var indicator       : UIActivityIndicatorView!
    
    private var slider          : AORangeSlider!
    private var durationLbl     : UILabel!
    
    private var clip            : Clip!
    
    // Constants
    private var previewFrame    : CGRect!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initLayouts()
    }
    
    func setClip(_ clip: Clip) {
        self.clip = clip
    }
    
}

//MARK: - UI functions
extension ClipPreview {
    
    private func setLayoutsOn(loading: Bool) {
        if loading {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }
        slider.isHidden = loading
        durationLbl.isHidden = loading
        previewPlayBtn.isHidden = loading
        if loading {
            setBannerLayouts()
        }
    }
    
    private func setBannerLayouts() {
        let width = bounds.width/3
        let size = CGSize(width: width, height: (width/16)*9)
        bannerImgView = UIImageView(frame: CGRect(x: previewImgView.bounds.width/2 - size.width/2, y: previewImgView.bounds.height - size.height, width: size.width, height: size.height))
        bannerImgView.isUserInteractionEnabled = true
        addSubview(bannerImgView)
        
        removeBannerBtn = UIButton(type: .system)
        removeBannerBtn.setImage(Constant.Image.DeleteWhite.image, for: .normal)
        removeBannerBtn.frame = CGRect(x: bannerImgView.bounds.width/2 - 12, y: -12, width: 24, height: 24)
        bannerImgView.addSubview(removeBannerBtn)
    }
    
    // Init function
    private func initLayouts() {
        
        previewFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 50)
        
        func setPreviewLayouts() {
            previewImgView = UIImageView(frame: previewFrame)
            addSubview(previewImgView)
            
            previewPlayBtn = UIButton(type: .system)
            previewPlayBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
            previewPlayBtn.center = previewImgView.center
            addSubview(previewPlayBtn)
        }
        
        func setSliderLayouts() {
            slider = AORangeSlider(frame: CGRect(x: 8, y: bounds.height - 46, width: bounds.width - 16, height: 42))
            slider.layer.borderColor = Constant.Color.yellow.cgColor
            slider.layer.borderWidth = 1.0
            addSubview(slider)
            durationLbl = UILabel()
            addSubview(durationLbl)
        }
        
        func setIndicator() {
            indicator = UIActivityIndicatorView(style: .white)
            indicator.center = previewImgView.center
            indicator.hidesWhenStopped = true
            addSubview(indicator)
        }
        
        setPreviewLayouts()
        setSliderLayouts()
        setIndicator()
        setBannerLayouts()
    }
}
