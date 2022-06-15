//
//  SettingsTemTraVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/30/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//
import UIKit
import AVFoundation
import MediaPlayer
import AudioToolbox
import AVKit
import StoreKit

enum SettingsTemTraVCMode: String {
    case soundTracks                    = "Soundtracks"
    case templates                      = "Templates"
    
    var mediaType                       : MediaType {
        switch self {
        case .soundTracks:
            return MediaType.sounds
        case .templates:
            return MediaType.templates
        }
    }
    
    var urlStr                          : String {
        switch self {
        case .soundTracks:
            return SOUNDTRACK_JSON
        case .templates:
            return TEMPLATE_JSON
        }
    }
}

private let cellId = "SettingsTemTraCell"

class SettingsTemTraVC: UITableViewController, StorePurchaseDelegate {

    // preview play for the soundtracks and templates
    private var audioPlayer             : AVAudioPlayer!
    private var avPlayer                : AVPlayer!
    private var playingSoundIndex       : IndexPath!
    
    // access properties should be initialized before calling viewDidLoad()
    var viewMode                        = SettingsTemTraVCMode.soundTracks
    var inSettingTab = true
    
    var isProductRestored : Bool = false
    var isDownloaded : Bool = false
    
    // using properties should be initialized in viewDidLoad() function
    var products: [SKProduct] = []
    
//MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = viewMode.rawValue
        isProductRestored = true
        isDownloaded = true
        
        initData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification(_:)), name: .IAPServicePurchaseNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterSettingTab(_:)), name: .DidEnterSettingTab, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if avPlayer != nil {
            avPlayer.pause()
        }
    }
    
//MARK: - Initial functions
    func initData() {
        var shouldReload = false
        if self.viewMode == .soundTracks, DataManager.shared.soundtracks.keys.count == 0 {
            shouldReload = true
            isProductRestored = false
        }
        if self.viewMode == .templates, DataManager.shared.templates.keys.count == 0 {
            shouldReload = true
            isProductRestored = false
        }
        if shouldReload {
            onRefreshBtn(UIButton())
        } else {
            let loadingView = inSettingTab ? DataManager.shared.tabberView : self.parent?.view
            Utiles.setHUD(true, loadingView!, .extraLight, "")
            reloadProducts { (success) in
                if success {
                    DispatchQueue.main.async { self.tableView.reloadData()  }
                } else {
                    MessageBarService.shared.error("No available in-app purchase currently!")
                }
                self.isProductRestored = false
                Utiles.setHUD(false)
            }
        }
    }
    
    func reloadProducts(onRefreshing: Bool = false, _ completion: @escaping (Bool) -> Void) {
        
        func productLoadComplete(success:Bool){
            if onRefreshing {
                completion(success)
             }else{
                refreshProductSubscription { (isSubscriptionRefresh) in
                    completion(success)
                }
            }
        }
        
        func loadProducts() {
            if viewMode == .soundTracks {
                FannerCamProducts.soundtrackStore.requestProducts{ [weak self] success, products in //
                    guard let self = self else { return }
                    
                    if success {
                        self.products = products ?? []
                        self.products.sort { $0.localizedTitle < $1.localizedTitle }
                        DataManager.shared.soundtrackProducts = self.products
                    }
                    productLoadComplete(success: success)
                }
            } else {
                FannerCamProducts.templatesStore.requestProducts{ [weak self] success, products in //
                    guard let self = self else { return }
                    
                    if success {
                        self.products = products ?? []
                        self.products.sort { $0.localizedTitle < $1.localizedTitle }
                        DataManager.shared.templateProducts = self.products
                    }
                    productLoadComplete(success: success)
                }
            }
        }
        
        if onRefreshing {
            loadProducts()
        } else {
            if viewMode == .soundTracks {
                if DataManager.shared.soundtrackProducts.count > 0 {
                    products = DataManager.shared.soundtrackProducts
                } else {
                    loadProducts(); return
                }
            } else {
                if DataManager.shared.templateProducts.count > 0 {
                    products = DataManager.shared.templateProducts
                } else {
                    loadProducts(); return
                }
            }
            refreshProductSubscription { (success) in
                completion(true)
            }
        }
    }
    
//MARK: - @objc functions
    @objc func didEnterSettingTab(_ notification: Notification) {
        tableView.reloadData()
    }
    
    @objc func handlePurchaseNotification(_ notification: Notification) {
        let productID = notification.object as? String
        transactionCompleted(productID: productID)
    }
    
    func transactionCompleted(productID:String?){
        guard (productID != nil),
        let index = products.firstIndex(where: { product -> Bool in
            product.productIdentifier == productID
        })
        else { return }
        
        let groupName = products[index].localizedTitle
        //        MessageBarService.shared.notify("Successfully purchased \(groupName)")
        
        if viewMode == .soundTracks {
            var purchasedItems = DataManager.shared.soundtracks[groupName] ?? [Soundtrack]()
            let purchaseType : Purchased = FannerCamProducts.soundtrackStore.isProductPurchased(productID!) ? .purchased : .unPurchased
            for (index, item) in purchasedItems.enumerated() {
                var temp = item
                temp.purchasedType = purchaseType
                if purchaseType == .unPurchased{
                    temp.removeFiles()
                }
                purchasedItems[index] = temp
            }
            DataManager.shared.soundtracks[groupName] = purchasedItems
            DataManager.shared.saveSoundtrack()
        } else {
            var purchasedItems = DataManager.shared.templates[groupName] ?? [Template]()
            let purchaseType : Purchased = FannerCamProducts.templatesStore.isProductPurchased(productID!) ? .purchased : .unPurchased
            for (index, item) in purchasedItems.enumerated() {
                var temp = item
                temp.purchasedType = purchaseType
                if purchaseType == .unPurchased{
                    temp.removeFiles()
                }
                purchasedItems[index] = temp
            }
            DataManager.shared.templates[groupName] = purchasedItems
            DataManager.shared.saveTemplates()
        }
        
        DispatchQueue.main.async { self.tableView.reloadData()  }
        if self.isDownloaded {
            Utiles.setHUD(false)
        }
    }
    
    func refreshProductSubscription(isRefreshReceipt: Bool = false,_ completion: @escaping (Bool) -> Void){
        
        func updateproducts(productIDs:[String]?){
            guard productIDs == nil else{
                for productId in productIDs!{
                    self.transactionCompleted(productID: productId)
                }
                return
            }
        }
        
        if self.viewMode == .soundTracks {
            if isRefreshReceipt {
                FannerCamProducts.soundtrackStore.restorePurchases { (isRefresh, productIds) in
                    updateproducts(productIDs: productIds)
                    completion(isRefresh)
                }
            }else{
                FannerCamProducts.soundtrackStore.checkIAPPurchaseStatus { (success, error, productIds) in
                    updateproducts(productIDs: productIds)
                    completion(success)
                }
            }
        }
        else if self.viewMode == .templates {
            if isRefreshReceipt {
                FannerCamProducts.templatesStore.restorePurchases { (isRefresh, productIds) in
                    updateproducts(productIDs: productIds)
                    completion(isRefresh)
                }
            }else{
                FannerCamProducts.templatesStore.checkIAPPurchaseStatus { (success, error, productIds) in
                    updateproducts(productIDs: productIds)
                    completion(success)
                }
            }
        }
    }
    
    func startedPurchasing() {
        let loadingView = inSettingTab ? DataManager.shared.tabberView : self.parent?.view
        Utiles.setHUD(true, loadingView!, .extraLight, "")
    }
    
    func purchasePuroduct(pendingProduct: SKProduct!) {
        if self.viewMode == .soundTracks {
            FannerCamProducts.soundtrackStore.buyProduct(pendingProduct)
            self.startedPurchasing()
        } else {
            FannerCamProducts.templatesStore.buyProduct(pendingProduct)
            self.startedPurchasing()
        }
    }
    
//MARK: - Main functions
    func updateTable(_ index: IndexPath) {
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [index], with: .fade)
        self.tableView.endUpdates()
    }
    
    func downloadSelectedItem(item: Any, index: Int) {
        DispatchQueue.main.async {
            self.isDownloaded = false
            if Utiles.HUDDisplayed() {
                Utiles.setHUD("Downloading media files...")
            } else {
                let loadingView = self.inSettingTab ? DataManager.shared.tabberView : self.parent?.view
                Utiles.setHUD(true, loadingView!, .extraLight, "Downloading media files...")
            }
        }
        
        func endProcessing() {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            Utiles.setHUD(false)
            isDownloaded = true
        }
        
        if var soundtrack = item as? Soundtrack, !soundtrack.isDownloaded {
//            soundtrack.saveFiles()
            soundtrack.saveFiles { (success, resultDes) in
                if success {
                    var temp = soundtrack
                    temp.set(isDownloaded: true)
                    DataManager.shared.selectSoundtrack(temp, index)
                } else {
                    MessageBarService.shared.error("It doesn't download selected media file, please check your internet connection and try later!")
                }
                endProcessing()
            }
        }
        if var template = item as? Template, !template.isDownloaded {
//            template.saveFiles()
            template.saveFiles { (success, resultDes) in
                if success {
                    var temp = template
                    temp.isDownloaded = true
                    DataManager.shared.selectTemplate(temp, index)
                } else {
                    MessageBarService.shared.error("It doesn't download selected media file, please check your internet connection and try later!")
                }
                endProcessing()
            }
        }
    }
    
    func cancelSubscription() {
        
        MessageBarService.shared.alertQuestion(title: APP_NAME, message: "Are you sure want to cancel this subscription?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
            
            self.products = []
            if self.viewMode == .soundTracks {
                let _ = DataManager.shared.setSoundtracks([], [])
            } else {
                let _ = DataManager.shared.setTemplates([], [])
            }
            
            self.tableView.reloadData()
            
            UIApplication.shared.open(URL(string: "https://sandbox.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions")!, options: [:]) { (success) in
                //
            }
            
        }, onNo: nil)
    }

//MARK: - IBAction functions
    @IBAction func onRefreshBtn(_ sender: UIButton) {
        if(isProductRestored){ return }
        let loadingView = inSettingTab ? DataManager.shared.tabberView : self.parent?.view
        Utiles.setHUD(true, loadingView!, .extraLight, "Loading \(viewMode.rawValue) List...")
        
        DispatchQueue.global().async {
            self.isProductRestored = true
                self.reloadProducts(onRefreshing: true) { (success) in
                    if success {
                        Downloader.loadTemplateMeidas(from: self.viewMode.urlStr, at: self.viewMode) { (isSucceed, resultValue, resultDes) in
                            if isSucceed {
                                let groupNames = self.products.map { $0.localizedTitle }
                                if self.viewMode == .soundTracks {
                                    let isFirstTime = DataManager.shared.setSoundtracks(resultValue as! [Soundtrack], groupNames)
                                    if isFirstTime {
                                        if DataManager.shared.soundtracks[FreeKey]!.count > 0 {
                                            let (soundtrack, index) = DataManager.shared.getSoundTrackFreeItem()
                                            var temp = soundtrack 
                                            temp.isSelected = true
                                            self.downloadSelectedItem(item: temp as Any, index: index)
                                        }
                                    }
                                } else {
                                    let isFirstTIme = DataManager.shared.setTemplates(resultValue as! [Template], groupNames)
                                    if isFirstTIme {
                                        if DataManager.shared.templates[FreeKey]!.count > 0 {
                                            let (template, index) = DataManager.shared.getTemplateFreeItem()
                                            self.downloadSelectedItem(item: template as Any, index: index)
                                        }
                                    }
                                }
                                self.refreshProductSubscription(isRefreshReceipt: true, { (isSubscriptionRefresh) in
                                    self.isProductRestored = false
                                })
                            } else {
                                MessageBarService.shared.warning(resultDes)
                            }
                            DispatchQueue.main.async { self.tableView.reloadData()  }
                           // Utiles.setHUD(false)
                        }
                    } else {
                        MessageBarService.shared.error("No available purchase items.")
                        Utiles.setHUD(false)
                    }
                }
        }
    }
    
    @IBAction func onBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }

// MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if products.count == 0 {
            return 0
        }
        
        if viewMode == .soundTracks {
            return DataManager.shared.soundtracks.keys.count
        } else {
            return DataManager.shared.templates.keys.count
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if products.count == 0 {
            return 0
        }
        
        if viewMode == .soundTracks {
            let keys = DataManager.shared.getSoundtrackKeys()
            let groupItems = DataManager.shared.soundtracks[keys[section]]!
            return groupItems.count
        } else {
            let keys = DataManager.shared.getTemplateKeys()
            let groupItems = DataManager.shared.templates[keys[section]]!
            return groupItems.count
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section != 0 {
            
            let header = tableView.dequeueReusableCell(withIdentifier: "SettingsTemTraHeaderCell") as! SettingTemSouHeaderCell
            
            header.viewMode = viewMode
            header.product = products[section - 1]
            header.purchaseHandler = { product in
                let storePurchaseNav = self.settingsStorePurchaseNav()
                let vc = storePurchaseNav.children[0] as! StorePurchaseVC
                vc.pendingProduct = product
                vc.inSettingTab = false
                vc.delegate = self
                self.present(storePurchaseNav, animated: true, completion: nil)
            }
            
            return header
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 110
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! TemplateMediaCell
        
        var isPlaying = false
        if playingSoundIndex != nil, playingSoundIndex.row == indexPath.row, playingSoundIndex.section == indexPath.section {
            isPlaying = true
        }
        
        if viewMode == .soundTracks {
            let keys = DataManager.shared.getSoundtrackKeys()
            let groupItems = DataManager.shared.soundtracks[keys[indexPath.section]]!
            cell.initialzie(self, groupItems[indexPath.row], self.viewMode, isPlaying)
        } else {
            let keys = DataManager.shared.getTemplateKeys()
            let groupItems = DataManager.shared.templates[keys[indexPath.section]]!
            cell.initialzie(self, groupItems[indexPath.row], self.viewMode)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return 50
        } else {
            return 60
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == products.count {
            return 100
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == products.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MatchTemplateMediaFooterCell")
            let label = cell?.viewWithTag(1000) as! UILabel
            let str = viewMode == .soundTracks ? "soundtracks" : "video templates"
            label.text = "Before buying remember that you can use the \(str) only if you have at least one match purchased."
            return cell
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

//MARK: - TemplateMediaCellDelegate
extension SettingsTemTraVC: TemplateMediaCellDelegate {
    
    func templateMediaCell(_ cell: TemplateMediaCell, didClickCheck btn: UIButton, item: Any) {
        
        let indexPath = self.tableView.indexPath(for: cell)!
        DispatchQueue.global().async {
            if self.viewMode == .soundTracks {
                let data = item as! Soundtrack
                if data.isSelected, !data.isDownloaded {
                    self.downloadSelectedItem(item: data, index: indexPath.row)
                } else {
                    DataManager.shared.selectSoundtrack(data, indexPath.row)
                }
            } else {
                let data = item as! Template
                if data.isSelected, !data.isDownloaded {
                    self.downloadSelectedItem(item: data, index: indexPath.row)
                } else {
                    DataManager.shared.selectTemplate(data, indexPath.row)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func templateMediaCell(_ cell: TemplateMediaCell, didClickPlay item: Any, _ isPlay: Bool) {
        let index = tableView.indexPath(for: cell)!
        if let soundtrack = item as? Soundtrack {
            if avPlayer != nil {
                play(url: soundtrack.filePath(), isPlay: false, index: index)
            }
            let url = soundtrack.isDownloaded ? soundtrack.filePath() : URL(string: soundtrack.audioUrl)!
            play(url: url, isPlay: isPlay, index: index)
        }
        
        if let template = item as? Template {
            let url = template.isDownloaded ? template.filePath(of: .introExample) : URL(string: template.introExample)!
            let player = AVPlayer(url: url)
            let playervc = AVPlayerViewController()
            playervc.player = player
            self.present(playervc, animated: true) {
                playervc.player!.play()
            }
        }
    }
}

//MARK: - Soundtrack and Template preview play
extension SettingsTemTraVC {
    func play(url: URL, isPlay: Bool, index: IndexPath) {
        if isPlay {
            let item = AVPlayerItem(url: url)
            avPlayer = AVPlayer(playerItem: item)
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem, queue: .main) { _ in
                self.playingSoundIndex = nil
                self.tableView.reloadData()
            }
            avPlayer.play()
            playingSoundIndex = index
        } else {
            avPlayer.pause()
            playingSoundIndex = nil
        }
        tableView.reloadData()
    }
}
