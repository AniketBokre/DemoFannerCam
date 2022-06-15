//
//  MatchesDetailReportVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/5/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

private let sectionId = "MathcesDetailReportSection"
private let cellId = "MatchesDetailReportCell"

enum ReportViewMode: Int {
    case players        = 0
    case individual     = 1
    case collective     = 2
    
    var printTitle : String {
        switch self {
        case .players:
            return "TAG numerici\n\n"
        case .individual:
            return "TAG Individuali\n\n"
        case .collective:
            return "TAG Collettivi\n\n"
        }
    }
}

typealias ReportViewDict = [Int: [ReportClip]]

class MatchesDetailReportVC: UIViewController {

    @IBOutlet weak var mTableView       : UITableView!
    @IBOutlet weak var topRedLineView   : UIView!
    
    private var viewMode                = ReportViewMode.players
    private var playersDict             = ReportViewDict()
    private var individualReportClips   = [ReportClip]()
    private var collectiveReportClips   = [ReportClip]()
    
    var selectedMatch                   : SelectedMatch!
    
//MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initViewData()
    }
    
//MARK: - Main functions
    func animateRedLineView(to point: CGRect) {
        UIView.animate(withDuration: 0.2) {
            self.topRedLineView.frame = point
        }
    }
    
    func createVideo(_ highBitrate: Bool, _ generator: VideoProcess) {
        guard DataManager.shared.getSelectedTemplate() != nil else {
            MessageBarService.shared.warning("You should use the Template. Please download templates and select one of them in Setting.")
            return
        }
        
        Utiles.setHUD(true, view, .extraLight, "Generating each clip...")
        
        dirManager.clearTempDir()
        DispatchQueue.global().async {
            let newVideo = Video(self.selectedMatch.match.namePresentation(), highBitrate, self.selectedMatch.match.quality())
            
            self.clipVideos(highBitrate, newVideo, 0, generator)
        }
        
    }
    
    func clipVideos(_ highBitrate: Bool, _ newVideo: Video, _ index: Int, _ generator: VideoProcess) {
        Utiles.setHUD("Generating the \(index.sequenth()) clip...") 
        generator.generateSingleMediaFile(selectedMatch.match.quality(), highBitrate, generator.clips[index]) { (isSuccess, resultDes) in
            if isSuccess {
                
                if index == generator.clips.count - 1 {
                    
                    Utiles.setHUD("Final step for generating...")
                    
                    generator.generateNewVideo(highBitrate, newVideo, { (done, str) in
                        if done {
                            DataManager.shared.updateVideos(newVideo, .new)
                            MessageBarService.shared.notify("Successfully created a video!")
                        } else {
                            MessageBarService.shared.error(resultDes)
                        }
                        Utiles.setHUD(false)
                    })
                } else {
                    self.clipVideos(highBitrate, newVideo, index + 1, generator)
                }
            } else {
                MessageBarService.shared.error(resultDes)
                Utiles.setHUD(false)
            }
        }
    }

//MARK: - IBAction functions
    @IBAction func onFilterBtn(_ sender: UIButton) {
        
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover
        let titles = [
            ActionTitleData(actionImage: nil, imgTintColor: nil, isChecked: true, title: ActionTitle.onlySelected.rawValue),
            ActionTitleData(actionImage: nil, imgTintColor: nil, isChecked: false, title: "All tags"),
            ActionTitleData(actionImage: nil, imgTintColor: nil, isChecked: false, title: "Gol"),
            ActionTitleData(actionImage: nil, imgTintColor: nil, isChecked: false, title: "Action"),
            ActionTitleData(actionImage: nil, imgTintColor: nil, isChecked: false, title: "Cross")
        ]
        
        titles.forEach { (param) in
            let action = self.fanSheetAction(titleData: param, handler: { (sheetAction) in
                print(sheetAction.title ?? "No name")
                //TODO: do desired action
            })
            sheetController.addAction(action)
        }
        
        sheetController.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        if let presenter = sheetController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        present(sheetController, animated: true, completion: nil)
    }
    
    @IBAction func onPlayersBtn(_ sender: UIButton) {
        viewMode = .players
        mTableView.reloadData()
        animateRedLineView(to: CGRect(x: 0, y: topRedLineView.frame.origin.y, width: topRedLineView.frame.width, height: topRedLineView.frame.height))
    }
    
    @IBAction func onIndividualBtn(_ sender: UIButton) {
        viewMode = .individual
        mTableView.reloadData()
        animateRedLineView(to: CGRect(x: view.bounds.width/2 - topRedLineView.frame.width/2, y: topRedLineView.frame.origin.y, width: topRedLineView.frame.width, height: topRedLineView.frame.height))
    }
    
    @IBAction func onCollectiveBtn(_ sender: UIButton) {
        viewMode = .collective
        mTableView.reloadData()
        animateRedLineView(to: CGRect(x: view.bounds.width - topRedLineView.frame.width, y: topRedLineView.frame.origin.y, width: topRedLineView.frame.width, height: topRedLineView.frame.height))
    }
    
    @IBAction func onPrintBtn(_ sender: UIButton) {
        let fileName  = "FannerCam_Report_Print"
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
        
        let writeString = makePrintString()
        
        do {
            try writeString.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            
            self.showShareView(url: fileURL, sender) 
        } catch let error {
            MessageBarService.shared.error(error.localizedDescription)
        }
    }
    
    @IBAction func onCreateVideoBtn(_ sender: UIButton) {
        let selectedClips = genClipsForVideo()
        guard selectedClips.count > 0 else {
            MessageBarService.shared.warning("No selected clips!")
            return
        }
        
        let generator = VideoProcess(selectedClips, selectedMatch.match)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        let highAction = UIAlertAction(title: ActionTitle.standarQuality.rawValue, style: .default) { (highAction) in
            self.createVideo(true, generator)
        }
        let meAction = UIAlertAction(title: ActionTitle.webQuality.rawValue, style: .default) { (meAction) in
            self.createVideo(false, generator)
        }
        alert.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        alert.addAction(highAction)
        alert.addAction(meAction)
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func onBackBtn(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
}

//MARK: - MatchesReportClipCellDelegate
extension MatchesDetailReportVC: MatchesReportClipCellDelegate {
    func matchReportCell(_ cell: MatchesReportClipCell, didClickedCheckFor team: Team, _ isSelected: Bool, _ selectedReportClip: ReportClip) {
        let indexPath = mTableView.indexPath(for: cell)!
        switch viewMode {
        case .players:
            let key = playersDict.keys.sorted()[indexPath.section]
            playersDict[key]![indexPath.row] = selectedReportClip
            break
        case .individual:
            individualReportClips[indexPath.row] = selectedReportClip
            break
        case .collective:
            collectiveReportClips[indexPath.row] = selectedReportClip
            break
        }
    }
}

//MARK: - UITableViewDelegate & UITableViewDataSource
extension MatchesDetailReportVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if viewMode == .players {
            return playersDict.keys.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewMode == .players {
            let key = playersDict.keys.sorted()[section]
            return playersDict[key]!.count
        } else if viewMode == .individual {
            return individualReportClips.count
        } else {
            return collectiveReportClips.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewMode == .players {
            return 60
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewMode == .players {
            let headerViewCell = tableView.dequeueReusableCell(withIdentifier: sectionId)
            
            let txtLbl = headerViewCell?.viewWithTag(145) as! UILabel
            txtLbl.text = "\(playersDict.keys.sorted()[section])"
            
            return headerViewCell
        } else {
            let view = UIView()
            return view
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! MatchesReportClipCell
        if viewMode == .players {
            let sectionKey = playersDict.keys.sorted()[indexPath.section]
            cell.initialize(self, playersDict[sectionKey]![indexPath.row])
        }
        else if viewMode == .individual {
            cell.initialize(self, individualReportClips[indexPath.row])
        }
        else if viewMode == .collective {
            cell.initialize(self, collectiveReportClips[indexPath.row])
        }
        
        return cell
    }
    
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

//Mark: View Data management
extension MatchesDetailReportVC {
    func initViewData() {
        playersDict = getViewDict(.players)
        individualReportClips = getIndiCollReportClips(from: getViewDict(.individual), type: .individual)
        collectiveReportClips = getIndiCollReportClips(from: getViewDict(.collective), type: .collective)
    }
    
    func getViewDict(_ mode: ReportViewMode) -> ReportViewDict {
        var result = [Int: [ReportClip]]()
        var clips = [Clip]()
        
        if mode == .players {
            clips = selectedMatch.match.clips.filter{ $0.marker.type == .individual }
        }
        else if mode == .individual {
            clips = selectedMatch.match.clips.filter{ $0.marker.type == .individual }
        }
        else {
            clips = selectedMatch.match.clips.filter{ $0.marker.type == .collective }
        }
        
        for clip in clips {
            
            if let tagNum = clip.clipTag {
                
                result = setNewReportClip(tagNum, clip, result)
                
            } else {
                
                result = setNewReportClip(Int(clip.marker.id)!, clip, result)
                
            }
        }
        
        return result
    }
    
    func setNewReportClip(_ key: Int, _ clip: Clip, _ result: [Int: [ReportClip]]) -> [Int: [ReportClip]] {
        let keys = result.keys.sorted()
        var temp = result
        
        if keys.contains(key) {
            
            var reportClips = temp[key] ?? [ReportClip]()
            let containedIndexObj = reportClips.firstIndex{ $0.clips[0].marker.id == clip.marker.id }
            
            if let containedIndex = containedIndexObj {
                
                if clip.team == .first {
                    reportClips[containedIndex].fstCount += 1
                } else {
                    reportClips[containedIndex].sndCount += 1
                }
                reportClips[containedIndex].clips.append(clip)
            } else {
                
                let reportClip = ReportClip(clip, clip.team == .first ? 1 : 0, clip.team == .second ? 1 : 0)
                reportClips.append(reportClip)
                
            }
            
            temp[key] = reportClips
            
        } else {
            
            let reportClip = ReportClip(clip, clip.team == .first ? 1 : 0, clip.team == .second ? 1 : 0)
            temp[key] = [reportClip]
        }
        
        return temp
    }
    
    func getIndiCollReportClips(from dict: ReportViewDict, type: MarkerType) -> [ReportClip] {
        var result = [ReportClip]()
        for (_, values) in dict {
            for value in values {
                result.append(value)
            }
        }
        if type == .individual {
            result.sort { $0.clips[0].clipTag < $1.clips[0].clipTag }
        } else {
            result.sort { $0.clips[0].marker.id < $1.clips[0].marker.id }
        }
        
        return result
    }
    
    func makePrintString() -> String {
        
        func getReportListString(for reportClips: [ReportClip], with mainStr: String) -> String {
            var result = mainStr
            for reportClip in reportClips {
                result += "\t"
                result += String(format: "%d\t", reportClip.fstCount)
                result += (reportClip.clips[0].marker.name as String)
                result += "\t"
                result += String.init( format:"%d\t", reportClip.sndCount) + "\n"
            }
            return result
        }
        
        var writeString = viewMode.printTitle
        
        writeString = String(format: "%@\t%@\t\t\t%@\n", writeString, selectedMatch.match.fstName, selectedMatch.match.sndName)
        
        switch viewMode {
        case .players:
            for (key, reportClips)  in  playersDict {
                if viewMode == .players {
                    writeString = writeString + "\t\t" + String(format:"%d", key) + "\n"
                }
                writeString = getReportListString(for: reportClips, with: writeString)
            }
        case .individual:
            writeString = getReportListString(for: individualReportClips, with: writeString)
        case .collective:
            writeString = getReportListString(for: collectiveReportClips, with: writeString)
        }
        
        return writeString
    }
    
    func genClipsForVideo() -> [Clip] {
        
        func sumClips(of reportClips: [ReportClip]) -> [Clip] {
            var result = [Clip]()
            for reportClip in reportClips {
                if reportClip.checkFst {
                    result.append(contentsOf: reportClip.clips.filter{ $0.team == .first })
                }
                if reportClip.checkSnd {
                    result.append(contentsOf: reportClip.clips.filter{ $0.team == .second })
                }
            }
            return result
        }
        
        var result = [Clip]()
        
        switch viewMode {
        case .players:
            for (_, values) in playersDict {
                result.append(contentsOf: sumClips(of: values))
            }
            break
        case .individual:
            result.append(contentsOf: sumClips(of: individualReportClips))
            break
        case .collective:
            result.append(contentsOf: sumClips(of: collectiveReportClips))
            break
        }
        
        return result
    }
}
