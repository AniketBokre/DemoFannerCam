//
//  AlamofireManager.swift
//  NewFannerCam
//
//  Created by Jin on 25/09/20.
//  Copyright © 2020 fannercam3. All rights reserved.
//

import UIKit
import Foundation
import Alamofire

class AlamofireManager: NSObject {
    var isThereAccessToken : Bool = true
    var strRequestType : String = ""
    
    //MARK:- POST
    func requestGet(_ requestUrl: String, completionHandler: @escaping ([String : Any])->()) ->()
    {
        if Reachability.isConnectedToNetwork()
        {
            self.strRequestType = "GET"
            
            var headerParam : HTTPHeaders = ["" : ""]
            
            if tokenId.isEmpty
            {
                headerParam = ["Content-Type"   : "application/json"]
            }
            else
            {
                headerParam = ["Authorization"  : "Bearer " + tokenId,
                               "Content-Type"   : "application/json"]
            }
            
            AF.request(URL.init(string: requestUrl)!, method: .get, encoding: JSONEncoding.default, headers: headerParam).responseJSON { (response) in
                print(response)
                DispatchQueue.main.async {
                    let statusCode = response.response?.statusCode
                    if statusCode == 401 || statusCode == 502
                    {
                        completionHandler(["errorMessage" : "Something went wrong! Please try again after sometime."])
                        return;
                    }
                    
                    switch response.result{
                    case .success(let value):
                        if let dictResponse = value as? [String:Any]
                        {
                            completionHandler(dictResponse)
                        }
                        else
                        {
                            completionHandler(["errorMessage" : "Something went wrong! Please try again after sometime."])
                        }
                        break
                        
                    case .failure:
                        
                        if let err = response.error {
                            
                            // -1001 = "The request timed out." Server stopped working due to some reason.
                            
                            if ((err as NSError).code == NSURLErrorTimedOut)
                            {
                                completionHandler(["errorMessage" : "The request timed out. Something went wrong! Please try again after sometime."])
                            }
                                
                                // -1003 = "A server with the specified hostname could not be found." Wifi +  no internet connection.
                                
                                // -1009 = "The Internet connection appears to be offline."
                            else if ((err as NSError).code == NSURLErrorCannotFindHost || (err as NSError).code == NSURLErrorNotConnectedToInternet)
                            {
                                completionHandler(["errorMessage" : "There is an issue with the network connection. Please check your network settings and try again."])
                            }
                            else
                            {
                                completionHandler(["errorMessage" : (err as NSError).localizedDescription])
                            }
                        }
                        break
                    }
                }
            }
        }
        else
        {
            completionHandler(["errorMessage!" : "Network error."])
        }
    }
    
    //MARK:- POST
    func requestPost(_ requestUrl: String, parameters: [String : Any], completionHandler: @escaping ([String : Any])->()) ->()
    {
        if Reachability.isConnectedToNetwork()
        {
            self.strRequestType = "POST"
            
            var headerParam : HTTPHeaders = ["" : ""]
            
            if tokenId.isEmpty
            {
                headerParam = ["Content-Type"   : "application/json"]
            }
            else
            {
                headerParam = ["Authorization"  : "Bearer " + tokenId,
                               "Content-Type"   : "application/json"]
            }
            
            AF.request(URL.init(string: requestUrl)!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headerParam).responseJSON { (response) in
                print(response)
                DispatchQueue.main.async {
                    let statusCode = response.response?.statusCode
                    if statusCode == 401 || statusCode == 502
                    {
                        self.requestForNewToken(requestUrl, parameters: parameters, completionHandler: completionHandler)
                        return;
                    }
                    
                    switch response.result{
                    case .success(let value):
                        if let dictResponse = value as? [String:Any]
                        {
                            completionHandler(dictResponse)
                        }
                        else
                        {
                            completionHandler(["errorMessage" : "Something went wrong! Please try again after sometime."])
                        }
                        break
                        
                    case .failure:
                        
                        if let err = response.error {
                            
                            // -1001 = "The request timed out." Server stopped working due to some reason.
                            
                            if ((err as NSError).code == NSURLErrorTimedOut)
                            {
                                completionHandler(["errorMessage" : "The request timed out. Something went wrong! Please try again after sometime."])
                            }
                                
                                // -1003 = "A server with the specified hostname could not be found." Wifi +  no internet connection.
                                
                                // -1009 = "The Internet connection appears to be offline."
                            else if ((err as NSError).code == NSURLErrorCannotFindHost || (err as NSError).code == NSURLErrorNotConnectedToInternet)
                            {
                                completionHandler(["errorMessage" : "There is an issue with the network connection. Please check your network settings and try again."])
                            }
                            else
                            {
                                completionHandler(["errorMessage" : (err as NSError).localizedDescription])
                            }
                        }
                        break
                    }
                }
            }
        }
        else
        {
            completionHandler(["errorMessage!" : "Network error."])
        }
    }
    
    
    func requestForNewToken(_ requestUrl: String, parameters: [String : Any], completionHandler: @escaping ([String : Any])->()) ->()
    {
        
        let authRequestUrl: String = getServerBaseUrl() + getLoginURL()
        let authParameters = [
            "account": userName,
            "password": password,
            "local": "IT"
            ] as [String : Any]

        if Reachability.isConnectedToNetwork()
        {
            self.strRequestType = "POST"
            
            var headerParam : HTTPHeaders = ["" : ""]
            headerParam = ["Content-Type"   : "application/json"]
            
            
            AF.request(URL.init(string: authRequestUrl)!, method: .post, parameters: authParameters, encoding: JSONEncoding.default, headers: headerParam).responseJSON { (response) in
                print(response)
                DispatchQueue.main.async {
                    let statusCode = response.response?.statusCode
                    if statusCode == 401
                    {
                        completionHandler(["errorMessage" : "Token Expired."])
                        return;
                    }
                    
                    switch response.result{
                    case .success(let value):
                        if let dictResponse = value as? [String:Any]
                        {
                            if (dictResponse["token"] as? String) == nil
                            {
                                completionHandler(["errorMessage" : "Something went wrong! Please try again after sometime."])
                                return
                            } else {
                                tokenId = dictResponse["token"] as? String ?? ""
                                name = dictResponse["name"] as? String ?? ""
                                lastName = dictResponse["lastName"] as? String ?? ""
                                customerId = dictResponse["customerId"] as? Int ?? 0
                                roleId = dictResponse["roleId"] as? Int ?? 0
                            }
                            
                            self.requestPost(requestUrl, parameters: parameters, completionHandler: completionHandler)

                        }
                        else
                        {
                            completionHandler(["errorMessage" : "Something went wrong! Please try again after sometime."])
                        }
                        break
                        
                    case .failure:
                        
                        if let err = response.error {
                            
                            // -1001 = "The request timed out." Server stopped working due to some reason.
                            
                            if ((err as NSError).code == NSURLErrorTimedOut)
                            {
                                completionHandler(["errorMessage" : "The request timed out. Something went wrong! Please try again after sometime."])
                            }
                                
                                // -1003 = "A server with the specified hostname could not be found." Wifi +  no internet connection.
                                
                                // -1009 = "The Internet connection appears to be offline."
                            else if ((err as NSError).code == NSURLErrorCannotFindHost || (err as NSError).code == NSURLErrorNotConnectedToInternet)
                            {
                                completionHandler(["errorMessage" : "There is an issue with the network connection. Please check your network settings and try again."])
                            }
                            else
                            {
                                completionHandler(["errorMessage" : (err as NSError).localizedDescription])
                            }
                        }
                        break
                    }
                }
            }
        }
        else
        {
            completionHandler(["errorMessage!" : "Network error."])
        }
    }
}
