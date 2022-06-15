//
//  TagsView.swift
//  NewFannerCam
//
//  Created by Jin on 1/24/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol TagsViewDataSource: class {
    func numberOfTags(in tagView: TagsView) -> Int
    func tagsView(_ tagsView: TagsView, tagMarkerAt index: Int) -> Marker
}

protocol TagsViewDelegate: class {
    func tagsView(_ tagNumView: TagNumView, didClickedSave button: UIButton, tagNum value: String)
    
    func tagsView(_ tagsView: TagsView, didSelectTagAt index: Int, _ type: FanGenMarker)
    func tagsView(_ tagsView: TagsView, heightForTagViewAt index: Int) -> CGFloat
}

class TagsView: UIView {
    
    class func instanceFromNib() -> TagsView {
        let selfView = UINib(nibName: FanGenId.tagsViewNib, bundle: nil).instantiate(withOwner: self, options: nil)[0] as! TagsView
        selfView.initLayout()
        return selfView
    }
    
    @IBOutlet weak var tagList: UITableView!
    @IBOutlet weak var tagLbl: UILabel!
    @IBOutlet weak var middleView : UIView!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: TagsViewDelegate?
    weak var dataSource : TagsViewDataSource?
    
    weak var tagNumView: TagNumView!
    
    private var selectedMarkerType          : FanGenMarker = FanGenMarker.individual
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Notification
        NotificationCenter.default.addObserver(self, selector: #selector(didTapOnCollectiveTag(_:)), name: NSNotification.Name(rawValue: "TapOnCollectiveTag"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
//MARK: - Main functions
    
}

//MARK: - TagListViewCellDelegate
extension TagsView: TagListViewCellDelegate {
    
    func tagListViewCell(_ cell: TagListViewCell, didTapTagBtn btn: UIButton) {
        isFromWatch = false
        let indexPath = tagList.indexPath(for: cell)!
        delegate?.tagsView(self, didSelectTagAt: indexPath.row, selectedMarkerType)
        if selectedMarkerType == .individual {
            addTagNumView()
        }
    }
    // Code for select Tag
    @objc func didTapOnCollectiveTag(_ notification: Notification) {
       // let indexPath =    //tagList.indexPath(for: cell)!
        
        if let selectedIndex = (notification as NSNotification).userInfo?["SelectedTag"] as? Int {
            delegate?.tagsView(self, didSelectTagAt: selectedIndex, selectedMarkerType)
            if selectedMarkerType == .individual {
                addTagNumView()
            }
        }
    }
}

//MARK: - Table view data source & delegate
extension TagsView : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.numberOfTags(in: self) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FanGenId.cellId, for: indexPath) as! TagListViewCell
        if let marker = dataSource?.tagsView(self, tagMarkerAt: indexPath.row) {
            cell.initData(marker, self)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return delegate?.tagsView(self, heightForTagViewAt: indexPath.row) ?? 44
        } else {
            return 70
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

//MARK: - TagNumViewDelegate

extension TagsView: TagNumViewDelegate {
    func tagNumView(_ tagNumView: TagNumView, didClickedSave btn: UIButton, tagNum value: String) {
        delegate?.tagsView(tagNumView, didClickedSave: btn, tagNum: value)
        tagNumView.removeFromSuperview()
    }
}

//MARK: - data for UI set funcitons

extension TagsView {
    func initLayout() {
        tagList.dataSource = self
        tagList.delegate = self
        tagList.register(UINib(nibName: FanGenId.fanGenCellNib, bundle: nil), forCellReuseIdentifier: FanGenId.cellId)
        
        if UI_USER_INTERFACE_IDIOM() == .phone {
            titleTopConstraint.constant = 40
            tableTopConstraint.constant = 12
            tableBottomConstraint.constant = 12
        } else {
            titleTopConstraint.constant = 150
            tableTopConstraint.constant = 40
            tableBottomConstraint.constant = 100
            tableWidthConstraint.constant = -100
        }
    }
    
    func addTagNumView() {
        tagNumView = TagNumView.instanceFromNib()
        tagNumView.delegate = self
        tagNumView.frame = CGRect(x: 0, y: 0, width: middleView.frame.width, height: middleView.frame.height)
        tagNumView.translatesAutoresizingMaskIntoConstraints = false
        middleView.isHidden = false
        tagList.isHidden = true
        middleView.addSubview(tagNumView)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: tagNumView as Any, attribute: .leading, relatedBy: .equal, toItem: middleView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tagNumView as Any, attribute: .trailing, relatedBy: .equal, toItem: middleView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tagNumView as Any, attribute: .top, relatedBy: .equal, toItem: middleView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tagNumView as Any, attribute: .bottom, relatedBy: .equal, toItem: middleView, attribute: .bottom, multiplier: 1, constant: 0)
            ])
    }
    
    func set(_ type: FanGenMarker) {
        selectedMarkerType = type
        let title = type == .individual ? "Individual Tag" : "Collective Tag"
        tagLbl.text = title
    }
}
