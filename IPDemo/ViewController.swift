//
//  ViewController.swift
//  IPDemo
//
//  Created by Do Tri on 6/21/18.
//  Copyright © 2018 Do Tri. All rights reserved.
//

import UIKit
import SVProgressHUD
import SwiftyJSON
import AppAuth
import Alamofire
import SwiftKeychainWrapper
import SafariServices

let BASE_URL = "https://st-api.thousandhands.com"
let IS_TESTING = false
let AUTH_PATH = "/ipfication/authorization_endpoint?deviceid=%@"

@available(iOS 11.0, *)
class ViewController: UIViewController {
    
    private var code = ""
    private var isLoggingInWithIP = false
    private var uuid = ""
    private var authState: OIDAuthState?
    var session : SFAuthenticationSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedCode(info:)), name: NSNotification.Name(rawValue: "RECEIVEDCODE"), object: nil)
        
        let retrievedString: String? = KeychainWrapper.standard.string(forKey: "MyIPDEMOUUID")

        if retrievedString != nil {
            uuid = retrievedString!
        }
        else {
            if UIDevice.current.identifierForVendor != nil {
                uuid = UIDevice.current.identifierForVendor!.uuidString
            }
            if uuid != "" {
                KeychainWrapper.standard.set(uuid, forKey: "MyIPDEMOUUID")
            }
        }
        print(uuid)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        if isLoggingInWithIP && code != "" {
            SVProgressHUD.show()
            LoginManager.sharedInstance.loginIP(code, success: { (result) in
                print(result)
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "OpenMain", sender: result)
                }
                SVProgressHUD.dismiss()
            }) { (error) in
                SVProgressHUD.dismiss()
            }
            isLoggingInWithIP = false
        }
    }
    
    @objc func receivedCode(info: Notification) {
        let userInfo = info.userInfo
        if let serverCode = userInfo!["code"] as? String {
            code = serverCode
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginWithIP(_ sender: UIButton) {
        isLoggingInWithIP = true
//        let authURL = String(format: BASE_URL + AUTH_PATH, uuid)
//        self.performSegue(withIdentifier: "OpenWeb", sender: authURL)
        
        //let authorizationEndpoint = URL(string: "https://api.ipification.com/auth/realms/mctest/protocol/openid-connect/auth")
        //let tokenEndpoint = URL(string: "https://api.ipification.com/auth/realms/mctest/protocol/openid-connect/token")
        
        if IS_TESTING {
            let alert = UIAlertController(title: "Testing Mode", message: "Enter ClientID", preferredStyle: UIAlertControllerStyle.alert)
            alert.addTextField { (textField) in
                
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                kClientID = alert.textFields![0].text!
                self.discoverOAuth()
                alert .dismiss(animated: true, completion: nil)
            }))
            alert.textFields![0].text = kClientID
            self.present(alert, animated: true, completion: nil)
        }
        else {
            discoverOAuth()
        }
    }
    
    func discoverOAuth() {
        guard let issuer = URL(string: kIssuer) else {
            self.logMessage("Error creating URL for : \(kIssuer)")
            return
        }
        
        self.logMessage("Fetching configuration for issuer: \(issuer)")
        
        SVProgressHUD.show()
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            
            guard let config = configuration else {
                self.logMessage("Error retrieving discovery document: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                self.setAuthState(nil)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                }
                
                return
            }
            
            self.logMessage("Got configuration: \(config)")
            print(kClientID)
            self.doAuthWithAutoCodeExchange(configuration: config, clientID: kClientID, clientSecret: nil)
        }
    }
    
    func doAuthWithAutoCodeExchange(configuration: OIDServiceConfiguration, clientID: String, clientSecret: String?) {
        
        guard let redirectURI = URL(string: kRedirectURI) else {
            self.logMessage("Error creating URL for : \(kRedirectURI)")
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
            }
            return
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            self.logMessage("Error accessing AppDelegate")
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
            }
            return
        }
        
        // builds authentication request
        let request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientID,
                                              clientSecret: clientSecret,
                                              scopes: [OIDScopeOpenID, OIDScopeProfile],
                                              redirectURL: redirectURI,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)
        
        // performs authentication request
        logMessage("Initiating authorization request with scope: \(request.scope ?? "DEFAULT_SCOPE")")
        
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self) { authState, error in
            
            if let authState = authState {
                self.setAuthState(authState)
                self.logMessage("Got authorization tokens. Access token: \(authState.lastTokenResponse?.accessToken ?? "DEFAULT_TOKEN")")
            } else {
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                }
                self.logMessage("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showMessage(self, title: "Error", message: error?.localizedDescription ?? "DEFAULT_ERROR")
                }
                self.setAuthState(nil)
            }
        }
    }
    
    func showMessage(_ container: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            
            alert .dismiss(animated: true, completion: nil)
            
            
        }))
        
        DispatchQueue.main.async {
            container.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func unwindToVC1ABCDEF(segue:UIStoryboardSegue) {
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenWeb" {
            if let webVC = segue.destination as? WebViewController {
                webVC.url = sender as! String
            }
        }
        else if segue.identifier == "OpenMain" {
            let mainVC = segue.destination as! MainViewController
            mainVC.userInfo = sender as! JSON
        }
    }
}

@available(iOS 11.0, *)
extension ViewController: OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    
    func didChange(_ state: OIDAuthState) {
        self.stateChanged()
    }
    
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        self.logMessage("Received authorization error: \(error)")
    }
}

//MARK: Helper Methods
@available(iOS 11.0, *)
extension ViewController {
    
    func saveState() {
        
        var data: Data? = nil
        
        if let authState = self.authState {
            data = NSKeyedArchiver.archivedData(withRootObject: authState)
        }
        
        UserDefaults.standard.set(data, forKey: kAppAuthExampleAuthStateKey)
        UserDefaults.standard.synchronize()
    }
    
    func loadState() {
        guard let data = UserDefaults.standard.object(forKey: kAppAuthExampleAuthStateKey) as? Data else {
            return
        }
        
        if let authState = NSKeyedUnarchiver.unarchiveObject(with: data) as? OIDAuthState {
            self.setAuthState(authState)
        }
    }
    
    func setAuthState(_ authState: OIDAuthState?) {
        if (self.authState == authState) {
            return;
        }
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
        }
        self.authState = authState;
        self.authState?.stateChangeDelegate = self;
        self.stateChanged()
    }
    
    func updateUI() {
        print("updateUI")
        if let authState = self.authState {
            guard let accessToken = authState.lastTokenResponse?.accessToken, accessToken != "" else {
                return
            }
            getUserInfo()
        }
    }
    
    func refreshToken() {
        self.authState?.performAction(freshTokens: { (accessToken, refreshToken, error) in
            if error != nil {
                return
            }
            
        })
    }
    
    func getUserInfo() {
        guard let userinfoEndpoint = self.authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.userinfoEndpoint else {
            self.logMessage("Userinfo endpoint not declared in discovery document")
            return
        }
        
        self.logMessage("Performing userinfo request")
        
        let currentAccessToken: String? = self.authState?.lastTokenResponse?.accessToken
        
        self.authState?.performAction() { (accessToken, idTOken, error) in
            
            if error != nil  {
                self.logMessage("Error fetching fresh tokens: \(error?.localizedDescription ?? "ERROR")")
                return
            }
            
            guard let accessToken = accessToken else {
                self.logMessage("Error getting accessToken")
                return
            }
            
            if currentAccessToken != accessToken {
                self.logMessage("Access token was refreshed automatically (\(currentAccessToken ?? "CURRENT_ACCESS_TOKEN") to \(accessToken))")
            } else {
                self.logMessage("Access token was fresh and not updated \(accessToken)")
            }
            
            var urlRequest = URLRequest(url: userinfoEndpoint)
            urlRequest.allHTTPHeaderFields = ["Authorization":"Bearer \(accessToken)"]
            
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                
                DispatchQueue.main.async {
                    
                    guard error == nil else {
                        self.logMessage("HTTP request failed \(error?.localizedDescription ?? "ERROR")")
                        return
                    }
                    
                    guard let response = response as? HTTPURLResponse else {
                        self.logMessage("Non-HTTP response")
                        return
                    }
                    
                    guard let data = data else {
                        self.logMessage("HTTP response data is empty")
                        return
                    }
                    
                    var json: [AnyHashable: Any]?
                    
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        self.logMessage("JSON Serialization Error")
                    }
                    
                    if response.statusCode != 200 {
                        // server replied with an error
                        let responseText: String? = String(data: data, encoding: String.Encoding.utf8)
                        
                        if response.statusCode == 401 {
                            // "401 Unauthorized" generally indicates there is an issue with the authorization
                            // grant. Puts OIDAuthState into an error state.
                            let oauthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                                                                                                errorResponse: json,
                                                                                                underlyingError: error)
                            self.authState?.update(withAuthorizationError: oauthError)
                            self.logMessage("Authorization Error (\(oauthError)). Response: \(responseText ?? "RESPONSE_TEXT")")
                        } else {
                            self.logMessage("HTTP: \(response.statusCode), Response: \(responseText ?? "RESPONSE_TEXT")")
                        }
                        
                        return
                    }
                    
                    if let json = json {
                        self.logMessage("Success: \(json)")
                        let result = JSON(json)
                        let _ = User(fromJSON: result)
                        let _ = User(fromJSON1: result)
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "OpenMain", sender: result)
                        }
                    }
                }
            }
            
            task.resume()
        }
    }
    
    func stateChanged() {
        self.saveState()
        self.updateUI()
    }
    
    func logMessage(_ message: String?) {
        
        guard let message = message else {
            return
        }
        
        print(message);
        
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "hh:mm:ss";
//            let dateString = dateFormatter.string(from: Date())
//
//            // appends to output log
//            DispatchQueue.main.async {
//                let logText = "\(self.logTextView.text ?? "")\n\(dateString): \(message)"
//                self.logTextView.text = logText
//            }
    }
}
