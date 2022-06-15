//
//  MatchRecoveryVC.swift
//  NewFannerCam
//
//  Created by Jin on 3/13/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

protocol MatchRecoveryVCDelegate: class {
    func dismissRecoveryVC(withLostMainVideos lostMainVideos: [MainVideo]?)
}

class MatchRecoveryVC: UIViewController {

//MARK: - IBOutlet Properties
    @IBOutlet weak var mTableView: UITableView!
    @IBOutlet weak var doneBtn: UIButton!
    
//MARK: - Properties
    // Properties Initialized by MatchesHighlightsVC
    var selectedMatch               : SelectedMatch!
    
    // Table View Properties
    var urlArray = [URL]()
    var selectedRows = [IndexPath]()
    
    // Other Properties
    weak var delegate : MatchRecoveryVCDelegate?
    
//MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        animationForStartOrEnd(isStart: true)
        
        initArrays()
        
        initViews()
    }
    
//MARK: - Initial Functions
    func initArrays() {
        urlArray = dirManager.getFiles(in: selectedMatch.match.mainVideoPath())
        mTableView.reloadData()
    }
    
    func initViews() {
        setDoneBtnAvailable()
    }
    
//MARK: - Custom Functions
    func setDoneBtnAvailable() {
        if self.selectedRows.count == 0 {
            doneBtn.isEnabled = false
            doneBtn.alpha = 0.4
        } else {
            doneBtn.isEnabled = true
            doneBtn.alpha = 1
        }
    }
    
    func createNewMainVideoItem(with url: URL) -> MainVideo {
        var new = MainVideo(selectedMatch.match.id, selectedMatch.match.newMainVideoStartTime(CMTIMESCALE), selectedMatch.match.scoreboardSetting.period)
        new.fileName = url.lastPathComponent
        return new
    }
    
    func getExistingMainVideoItem(of url: URL) -> MainVideo? {
        return selectedMatch.match.mainVideos.first { $0.fileName == url.lastPathComponent }
    }
    
    // Animation
    func animationForStartOrEnd(isStart: Bool) {
        let size = UIScreen.main.bounds.size
        if isStart {
            view.frame = CGRect(x: 0, y: size.height, width: size.width, height: size.height)
        } else {
            view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
        UIView.beginAnimations(nil, context: nil)
        
        //old position
        UIView.animate(withDuration: 5, animations: {
            if isStart {
                self.view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            } else {
                self.view.frame = CGRect(x: 0, y: size.height, width: size.width, height: size.height)
            }
        }) { (finished) in
            //
        }
        UIView.commitAnimations()
    }
    
//MARK: - IBAction Functions
    @IBAction func onExitBtn(_ sender: Any) {
//        animationForStartOrEnd(isStart: false)
        delegate?.dismissRecoveryVC(withLostMainVideos: nil)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDoneBtn(_ sender: Any) {
//        animationForStartOrEnd(isStart: false)
        var newMainVideos : [MainVideo]?
        if selectedRows.count != 0 {
            newMainVideos = [MainVideo]()
            for indexPath in selectedRows {
                let temp = createNewMainVideoItem(with: urlArray[indexPath.row])
                newMainVideos?.append(temp)
            }
        }
        self.delegate?.dismissRecoveryVC(withLostMainVideos: newMainVideos)
        dismiss(animated: true, completion: nil)
    }
    
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension MatchRecoveryVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urlArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecoveryCell", for: indexPath) as! RecoveryCell
        
        if selectedRows.contains(indexPath) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        if let videoItem = getExistingMainVideoItem(of: urlArray[indexPath.row]) {
            cell.contentView.alpha = 0.3
            
            let duration = Int(CMTimeGetSeconds(videoItem.duration()))
            let startTime = Int(CMTimeGetSeconds(videoItem.startTime))
            
            cell.descriptionLbl.text = """
            Duration : \(AVPlayerService.getTimeString(from: duration))
            Time in match : \(AVPlayerService.getTimeString(from: startTime)) - \(AVPlayerService.getTimeString(from: startTime + duration))
            """
        } else {
            cell.contentView.alpha = 1
            cell.descriptionLbl.text = "Not Taken File"
        }
        DispatchQueue.main.async {
            let key = "recovery_\(self.urlArray[indexPath.row].lastPathComponent)"
            if let preview = DataManager.shared.getImageCache(forKey: key) {
                cell.thumbnailImgView.image = preview
            } else {
                let preview = ImageProcess.getFrame(url: self.urlArray[indexPath.row], fromTime: 0.0)
                let resized = ImageProcess.resize(image: preview, scaledToSize: cell.thumbnailImgView.bounds.size)
                cell.thumbnailImgView.image = resized
                DataManager.shared.set(cache: resized, for: key)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let _ = getExistingMainVideoItem(of: urlArray[indexPath.row]) {
            return
        }
        if selectedRows.contains(indexPath) {
            let index = (selectedRows.firstIndex(of: indexPath))
            selectedRows.remove(at: index!)
        } else {
            selectedRows.append(indexPath)
        }
        if selectedRows.count == 0 {
            doneBtn.isEnabled = false
        } else {
            doneBtn.isEnabled = true
        }
        
        tableView.update(row: indexPath, for: .replace)
        setDoneBtnAvailable()
    }

}
