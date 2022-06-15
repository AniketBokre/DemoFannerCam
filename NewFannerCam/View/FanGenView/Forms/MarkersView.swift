//
//  TopBarView.swift
//  NewFannerCam
//
//  Created by Jin on 1/21/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit

protocol MarkersViewDelegate: class {
    func didTap(on view: MarkersView, btn: UIButton, type: FanGenMarker, team: Team, countPressed: Int)
}

class MarkersView: UIView {
    
    class func instanceFormNib() -> MarkersView {
        let selfView = UINib(nibName: FanGenId.markersViewNib, bundle: nil).instantiate(withOwner: self, options: nil)[0] as! MarkersView
        selfView.initialize()
        return selfView
    }
    
    @IBOutlet weak var f_individualBtn     : UIButton!
    @IBOutlet weak var f_genericBtn        : UIButton!
    @IBOutlet weak var f_collectiveBtn     : UIButton!
    @IBOutlet weak var s_individualBtn     : UIButton!
    @IBOutlet weak var s_genericBtn        : UIButton!
    @IBOutlet weak var s_collectiveBtn     : UIButton!
    
    // constraints
    @IBOutlet weak var f_indiWidthCons: NSLayoutConstraint!
    
    @IBOutlet weak var f_indiLeadingCons: NSLayoutConstraint!
    @IBOutlet weak var f_genLeadingCons: NSLayoutConstraint!
    @IBOutlet weak var f_colLeadingCons: NSLayoutConstraint!
    
    @IBOutlet weak var f_indiVerticalCons: NSLayoutConstraint!
    @IBOutlet weak var f_genVerticalCons: NSLayoutConstraint!
    @IBOutlet weak var f_colVerticalCons: NSLayoutConstraint!
    
    @IBOutlet weak var s_indiTrailingCons: NSLayoutConstraint!
    @IBOutlet weak var s_genTrailingCons: NSLayoutConstraint!
    @IBOutlet weak var s_colTrailingCons: NSLayoutConstraint!
    
    // Properties
    weak var delegate : MarkersViewDelegate?
    
    var activatedBtn                        : UIButton!
    
    private var markerTimer                 : Timer!
    private var countPressed                : Int = 0
    
//MARK: - Override function
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initialize() {
        f_individualBtn.isMultipleTouchEnabled = true
        f_genericBtn.isMultipleTouchEnabled = true
        f_collectiveBtn.isMultipleTouchEnabled = true
        s_individualBtn.isMultipleTouchEnabled = true
        s_genericBtn.isMultipleTouchEnabled = true
        s_collectiveBtn.isMultipleTouchEnabled = true
        
        if UI_USER_INTERFACE_IDIOM() != .phone {
            
            let width : CGFloat = 60.0
            let sideGap : CGFloat = 50.0
            let centerDiffer : CGFloat = 70.0
            
            f_indiWidthCons.constant = width
            
            f_indiLeadingCons.constant = sideGap
            f_genLeadingCons.constant = sideGap
            f_colLeadingCons.constant = sideGap
            
            s_indiTrailingCons.constant = sideGap
            s_genTrailingCons.constant = sideGap
            s_colTrailingCons.constant = sideGap
            
            f_indiVerticalCons.constant = centerDiffer
            f_colVerticalCons.constant -= centerDiffer
        }
        
        // Notification
        NotificationCenter.default.addObserver(self, selector: #selector(didTapOnCollective(_:)), name: NSNotification.Name(rawValue: "TapOnCollective"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didTapOnGeneric(_:)), name: NSNotification.Name(rawValue: "TapOnGeneric"), object: nil)
    }
    
    @objc func didTapOnCollective(_ notification: Notification) {
       // releaseMarkerBtn(s_collectiveBtn)
     //   delegate?.didTap(on: self, btn: f_collectiveBtn, type: .collective, team: .first, countPressed: countPressed)
        
        activatedBtn = s_collectiveBtn
        setTimer(release: true)
        delegate?.didTap(on: self, btn: s_collectiveBtn, type: .collective, team: .second, countPressed: countPressed)
    }
    
    @objc func didTapOnGeneric(_ notification: Notification) {
        // releaseMarkerBtn(s_collectiveBtn)
        //   delegate?.didTap(on: self, btn: f_collectiveBtn, type: .collective, team: .first, countPressed: countPressed)
        activatedBtn = s_genericBtn
        setTimer(release: true)
        //delegate?.didTap(on: self, btn: s_genericBtn, type: .generic, team: .second, countPressed: countPressed)
        isFromWatch = false
        
        releaseMarkerBtn(s_genericBtn)
    }
    deinit {
            NotificationCenter.default.removeObserver(self)
    }
  
    
//MARK: - Main functions
    
    private func setEnabled(of btn: UIButton, to val: Bool) {
        btn.isEnabled = val
        btn.alpha = val ? 1 : 0.5
    }
    
    private func set(hide: Bool) {
        
    }
    
    private func setTimer(release: Bool) {
        if release {
            countPressed = 0
            markerTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(markerTimerHandle(_:)), userInfo: nil, repeats: true)
        } else {
            if markerTimer != nil {
                if countPressed >= 1 {
                    setMarkerBtns(enabled: true)
                }
                markerTimer.invalidate()
                markerTimer = nil
                DispatchQueue.main.async {
                    self.activatedBtn.setTitle(nil, for: .normal)
                }
            }
        }
    }
    
    @objc private func markerTimerHandle(_ timer: Timer) {
        countPressed += 1
        if countPressed >= 1 {
            setMarkerBtns(enabled: false)
        }
        let min = countPressed/60
        let sec = countPressed%60
        let title = String(format: "%02d:%02d", min, sec)
        activatedBtn.setTitle(title, for: UIControl.State.normal)
        
        if countPressed >= 60 {
            releaseMarkerBtn(activatedBtn)
        }
    }
    
    @objc private func removeMarkerAnimationView(animationView: UIImageView) {
        animationView.removeFromSuperview()
    }
    
    private func releaseMarkerBtn(_ sender: UIButton) {
        
        guard markerTimer != nil else {
            return
        }
        
        setTimer(release: false)
        
        if sender == f_individualBtn {
            delegate?.didTap(on: self, btn: sender, type: .individual, team: .first, countPressed: countPressed)
        }
        else if sender == f_genericBtn {
            markerEndAnimation()
            delegate?.didTap(on: self, btn: sender, type: .generic, team: .first, countPressed: countPressed)
        }
        else if sender == f_collectiveBtn {
            delegate?.didTap(on: self, btn: sender, type: .collective, team: .first, countPressed: countPressed)
        }
        else if sender == s_individualBtn {
            delegate?.didTap(on: self, btn: sender, type: .individual, team: .second, countPressed: countPressed)
        }
        else if sender == s_genericBtn {
            markerEndAnimation()
            delegate?.didTap(on: self, btn: sender, type: .generic, team: .second, countPressed: countPressed)
        }
        else if sender == s_collectiveBtn {
            delegate?.didTap(on: self, btn: sender, type: .collective, team: .second, countPressed: countPressed)
        }
    }
}

//MARK: - Access functions

extension MarkersView {
    func markerEndAnimation() {
        DispatchQueue.main.async {
            let animationView = UIImageView(image: self.activatedBtn.backgroundImage(for: .normal))
            animationView.frame = self.activatedBtn.frame
        
        self.addSubview(animationView)
        
        UIView.beginAnimations(nil, context: nil)
        UIView.animate(withDuration: 3, animations: {
            animationView.frame = CGRect(x: self.frame.size.width/2-50, y: self.frame.size.height/2-50, width: 100, height: 100)
        }) { (finished) in
            self.perform(#selector(self.removeMarkerAnimationView(animationView:)), with: animationView, afterDelay: 1.0)
        }
        UIView.commitAnimations()
        }
    }
    
    func undoMarkerAnimation(_ marker: Marker, _ team: Team) {
        var undoMarkerBtn = UIButton()
        
        if team == .first {
            if marker.type == .individual {
                undoMarkerBtn = f_individualBtn
            }
            else if marker.type == .generic {
                undoMarkerBtn = f_genericBtn
            }
            else {
                undoMarkerBtn = f_collectiveBtn
            }
        } else {
            if marker.type == .individual {
                undoMarkerBtn = s_individualBtn
            }
            else if marker.type == .generic {
                undoMarkerBtn = s_genericBtn
            }
            else {
                undoMarkerBtn = s_collectiveBtn
            }
        }
        
        let animationView = UIImageView(image: undoMarkerBtn.backgroundImage(for: .normal))
        animationView.frame = CGRect(x: self.frame.size.width/2-50, y: self.frame.size.height/2-50, width: 100, height: 100)
        addSubview(animationView)
        
        UIView.beginAnimations(nil, context: nil)
        UIView.animate(withDuration: 3, animations: {
            animationView.frame = undoMarkerBtn.frame
        }) { (finished) in
            animationView.removeFromSuperview()
        }
        UIView.commitAnimations()
    }
    
    func setMarkerBtns(enabled val: Bool) {
        setEnabled(of: f_individualBtn, to: val)
        setEnabled(of: f_genericBtn, to: val)
        setEnabled(of: f_collectiveBtn, to: val)
        setEnabled(of: s_individualBtn, to: val)
        setEnabled(of: s_genericBtn, to: val)
        setEnabled(of: s_collectiveBtn, to: val)
    }
    
    func setIndColMarkerBtns(hide: Bool) {
        f_individualBtn.isHidden = hide
        f_collectiveBtn.isHidden = hide
        s_individualBtn.isHidden = hide
        s_collectiveBtn.isHidden = hide
    }
}

//MARK: - Button functions
extension MarkersView {
    
    @IBAction func onTouchDown(_ sender: UIButton) {
        isFromWatch = false

        activatedBtn = sender
        setTimer(release: true)
    }
    
    @IBAction func onTouchUp(_ sender: UIButton) {
        isFromWatch = false

        releaseMarkerBtn(sender)
    }
    
    @IBAction func onTouchDragExit(_ sender: UIButton) {
        releaseMarkerBtn(sender)
    }
}
