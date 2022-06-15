//
//  UserStorage.swift
//  YTLiveStreaming
//
//  Created by Jin on 2/11/18.
//  Copyright © 2018 Jin. All rights reserved.
//

import Foundation

struct GoogleUser: Codable {
   let userId: String
   let idToken: String
   let fullName: String
   let givenName: String
//   let familyName: String
   let email: String
   
   var description: String {
      return self.fullName
   }

   var token: String {
      return self.idToken
   }
   
   init(userId: String, idToken: String, fullName: String, givenName: String, email: String) { //familyName: String,
      self.userId = userId
      self.idToken = idToken
      self.fullName = fullName
      self.givenName = givenName
//      self.familyName = familyName
      self.email = email
   }
}

struct UserStorage {

   static let kCurrentUserDataKey = "CurrentUserKey"
   
   var user: GoogleUser? {
      get {
         let userDefaults = UserDefaults.standard
         if let data = userDefaults.data(forKey: UserStorage.kCurrentUserDataKey) {
            if let user = try? JSONDecoder().decode(GoogleUser.self, from: data) {
               return user
            }
         }
         return nil
      }
      set {
         if let user = newValue {
            if let data = try? JSONEncoder().encode(user) {
               let userDefaults = UserDefaults.standard
               userDefaults.set(data, forKey: UserStorage.kCurrentUserDataKey)
               userDefaults.synchronize()
            }
         } else {
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: UserStorage.kCurrentUserDataKey)
         }
      }
   }
}
