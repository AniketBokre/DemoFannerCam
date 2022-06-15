//
//  UserDefaults.swift
//  NewFannerCam
//
//  Created by iMac on 25/09/20.
//  Copyright © 2020 fannercam3. All rights reserved.
//

import Foundation
var customerId: Int {
    get {
        return UserDefaults.standard.integer(forKey: "customerId")
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "customerId")
        UserDefaults.standard.synchronize()
    }
}

var roleId: Int {
    get {
        return UserDefaults.standard.integer(forKey: "roleId")
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "roleId")
        UserDefaults.standard.synchronize()
    }
}

var tokenId: String {
    get {
        return UserDefaults.standard.string(forKey: "tokenId") ?? ""
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "tokenId")
        UserDefaults.standard.synchronize()
    }
}

var name: String {
    get {
        return UserDefaults.standard.string(forKey: "name") ?? ""
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "name")
        UserDefaults.standard.synchronize()
    }
}

var lastName: String {
    get {
        return UserDefaults.standard.string(forKey: "lastName") ?? ""
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "lastName")
        UserDefaults.standard.synchronize()
    }
}

var userName: String {
    get {
        return UserDefaults.standard.string(forKey: "userName") ?? ""
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "userName")
        UserDefaults.standard.synchronize()
    }
}

var password: String {
    get {
        return UserDefaults.standard.string(forKey: "password") ?? ""
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "password")
        UserDefaults.standard.synchronize()
    }
}

