//
//  AppDataManager.swift
//  NewFannerCam
//
//  Created by Jin on 1/16/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import StoreKit

enum Updater {
    case old
    case new
    case replace
    case delete
}

protocol DataManagerMatchesDelegate: class {
    func didUpdateMatches(_ updateMode: Updater, _ updatedItem: Match?, _ index: Int?)
}

protocol DataManagerMatchCountDelegate: class {
    func didUpdateMatchCount()
}

protocol DataManagerVideosDelegate: class {
    func didUpdateVideos(_ updateMode: Updater, _ updatedItem: Video?, _ index: Int?)
}

protocol DataManagerSettingsDelegate: class {
    func didUpdateaMarker(_ updateMode: Updater, _ updatedItem: Marker, _ index: Int)
}

protocol DataManagerUserInfoDelegate: class {
    func didUpdateUserInfo( _ updater: Updater)
}

final class DataManager {

//MARK: - Properties
    static let shared                   = DataManager()
    
    weak var matchesDelegate            : DataManagerMatchesDelegate?
    weak var matchCountDelegate         : DataManagerMatchCountDelegate?
    weak var videosDelegate             : DataManagerVideosDelegate?
    weak var settingsDelegate           : DataManagerSettingsDelegate?
    weak var userInfoDelegate           : DataManagerUserInfoDelegate?
    
    private let localStorageManager     = UserStandardManager()
    
    var matches                         = [Match]()
    var videos                          = [Video]()
    var overlays                        = [String: ImgArchive]()
    var settingsMarkers                 = [String: [Marker]]()
    var imgArchives                     = [ImgArchive]()
    var imgArchives2                     = [ImgArchive]()
    var templates                       = [String: [Template]]()
    var soundtracks                     = [String: [Soundtrack]]()
    var purchasedMatchCount             : Int = 0
    
    // products
    var soundtrackProducts              = [SKProduct]()
    var templateProducts                = [SKProduct]()
    var matchProducts                   = [SKProduct]()
    
    //other data
    let clipSliderHandleImage           : UIImage!
    var tabberView                      : UIView!
    
//MARK: - Main functions
    func updateMatches(_ match: Match, _ index: Int, _ updater: Updater, _ isAbleToDelegate: Bool = true) {
        switch updater {
        case .new:
            matches.append(match)
        case .replace:
            matches[index] = match
        case .delete:
            dirManager.deleteItems(at: match.matchPath())
            matches.remove(at: index)
        default:
            break
        }
        
        matches.sort { $0.id > $1.id }
        localStorageManager.saveObject(matches, .matches)
        if isAbleToDelegate {
            matchesDelegate?.didUpdateMatches(updater, match, index)
        }
    }
    
    func updateScoreboardHidden(_ val: Bool) {
        localStorageManager.saveObject(val, .scoreboardHidden)
    }
    
    func updateOverlays(_ overlay: ImgArchive, _ key: String, _ updater: Updater) {
        switch updater {
        case .new, .replace:
            overlays[key] = overlay
        case .delete:
            dirManager.deleteItems(at: overlay.filePath())
            overlays.removeValue(forKey: key)
        default:
            break
        }
        
        localStorageManager.saveObject(overlays, .overlays)
    }
    
    func getOverlay(of mode: Overlays) -> ImgArchive? {
        return overlays[mode.rawValue]
    }
    
    func updateVideos(_ video: Video, _ updater: Updater, _ replaceVideo: Video? = nil) {
        let index = videos.firstIndex { $0.fileName == video.fileName } ?? videos.count - 1
        switch updater {
        case .new:
            videos.append(video)
        case .replace:
            if let replaceItem = replaceVideo {
                videos[index] = replaceItem
                dirManager.deleteItems(at: video.filePath())
            } else {
                videos[index] = video
            }
        case .delete:
            dirManager.deleteItems(at: video.filePath())
            videos.remove(at: index)
        default:
            break
        }
        
        videos.sort { $0.fileName > $1.fileName }
        localStorageManager.saveObject(videos, .videos)
        videosDelegate?.didUpdateVideos(updater, video, index)
    }
    
    func updateSettingMarkers(_ marker: Marker, _ index: Int, _ updater: Updater) {
        var markers = settingsMarkers[marker.type.rawValue] ?? [Marker]()
        
        switch updater {
        case .new:
            markers.append(marker)
        case .replace:
            markers[index] = marker
        case .delete:
            markers.remove(at: index)
            break
        default:
            break
        }
        settingsMarkers[marker.type.rawValue] = markers
        localStorageManager.saveObject(settingsMarkers, .settingMarkers)
        settingsDelegate?.didUpdateaMarker(updater, marker, index)
    }
    
    func updateImgArchives(_ media: ImgArchive, _ index: Int, _ updater: Updater, _ allForDelete: Bool = false) {
        switch updater {
        case .new:
            imgArchives.append(media)
        case .replace:
            imgArchives[index] = media
        case .delete:
            if allForDelete {
                imgArchives.forEach { (img) in
                    dirManager.deleteItems(at: img.filePath())
                }
                imgArchives.removeAll()
            } else {
                dirManager.deleteItems(at: imgArchives[index].filePath())
                imgArchives.remove(at: index)
            }
            break
        default:
            break
        }

        localStorageManager.saveObject(imgArchives, .imgArchive)
    }
    
    func updateImgArchives2(_ media: ImgArchive, _ index: Int, _ updater: Updater, _ allForDelete: Bool = false) {
        switch updater {
        case .new:
            imgArchives2.append(media)
        case .replace:
            imgArchives2[index] = media
        case .delete:
            if allForDelete {
                imgArchives2.forEach { (img) in
                    dirManager.deleteItems(at: img.filePath())
                }
                imgArchives2.removeAll()
            } else {
                dirManager.deleteItems(at: imgArchives2[index].filePath())
                imgArchives2.remove(at: index)
            }
            break
        default:
            break
        }

        localStorageManager.saveObject(imgArchives2, .imgArchive2)
    }
    
    // Template functions
    func saveTemplates() {
        localStorageManager.saveObject(templates, .templates)
    }
    
    func setTemplates(_ items: [Template], _ groups: [String]) -> Bool {
        var lastTemplates = [Template]()
        for (_ , value) in templates {
            lastTemplates.append(contentsOf: value)
        }
        for (index, _) in lastTemplates.enumerated() {
            lastTemplates[index].removeFiles()
        }
        
        let newTemplateArray = items
        var result = [String: [Template]]()
      /*  for groupName in groups {
            let groupItems = newTemplateArray.filter { $0.iapGroupName == groupName }.sorted { $0.order < $1.order }
            result[groupName] = groupItems
        } */
        for groupName in groups {
           var groupItems = newTemplateArray.filter { $0.iapGroupName == groupName }.sorted { $0.order < $1.order }
        
           lastTemplates.forEach { (templates) in
             for (index,template) in groupItems.enumerated() {
               if template.id == templates.id && template.iapGroupName == templates.iapGroupName{
                   var temp = template
                   temp.purchasedType = templates.purchasedType
                   groupItems[index] = temp
              }
             }
           }
           result[groupName] = groupItems
        }
        let freeItems = newTemplateArray.filter { $0.iapGroupName == FreeKey }
        result[FreeKey] = freeItems
        templates = result
        localStorageManager.saveObject(templates, .templates)
        
        let selectedTemplates = newTemplateArray.filter { $0.isSelected && $0.isDownloaded }
        if selectedTemplates.count > 0 {
            return false                // no needed to download free item
        } else {
            return true                 // should download free item because no selected item means refresh items as the first time.
        }
    }
    
    func selectTemplate(_ item: Template, _ selectedIndex: Int) {
        for (key, value) in templates {
            var groupItems = value
            var isChanged = false
            for (index, item) in groupItems.enumerated() {
                if item.isSelected {
                    var lastSelectedItem = item
                    lastSelectedItem.isSelected = false
                    groupItems[index] = lastSelectedItem
                    isChanged = true
                    break
                }
            }
            if isChanged {
                templates[key] = groupItems
                break
            }
        }
        var groupItems = templates[item.iapGroupName] ?? [Template]()
        var temp = item
        temp.isSelected = true
        groupItems[selectedIndex] = temp
        templates[item.iapGroupName] = groupItems
        localStorageManager.saveObject(templates, .templates)
    }
    
    func getTemplateKeys() -> [String] {
        var oriKeys = Array(self.templates.keys).sorted()
        oriKeys.removeAll { (val) -> Bool in
            val == FreeKey
        }
        oriKeys.insert(FreeKey, at: 0)
        return oriKeys
    }
    
    func getTemplateFreeItem() -> (item: Template, index: Int)
    {
        print("Template=",self.templates)
        if(self.templates[FreeKey]!.count > 0){
            return (item: self.templates[FreeKey]![0], index: 0)
        }else{
            return (item: Template(), index: 0)
        }
    }
    
    func getSelectedTemplate() -> Template? {
        for (_ , value) in templates {
            let groupItems = value
            for (_ , item) in groupItems.enumerated() {
                if item.isSelected {
                    return item
                }
            }
        }
        
        return nil
    }
    
    // soundtrack functions
    func saveSoundtrack() {
        localStorageManager.saveObject(soundtracks, .soundtracks)
    }
    
    func setSoundtracks(_ items: [Soundtrack], _ groups: [String]) -> Bool {
        var lastSoundtracks = [Soundtrack]()
        for (_ , value) in soundtracks {
            lastSoundtracks.append(contentsOf: value)
        }
        let downloadedItems = lastSoundtracks.filter { $0.isDownloaded }
        for item in downloadedItems {
            var temp = item
            temp.removeFiles()
        }
        
        var result = [String: [Soundtrack]]()
        
       /* for groupName in groups {
            let groupItems = items.filter { $0.iapGroupName == groupName }.sorted { $0.order < $1.order }
            result[groupName] = groupItems
        } */
        for groupName in groups {
            var groupItems = items.filter { $0.iapGroupName == groupName }.sorted { $0.order < $1.order }
         
            lastSoundtracks.forEach { (soundtrack) in
              for (index,sound) in groupItems.enumerated() {
                if sound.id == soundtrack.id && sound.iapGroupName == soundtrack.iapGroupName {
                    var temp = sound
                    temp.purchasedType = soundtrack.purchasedType
                    groupItems[index] = temp
               }
              }
            }
            result[groupName] = groupItems
        }
        let freeItems = items.filter { $0.iapGroupName == FreeKey }
        result[FreeKey] = freeItems
        soundtracks = result
        localStorageManager.saveObject(soundtracks, .soundtracks)
        
        let selectedSoundtracks = items.filter { $0.isSelected && $0.isDownloaded }
        if selectedSoundtracks.count > 0 {
            return false                // no needed to download free item
        } else {
            return true                 // should download free item because no selected item means refresh items as the first time.
        }
    }
    
    func selectSoundtrack(_ item: Soundtrack, _ selectedIndex: Int) {
        if item.isSelected {
            for (key, value) in soundtracks {
                var groupItems = value
                var isChanged = false
                for (index, item) in groupItems.enumerated() {
                    if item.isSelected {
                        var lastSelectedItem = item
                        lastSelectedItem.isSelected = false
                        groupItems[index] = lastSelectedItem
                        isChanged = true
                        break
                    }
                }
                if isChanged {
                    soundtracks[key] = groupItems
                    break
                }
            }
        }
        
        var groupItems = soundtracks[item.iapGroupName] ?? [Soundtrack]()
        groupItems[selectedIndex] = item
        soundtracks[item.iapGroupName] = groupItems
        localStorageManager.saveObject(soundtracks, .soundtracks)
    }
    
    func getSoundtrackKeys() -> [String] {
        var oriKeys = Array(self.soundtracks.keys).sorted()
        oriKeys.removeAll { (val) -> Bool in
            val == FreeKey
        }
        oriKeys.insert(FreeKey, at: 0)
        return oriKeys
    }
    
    func getSoundTrackFreeItem() -> (item: Soundtrack, index: Int)
    {
        print("Template=",soundtracks)
        if(soundtracks[FreeKey]!.count > 0){
            return (item: soundtracks[FreeKey]![0], index: 0)
        }else{
            return (item: Soundtrack(), index: 0)
        }
    }
    
    func getSelectedSoundtrack() -> Soundtrack? {
        for (_ , value) in self.soundtracks {
            let groupItems = value
            for (_ , item) in groupItems.enumerated() {
                if item.isSelected {
                    return item
                }
            }
        }
        
        return nil
    }
    
    // purchased match count functions
    func updatePurchasedMatchCount(_ purchasedCount: Int) {
        purchasedMatchCount += purchasedCount
        localStorageManager.saveObject(purchasedMatchCount, .purchasedMatchCount)
        matchCountDelegate?.didUpdateMatchCount()
    }
    
//MARK: - Init functions
    init() {
        clipSliderHandleImage = ImageProcess.image(solidColor: .yellow, size: CGSize(width: 8, height: 50))
    }
    
    func setData() {
        getPurchasedMatchCount()
        getMatches()
        getOverlays()
        getVideos()
        getSettingMarkers()
        getImgArchive()
        getImgArchive2()
        getTemplates()
        getSoundtracks()
    }
    
    func getPurchasedMatchCount() {
        if let data = localStorageManager.loadObject(type: .purchasedMatchCount) {
            purchasedMatchCount = data as! Int
            if purchasedMatchCount < 0 {
                purchasedMatchCount = 0
            }
        } else {
            purchasedMatchCount = 0
        }
        matchCountDelegate?.didUpdateMatchCount()
    }
    
    func getMatches() {
        if let data = localStorageManager.loadObject(type: .matches) {
            do {
                matches = try JSONDecoder().decode([Match].self, from: data as! Data)
            } catch {
                matches = [Match]()
                print(error)
            }
        } else {
            matches = [Match]()
        }
        matchesDelegate?.didUpdateMatches(.old, nil, nil)
    }
    
    func getOverlays() {
        if let data = localStorageManager.loadObject(type: .overlays) {
            do {
                overlays = try JSONDecoder().decode([String: ImgArchive].self, from: data as! Data)
            } catch {
                overlays = [String: ImgArchive]()
                print(error)
            }
        } else {
            overlays = [String: ImgArchive]()
        }
    }
    
    func getScoreboardHidden() -> Bool {
        if let data = localStorageManager.loadObject(type: .scoreboardHidden) {
            print(data as! Bool)
            return data as! Bool
        } else {
            return false
        }
    }
    
    func getVideos() {
        if let data = localStorageManager.loadObject(type: .videos) {
            do {
                videos = try JSONDecoder().decode([Video].self, from: data as! Data)
            } catch {
                videos = [Video]()
                print(error)
            }
        } else {
            videos = [Video]()
        }
        videosDelegate?.didUpdateVideos(.old, nil, nil)
    }
    
    func getSettingMarkers() {
        func setSettingMarkers() {
            settingsMarkers = [
                MarkerType.individual.rawValue : [
                    Marker("1", "PALLA PERSA", .individual, 10),
                    Marker("2", "PALLA RECUPERATA", .individual, 10),
                    Marker("4", "FALLO", .individual, 10),
                    Marker("8", "SCHIACCIATA", .individual, 10)
                ],
                MarkerType.collective.rawValue : [
                    Marker("0", "GOAL", .collective, 12),
                    Marker("9", "TIRO", .collective, 10),
                    Marker("10", "PARATA", .collective, 10),
                    Marker("11", "CANESTRO", .collective, 10),
                    Marker("12", "CANESTRO DA 3", .collective, 10),
                    Marker("13", "TIRO LIBERO", .collective, 10),
                    Marker("14", "INGRESSO", .collective, 10),
                    Marker("14", "FINE GARA", .collective, 10),
                ],
                MarkerType.generic.rawValue : [
                    Marker("15", "GENERICO", .generic, 10),
                ]
            ]
            
            localStorageManager.saveObject(settingsMarkers as Any, .settingMarkers)
        }
        
        if let data = localStorageManager.loadObject(type: .settingMarkers) {
            do {
                settingsMarkers = try JSONDecoder().decode([String: [Marker]].self, from: data as! Data)
            } catch {
                setSettingMarkers()
                print(error)
            }
        } else {
            setSettingMarkers()
        }
    }
    
    func getImgArchive() {
        if let data = localStorageManager.loadObject(type: .imgArchive) {
            do {
                imgArchives = try JSONDecoder().decode([ImgArchive].self, from: data as! Data)
            } catch {
                print(error)
            }
        }
    }
    
    func getImgArchive2() {
        if let data = localStorageManager.loadObject(type: .imgArchive2) {
            do {
                imgArchives2 = try JSONDecoder().decode([ImgArchive].self, from: data as! Data)
            } catch {
                print(error)
            }
        }
    }
    
    func getTemplates() {
        if let data = localStorageManager.loadObject(type: .templates) {
            do {
                templates = try JSONDecoder().decode([String: [Template]].self, from: data as! Data)
            } catch {
                print(error)
            }
        }
    }
    
    func getSoundtracks() {
        if let data = localStorageManager.loadObject(type: .soundtracks) {
            do {
                soundtracks = try JSONDecoder().decode([String: [Soundtrack]].self, from: data as! Data)
            } catch {
                print(error)
            }
        }
    }
    
    // Image Cache
    var imageCache       = NSCache<AnyObject, AnyObject>()
    
    func getImageCache(forKey: String) -> UIImage? {
        let image = imageCache.object(forKey: forKey as AnyObject) as? UIImage
        return image
    }
    
    func set(cache image: UIImage, for key: String) {
        imageCache.setObject(image as AnyObject, forKey: key as AnyObject)
    }
    
    func setProductGroupData(productGroup:[String:NSDictionary]) {
        let groupData = NSKeyedArchiver.archivedData(withRootObject: productGroup)
        localStorageManager.saveObject(groupData, .productGroupData)
    }
    
    func getProductGroupData()->[String:NSDictionary]? {
        let groupData = localStorageManager.loadObject(type: .productGroupData)
        let productGroup = NSKeyedUnarchiver.unarchiveObject(with: groupData as! Data) as? [String: NSDictionary]
        return productGroup
    }
}
