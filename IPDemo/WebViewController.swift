//
//  WebViewController.swift
//  ezyHelpers
//
//  Created by Do Tri on 8/4/16.
//  Copyright © 2016 Do Tri. All rights reserved.
//

import UIKit
import SVProgressHUD
import SwiftyJSON

class WebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    var url = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Logging in ... Please wait"
        
        let backBtn = UIButton(type: UIButtonType.custom)
        backBtn.setImage(UIImage(named: "arrow_left"), for: UIControlState())
        backBtn.addTarget(self, action: #selector(self.back), for: UIControlEvents.touchUpInside)
        backBtn.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        let backBarButtonItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = backBarButtonItem
        
        let backButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backButtonItem
        
        
        print(url)
        if url != "" {
            SVProgressHUD.show()
            webView.loadRequest(URLRequest(url: URL(string: url)!))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }
    
    @objc func back() {
        self.navigationController!.popViewController(animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func webViewDidFinishLoad(_ webView: UIWebView) {
        SVProgressHUD.dismiss()
        print("webViewDidFinishLoad")
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        SVProgressHUD.dismiss()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.url != nil {
            let urlString = request.url!.absoluteString
            if urlString.contains("session_state=") && urlString.contains("code=") {
                let code = urlString.components(separatedBy: "code=")[1]
                print(code)
                //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RECEIVEDCODE"), object: nil, userInfo: ["code" : code])
                //SVProgressHUD.dismiss()
                //self.back()
                
                SVProgressHUD.show()
                
                LoginManager.sharedInstance.loginIP(code, success: { (result) in
                    print(result)
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "OpenMain", sender: result)
                        SVProgressHUD.dismiss()
                    }
                    
                    
                }) { (error) in
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                    }
                    
                }
                
            }
            
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenMain" {
            let mainVC = segue.destination as! MainViewController
            mainVC.userInfo = sender as! JSON
        }
    }

}
