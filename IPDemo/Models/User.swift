//
//  User.swift
//  IPDemo
//
//  Created by Do Tri on 7/30/18.
//  Copyright © 2018 Do Tri. All rights reserved.
//

import UIKit
import SwiftyJSON

class User {
    var name : String
    var type : String
    init() {
        name = ""
        type = ""
    }
    
    convenience init(fromJSON1 json: JSON) {
        self.init()
    }
    
    convenience init(fromJSON json: JSON) {
        self.init()
        name = json["full_name"].stringValue
        type = json["type"].stringValue
    }
}
