//
//  SettingsLoginLiverecapVC.swift
//  NewFannerCam
//
//  Created by Jin on 21/09/20.
//  Copyright © 2020 fannercam3. All rights reserved.
//

import UIKit

class SettingsLoginLiverecapVC: UIViewController {
    
    
    @IBOutlet weak var userNameTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Test account
//        userNameTF.text = "Test1Test2";
//        passwordTF.text = "Test1Test2";
        userNameTF.text = "";
        passwordTF.text = "";
    }
    
    @IBAction func onBackBtn(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onLoginBtn(_ sender: Any) {
        
        Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Signing...")

        let strUrl: String = getServerBaseUrl()+getLoginURL()
        let postParam = [
            "account": userNameTF.text ?? "",
            "password": passwordTF.text ?? "",
            "local": "IT"
            ] as [String : Any]
        let oWebManager: AlamofireManager = AlamofireManager()
        oWebManager.requestPost(strUrl, parameters: postParam) { (jsonResult) in
            
            Utiles.setHUD(false)
            
            if let error = jsonResult["error"] as? String
            {
                let alert = UIAlertController(title: "Alert", message: error, preferredStyle: UIAlertController.Style.alert)
                
                let okButtonAction = UIAlertAction(title: "Ok", style: .default) { (okButtonAction) in
                }
                alert.addAction(okButtonAction)
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            else if let errorMessage = jsonResult["ss"] as? NSDictionary
            {
                if let errorMessage = errorMessage["errorMessage"] as? String
                {
                    if !errorMessage.isEmpty
                    {
                        let alert = UIAlertController(title: "Alert", message: errorMessage, preferredStyle: UIAlertController.Style.alert)
                        
                        let okButtonAction = UIAlertAction(title: "Ok", style: .default) { (okButtonAction) in
                        }
                        alert.addAction(okButtonAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    else {
                        if (jsonResult["roleId"] as? Int ?? 0) == 5
                        {
                            let alert = UIAlertController(title: "Alert", message: "You are a base user, so you are not able to upload video. Please ask for upgrade at info@fanner.it", preferredStyle: UIAlertController.Style.alert)
                            
                            let okButtonAction = UIAlertAction(title: "Ok", style: .default) { (okButtonAction) in
                            }
                            alert.addAction(okButtonAction)
                            self.present(alert, animated: true, completion: nil)
                            return
                        }
                        else
                        {
                            userName = self.userNameTF.text ?? ""
                            password = self.passwordTF.text ?? ""
                            tokenId = jsonResult["token"] as? String ?? ""
                            name = jsonResult["name"] as? String ?? ""
                            lastName = jsonResult["lastName"] as? String ?? ""
                            customerId = jsonResult["customerId"] as? Int ?? 0
                            roleId = jsonResult["roleId"] as? Int ?? 0
                            
                            self.navigationController?.popViewController(animated: true)
                        }
                        return
                    }
                }
            }
            else {
                userName = self.userNameTF.text ?? ""
                password = self.passwordTF.text ?? ""
                tokenId = jsonResult["token"] as? String ?? ""
                name = jsonResult["name"] as? String ?? ""
                lastName = jsonResult["lastName"] as? String ?? ""
                customerId = jsonResult["customerId"] as? Int ?? 0
                roleId = jsonResult["roleId"] as? Int ?? 0
                
                self.navigationController?.popViewController(animated: true)
            }
        }
        
    }
    func convertToDictionary(from text: String) -> [String: String] {
        guard let data = text.data(using: .utf8) else { return [:] }
        let anyResult: Any? = try? JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: String] ?? [:]
    }
    
    // TODO: For backup
//    @IBAction func onForgotPasswordBtn(_ sender: Any) {
//
//    }
//
//    @IBAction func onFaceBookBtn(_ sender: Any) {
//
//
//
//        let loginManager = LoginManager()
//        let permission=["public_profile" , "email"]
//        loginManager.logIn(permissions: permission, from: self) { [weak self] (result, error) in
//
//            guard error == nil else {
//                // Error occurred
//                print(error!.localizedDescription)
//                return
//            }
//            guard let result = result, !result.isCancelled else {
//                print("User cancelled login")
//                return
//            }
//
//            Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Signing...")
//
//            Profile.loadCurrentProfile { (profile, error) in
//
//                let req = GraphRequest(graphPath: "me", parameters: ["fields":"first_name, last_name, email"], tokenString: AccessToken.current?.tokenString, version: nil, httpMethod: .get)
//                req.start { (connection, result, error) in
//                    if(error == nil) {
//
//                        if (((result as? NSDictionary)?["email"]) == nil)
//                        {
//                            let alert = UIAlertController(title: "Alert", message: "No email found with this Facebook account, please try with different Facebook account.", preferredStyle: UIAlertController.Style.alert)
//                            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
//                            self?.present(alert, animated: true, completion: nil)
//                            Utiles.setHUD(false)
//                            return;
//                        }
//
//                        let strUrl: String = getServerBaseUrl() + getLoginURL()
//                        let postParam = [
//                            "mail": ((result as? NSDictionary)?["email"]) as! String as String
//                            ] as [String : Any]
//                        let oWebManager: AlamofireManager = AlamofireManager()
//                        oWebManager.requestPost(strUrl, parameters: postParam) { (jsonResult) in
//
//                            Utiles.setHUD(false)
//
//                            if let error = jsonResult["error"] as? String
//                            {
//                                print(error)
//                                return
//                            }else{
//
//                                if jsonResult["customerId"] as? Int ?? 0 == 0
//                                {
//                                    let alert = UIAlertController(title: "Alert", message: "Sorry! User not found.", preferredStyle: UIAlertController.Style.alert)
//                                                               alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
//                                                               self?.present(alert, animated: true, completion: nil)
//                                    return
//                                }
//
//                                tokenId = jsonResult["token"] as? String ?? ""
//                                name = jsonResult["name"] as? String ?? ""
//                                lastName = jsonResult["lastName"] as? String ?? ""
//                                customerId = jsonResult["customerId"] as? Int ?? 0
//                                roleId = jsonResult["roleId"] as? Int ?? 0
//
//                                self?.navigationController?.popViewController(animated: true)
//
//                            }
//                        }
//
//
//                    } else {
//                        print("error \(error)")
//                    }
//                }
//
//            }
//        }
//    }
//
}



