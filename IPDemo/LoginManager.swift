//
//  LoginManager.swift
//  IPDemo
//
//  Created by Do Tri on 6/21/18.
//  Copyright © 2018 Do Tri. All rights reserved.
// OK

import UIKit
import SwiftyJSON
import SwiftHTTP

let LOGIN_PATH = "/api/v1/oauth/token"

class LoginManager: NSObject {
    
    static let sharedInstance = LoginManager()
    
    func loginIP(_ code: String, success successBlock: @escaping (_ result: JSON) -> Void, failure failureBlock : ((NSError?) -> ())!) {
        let url = BASE_URL + LOGIN_PATH
        let params = ["code": code, "provider": "ipfication", "grant_type": "assertion", "client_type": "ios"]
        
        let headers = [
            "X-Device-Type": "ios",
        ]
        print(headers)
        print(params)
        HTTP.POST(url, parameters: params) { response in
            if let err = response.error {
                print(response.URL ?? "empty URL")
                print("error: \(err.localizedDescription)")
                if response.statusCode == 401 {
                    do {
                        let json = try JSON(data: response.data)
                        successBlock(json)
                    }
                    catch {
                        successBlock(JSON.null)
                    }
                } else {
                    failureBlock(NSError(domain: "", code: 1, userInfo: ["message": "message"]))
                }
                
                return //also notify app of failure as needed
            }
            do {
                let json = try JSON(data: response.data)
                successBlock(json)
            }
            catch {
                successBlock(JSON.null)
            }
        }
    }
}
