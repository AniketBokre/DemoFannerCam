//
//  HighlightsVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/27/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit

private let cellID = "VideoCell"

class VideosVC: UIViewController {

    @IBOutlet weak var mTableView           : UITableView!
    @IBOutlet weak var statusLbl            : UILabel!
    
    //MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        FannerCamWatchKitShared.sharedManager.delegate =  self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DataManager.shared.videosDelegate = self
        
        mTableView.reloadData()
        setStatus()
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: ["message":"Get Call"]) {
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.Segue.VideoPlaySegueId {
            let vc = segue.destination as! VideoPlayerVC
            let index = sender as! Int
            vc.currentVideo = DataManager.shared.videos[index]
        }
    }
    
//MARK: - Main functions
    func setStatus() {
        statusLbl.isHidden = DataManager.shared.videos.count != 0
    }
    
    func showCreateNewMatchVC(_ mode: MatchType) {
        if let nvc = createMatchNVC(with: mode) {
            present(nvc, animated: true, completion: nil)
        }
    }
    
    func showEditNameView(with index: Int) {
        var video = DataManager.shared.videos[index]
        
        let alert = UIAlertController(title: "Edit name", message: nil, preferredStyle: .alert)
        alert.addTextField { (nameTF) in
            nameTF.placeholder = "Highlight name"
            nameTF.text = video.title
            nameTF.textAlignment = .center
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        cancel.setValue(Constant.Color.defaultBlack, forKey: SheetKeys.titleTextColor.rawValue)
        alert.addAction(cancel)

        let yes = UIAlertAction(title: "Save", style: .default) { (yesAction) in
            video.title = alert.textFields?[0].text
            DataManager.shared.updateVideos(video, .replace)
        }
        yes.setValue(Constant.Color.defaultBlack, forKey: SheetKeys.titleTextColor.rawValue)
        alert.addAction(yes)
        
        present(alert, animated: true, completion: nil)
    }
    
    func shareVideo(_ video: Video, _ sender: UIButton) {
        showShareView(url: video.filePath(), sender)
    }
    
//MARK: - IBAction functions
    @IBAction func onCreateImportBtn(_ sender: Any) {
        self.showCreateNewMatchVC(.importMatch)
    }
    
    @IBAction func onCreateRecordBtn(_ sender: Any) {
        self.showCreateNewMatchVC(.recordMatch)
    }
    
}

extension VideosVC : FannerCamWatchKitSharedDelegate {
    func getDataFromWatch(watchMessage: [String : Any]) {
        
        print(watchMessage)
    }
}
//MARK: - DataManagerDelegate
extension VideosVC : DataManagerVideosDelegate {
    func didUpdateVideos(_ updateMode: Updater, _ updatedItem: Video?, _ index: Int?) {
        
        var row : IndexPath!
        
        if let rowIndex = index {
            row = IndexPath(row: rowIndex, section: 0)
        } else {
            row = IndexPath(row: 0, section: 0)
        }
        
        mTableView.update(row: row, for: updateMode)
    }
}

//MARK: - VideoCellDelegate
extension VideosVC: VideoCellDelegate {
    func videoCell(_ cell: VideoCell, didClickedMore btn: UIButton) {
        let indexPath = mTableView.indexPath(for: cell)!
        let video = DataManager.shared.videos[indexPath.row]
        
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover
        sheetController.addAction(UIAlertAction(title: "Share", style: .default) { (shareAction) in
            self.shareVideo(video, btn)
        })
        sheetController.addAction(UIAlertAction(title: "Edit name", style: .default) { (editAction) in
            self.showEditNameView(with: indexPath.row)
        })
        let sheetAction = UIAlertAction(title: "Delete Highlights", style: .default) { (deleteAction) in
            MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure to delete this \"\(video.title ?? String())\" video?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
                
                DataManager.shared.updateVideos(video, .delete)
                self.setStatus()
            
            }, onNo: nil)
        }
        sheetAction.setValue(Constant.Color.red, forKey: SheetKeys.titleTextColor.rawValue)
        sheetController.addAction(sheetAction)
        sheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let presenter = sheetController.popoverPresentationController {
            presenter.sourceView = btn
            presenter.sourceRect = btn.bounds
        }
        present(sheetController, animated: true, completion: nil)
    }
}

//MARK: - UITableViewDelegate & data source
extension VideosVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.shared.videos.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (view.bounds.width/16) * 9 + 40
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        if let result = (view.bounds.width/16) * 9 + 40 as? UITableView.automaticDimension {
//            return result
//        }
//        return UITableView.automaticDimension
        return (view.bounds.width/16) * 9 + 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! VideoCell
        cell.initialize(DataManager.shared.videos[indexPath.row], self)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Constant.Segue.VideoPlaySegueId, sender: indexPath.row)
    }
    
}
