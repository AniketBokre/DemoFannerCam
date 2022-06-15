//
//  TopBarView.swift
//  NewFannerCam
//
//  Created by Jin on 1/21/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit

enum Team {
    case first
    case second
}

protocol MarkersViewDelegate {
    func didTap(on view: MarkersView, btn: UIButton, type: FanGenViewBtn, team: Team)
}

class MarkersView: UIView {
    
    // Properties
    var delegate : MarkersViewDelegate?
    
    // UIButtons
    var f_individualBtn     : UIButton!
    var f_genericBtn        : UIButton!
    var f_collectiveBtn     : UIButton!
    var s_individualBtn     : UIButton!
    var s_genericBtn        : UIButton!
    var s_collectiveBtn     : UIButton!
    
    //MARK: - Override function
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initLayout()
    }
    
    init(_ frame: CGRect, _ target: FanGenerationVideoView) {
        super.init(frame: frame)
        self.delegate = target
        initLayout()
    }
    
    //MARK: - Main functions
    func initLayout() {
        
        f_individualBtn = UIButton()
        f_individualBtn.translatesAutoresizingMaskIntoConstraints = false
        f_individualBtn.setBackgroundImage(FanGenViewBtn.individual.image, for: .normal)
        f_individualBtn.addTarget(self, action: #selector(onFIndividualBtn(_:)), for: .touchUpInside)
        addSubview(f_individualBtn)
        
        f_genericBtn = UIButton()
        f_genericBtn.translatesAutoresizingMaskIntoConstraints = false
        f_genericBtn.setBackgroundImage(FanGenViewBtn.generic.image, for: .normal)
        f_genericBtn.addTarget(self, action: #selector(onFGenericBtn(_:)), for: .touchUpInside)
        addSubview(f_genericBtn)
        
        f_collectiveBtn = UIButton()
        f_collectiveBtn.translatesAutoresizingMaskIntoConstraints = false
        f_collectiveBtn.setBackgroundImage(FanGenViewBtn.collective.image, for: .normal)
        f_collectiveBtn.addTarget(self, action: #selector(onFCollectiveBtn(_:)), for: .touchUpInside)
        addSubview(f_collectiveBtn)
        
        s_individualBtn = UIButton()
        s_individualBtn.translatesAutoresizingMaskIntoConstraints = false
        s_individualBtn.setBackgroundImage(FanGenViewBtn.individual.image, for: .normal)
        s_individualBtn.addTarget(self, action: #selector(onSIndividualBtn(_:)), for: .touchUpInside)
        addSubview(s_individualBtn)
        
        s_genericBtn = UIButton()
        s_genericBtn.translatesAutoresizingMaskIntoConstraints = false
        s_genericBtn.setBackgroundImage(FanGenViewBtn.generic.image, for: .normal)
        s_genericBtn.addTarget(self, action: #selector(onSGenericBtn(_:)), for: .touchUpInside)
        addSubview(s_genericBtn)
        
        s_collectiveBtn = UIButton()
        s_collectiveBtn.translatesAutoresizingMaskIntoConstraints = false
        s_collectiveBtn.setBackgroundImage(FanGenViewBtn.collective.image, for: .normal)
        s_collectiveBtn.addTarget(self, action: #selector(onSCollectiveBtn(_:)), for: .touchUpInside)
        addSubview(s_collectiveBtn)
        
        NSLayoutConstraint.activate([
            // First team's markers
            NSLayoutConstraint(item: f_individualBtn, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: f_individualBtn, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 0.5, constant: 0),
            NSLayoutConstraint(item: f_individualBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            NSLayoutConstraint(item: f_individualBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            
            NSLayoutConstraint(item: f_genericBtn, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: f_genericBtn, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: f_genericBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            NSLayoutConstraint(item: f_genericBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            
            NSLayoutConstraint(item: f_collectiveBtn, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: f_collectiveBtn, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.5, constant: 0),
            NSLayoutConstraint(item: f_collectiveBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            NSLayoutConstraint(item: f_collectiveBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            
            // Second team's markers
            NSLayoutConstraint(item: s_individualBtn, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: s_individualBtn, attribute: .centerY, relatedBy: .equal, toItem: f_individualBtn, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: s_individualBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            NSLayoutConstraint(item: s_individualBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            
            NSLayoutConstraint(item: s_genericBtn, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: s_genericBtn, attribute: .centerY, relatedBy: .equal, toItem: f_genericBtn, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: s_genericBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            NSLayoutConstraint(item: s_genericBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            
            NSLayoutConstraint(item: s_collectiveBtn, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: s_collectiveBtn, attribute: .centerY, relatedBy: .equal, toItem: f_collectiveBtn, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: s_collectiveBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            NSLayoutConstraint(item: s_collectiveBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48)
        ])
    }
    
}

extension MarkersView {
    //MARK: - Button functions
    @objc func onFIndividualBtn(_ sender: Any) {
        delegate?.didTap(on: self, btn: f_individualBtn, type: .individual, team: .first)
    }
    
    @objc func onFGenericBtn(_ sender: Any) {
        delegate?.didTap(on: self, btn: f_genericBtn, type: .generic, team: .first)
    }
    
    @objc func onFCollectiveBtn(_ sender: Any) {
        delegate?.didTap(on: self, btn: f_collectiveBtn, type: .collective, team: .first)
    }
    
    @objc func onSIndividualBtn(_ sender: Any) {
        delegate?.didTap(on: self, btn: s_individualBtn, type: .individual, team: .second)
        print("second individual")
    }
    
    @objc func onSGenericBtn(_ sender: Any) {
        delegate?.didTap(on: self, btn: s_genericBtn, type: .generic, team: .second)
    }
    
    @objc func onSCollectiveBtn(_ sender: Any) {
        delegate?.didTap(on: self, btn: s_collectiveBtn, type: .collective, team: .second)
    }
}
