//
//  MainViewController.swift
//  IPDemo
//
//  Created by Do Tri on 6/22/18.
//  Copyright © 2018 Do Tri. All rights reserved.
//

import UIKit
import SwiftyJSON

class MainViewController: UIViewController {

    var userInfo: JSON!
    @IBOutlet weak var userInfoLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Application"
        
        userInfoLbl.text = String(format: "User ID: %@\nType: %@\n\nPreferred Username: %@\nSub: %@", userInfo["user_id"].stringValue, userInfo["user_type"].stringValue, userInfo["preferred_username"].stringValue, userInfo["sub"].stringValue)

        self.navigationItem.leftBarButtonItem = nil
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.hidesBackButton = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logOut(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: false)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
