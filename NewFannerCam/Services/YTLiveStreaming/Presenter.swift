//
//  Presenter.swift
//  YouTubeLiveVideo
//
//  Created by Jin on 10/24/16.
//  Copyright © 2016 Jin. All rights reserved.
//

import UIKit
import YTLiveStreaming

protocol PresenterDelegate: class {
    func didStartLive()
    func didChangedLiveStatus()
}

class Presenter: NSObject {
    
    var delegate : PresenterDelegate?
    
    // Dependebcies
    var viewController: MatchesDetailMainVideoVC!
    var output: MatchesDetailMainVideoVC!
    var signinInteractor: GoogleConnect!
    
    var youTubeWorker: YTLiveStreaming!
    var interactor: YouTubeInteractor!
    
    fileprivate var liveBroadcast: LiveBroadcastStreamModel?
    //   fileprivate var liveViewController: LFLiveViewController!
    
    func launchShow() {
        launchSignIn()
    }
    
    func presentUserInfo() {
        if let userInfo = signinInteractor.currentUserInfo {
            //         output.presentUserInfo(connected: true, userInfo: userInfo)
            print(userInfo)
            loadData()
        } else {
            //         output.presentUserInfo(connected: false, userInfo: "")
        }
    }
    
    func launchReloadData() {
        reloadData()
    }
    
    func launchSignIn() {
        signinInteractor.signIn(with: viewController)
    }
    
    func launchSignOut() {
        signinInteractor.signOut()
        presentUserInfo()
    }
    
    func launchLiveStream(section: Int, index: Int) {
        if section == 0 {
            let broadcast = interactor.getUpcomingBroadcastItem(index: index)
            self.startBroadcast(broadcast, completed: { success in
                if success == false {
                    MessageBarService.shared.alert(message: "Can't create broadcast!")
                }
            })
        } else {
            interactor.launchLiveStream(section: section, index: index, viewController: viewController)
        }
    }
    
    func startActivity() {
        viewController.startActivity()
    }
    
    func stopActivity() {
        viewController.stopActivity()
    }
    
    func createBroadcastInVC() {
        viewController.creadeBroadcast()
    }
}

// MARK: - Privete methods

extension Presenter {
    
    fileprivate func reloadData() {
        guard signinInteractor.isConnected else {
            return
        }
        interactor.reloadData() { upcoming, current, past  in
            print(current)
            //         self.output.present(content: (upcoming, current, past))
            self.launchLiveStream(section: 0, index: 0)
        }
    }
    
    fileprivate func loadData() {
        guard signinInteractor.isConnected else {
            return
        }
        interactor.loadData() { (upcoming, current, past) in
            print(current)
            //         self.output.present(content: (upcoming, current, past))
        }
    }
}

// MARK: -
extension Presenter {
   
   func createBroadcast(_ completion: @escaping (Error?) -> Void) {
      interactor.createBroadcast(completion)
   }
   
   func startBroadcast(_ liveBroadcast: LiveBroadcastStreamModel, completed: @escaping (Bool) -> Void) {
      self.liveBroadcast = liveBroadcast
      
      print("Watch the live video: https://www.youtube.com/watch?v=\(liveBroadcast.id)")
    
        viewController.goToRecordVC()
        completed(true)
   }
   
   fileprivate func dismissVideoStreamViewController() {
      DispatchQueue.main.async {
         self.viewController.dismiss(animated: true, completion: {
         })
      }
   }
   
}

// MARK: Live stream publishing output protocol

extension Presenter: YouTubeLiveVideoOutput {
    
    func startPublishing(completed: @escaping (String?, String?) -> Void) {
        guard let broadcast = self.liveBroadcast else {
            assert(false, "Need Broadcast object for starting live video!")
            return
        }
        youTubeWorker.startBroadcast(broadcast, delegate: self, completion: { streamName, streamUrl, scheduledStartTime in
            if let name = streamName, let url = streamUrl, let startTime = scheduledStartTime {
                //            self.liveViewController.scheduledStartTime = scheduledStartTime as NSDate?
                print(name, url, startTime)
                completed(url, name)
            }
        })
    }
    
    func finishPublishing() {
        guard let broadcast = self.liveBroadcast else {
            self.dismissVideoStreamViewController()
            return
        }
        youTubeWorker.completeBroadcast(broadcast, completion: { success in
            self.dismissVideoStreamViewController()
        })
    }
    
    func cancelPublishing() {
        guard let broadcast = self.liveBroadcast else {
            self.dismissVideoStreamViewController()
            return
        }
        youTubeWorker.deleteBroadcast(id: broadcast.id, completion: { success in
            if success {
                print("Broadcast \"\(broadcast.id)\" was deleted!")
            } else {
                MessageBarService.shared.alert(message: "Sorry, system detected error while deleting the video. You can try to delete it in your YouTube account.")
            }
            self.dismissVideoStreamViewController()
        })
    }
}

// MARK: YTLiveStreamingDelegate protocol

extension Presenter: LiveStreamTransitioning {
    
    func didTransitionToLiveStatus() {
        //      self.liveViewController.showCurrentStatus(currStatus: "● LIVE")
        print("● LIVE")
        
        delegate?.didStartLive()
    }
    
    func didTransitionTo(broadcastStatus: String?, streamStatus: String?, healthStatus: String?) {
        if let broadcastStatus = broadcastStatus, let streamStatus = streamStatus, let healthStatus = healthStatus {
            let text = "status: \(broadcastStatus) [\(streamStatus);\(healthStatus)]"
            //         self.liveViewController.showCurrentStatus(currStatus: text)
            print(text)
        }
        delegate?.didChangedLiveStatus()
    }
}
