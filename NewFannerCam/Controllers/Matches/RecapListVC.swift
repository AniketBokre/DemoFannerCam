//
//  RecapListVC.swift
//  NewFannerCam
//
//  Created by iMac on 30/09/20.
//  Copyright © 2020 fannercam3. All rights reserved.
//

import UIKit

class RecapListVC: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var recapListTbl: UITableView!
    
    var arrRecap = [Recap]()
    var selectedMatch : SelectedMatch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.selectedMatch.match.namePresentation()
        
        getRecapList()
        
        // Do any additional setup after loading the view.
    }
    
    func getRecapList()
    {
        let strUrl: String = getServerBaseUrl() + getRecapListURL() + "\(customerId)"
        let postParam = [:] as [String : Any]
        let oWebManager: AlamofireManager = AlamofireManager()
        oWebManager.requestPost(strUrl, parameters: postParam) { (jsonResult) in
            if let error = jsonResult["error"] as? String
            {
                print(error)
                return
            }else{
                
                let entities = jsonResult["entities"] as! [NSDictionary]
                
                for objEntity in entities {
                    var objRecap = Recap()
                    objRecap.recapId = objEntity["recapId"] as? Int
                    objRecap.recapTitle = objEntity["recapTitle"] as? String
                    
                    self.arrRecap.append(objRecap)
                }
                
                self.getLiveRecapList()
                
            }
        }
    }
    
    func getLiveRecapList()
    {
        let strUrl: String = getServerBaseUrl() + getLiveRecapListURL() + "\(customerId)"
        let oWebManager: AlamofireManager = AlamofireManager()
        oWebManager.requestGet(strUrl) { (jsonResult) in
            if let error = jsonResult["error"] as? String
            {
                print(error)
                return
            }else{
                
                let entities = jsonResult["entities"] as! [NSDictionary]
                
                for objEntity in entities {
                    var objRecap = Recap()
                    objRecap.recapId = objEntity["recapId"] as? Int
                    objRecap.recapTitle = objEntity["recapTitle"] as? String
                    
                    self.arrRecap.append(objRecap)
                }
                
                self.recapListTbl.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrRecap.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecapListCell", for: indexPath) as! RecapListCell
        cell.recapClipLbl.text = arrRecap[indexPath.row].recapTitle
                
        let recapId = UserDefaults.standard.integer(forKey: selectedMatch.match.id)
        if arrRecap[indexPath.row].recapId == recapId
        {
            cell.accessoryType = .checkmark
            cell.tintColor = UIColor.white
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        

        let recapId = arrRecap[indexPath.row].recapId
        let match_id = self.selectedMatch.match.id
        
        UserDefaults.standard.setValue(recapId, forKey: match_id)
        UserDefaults.standard.synchronize()
        
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
        label.textAlignment = .center
        label.text = "Choose recap"
        label.textColor = UIColor.white
        view.addSubview(label)
        return view
    }
    
    @IBAction func onBackBtn(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }    
}
