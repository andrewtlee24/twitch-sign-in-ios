//
//  TwitchSignInViewController.swift
//
//  Created by Andrew Lee on 2020-10-16.
//  Copyright © 2020 Andrew Lee. All rights reserved.
//

import Foundation
import UIKit
import WebKit

protocol TwitchSignInDelegate {
    func twitchSignInDismiss()
    func twitchSignInSuccessful(accessToken : String, authData : TwitchAuthorizationData)
    func twitchSignInError(error : TwitchSignInError)
}

class TwitchSignInViewController : UIViewController, WKNavigationDelegate {

    let twitchAuthorizeURL : String! = "https://id.twitch.tv/oauth2/authorize"
    let twitchValidateURL : String! = "https://id.twitch.tv/oauth2/validate"
    let accessTokenKey : String = "access_token"
    
    private var _clientID : String!
    private var _redirectURI : String!
    private var _scopes : [String]!
    var delegate : TwitchSignInDelegate?
    
    var _webView : WKWebView!
    var _dismissButton : UIButton!
    
    init(clientID : String, redirectURI : String, scopes : [String]) {
        _clientID = clientID
        _redirectURI = redirectURI
        _scopes = scopes
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        _webView.navigationDelegate = self
        self.view.addSubview(_webView)
        
        _dismissButton = UIButton(frame: CGRect(x: self.view.frame.size.width - 50, y: 0, width: 50, height: 50))
        _dismissButton.setTitle("X", for: UIControl.State.normal);
        _dismissButton.addTarget(self, action: #selector(onDismiss(sender:)), for: .touchUpInside)
        _dismissButton.backgroundColor = UIColor.black
        self.view.addSubview(_dismissButton)
        
        let scopesStr = _scopes.joined(separator: " ")
        let urlStr = String(format: "%@?client_id=%@&redirect_uri=%@&response_type=token&scope=%@", twitchAuthorizeURL, _clientID, _redirectURI, scopesStr)
        
        let url = URL(string: urlStr)!
        let request = URLRequest(url: url)
        _webView.load(request)
    }
    
    @objc private func onDismiss(sender : UIButton) {
        if let delegate = delegate {
            delegate.twitchSignInDismiss()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        
        if let url = request.url?.absoluteString {
            let prefix = String(format: "%@#", _redirectURI)
            if url.hasPrefix(prefix) {
                let queryItems : [URLQueryItem]? = processQueryItemsFromURL(inputURL: url)
                guard let items = queryItems else {
                    if let delegate = delegate {
                        delegate.twitchSignInError(error:TwitchSignInError.QueryItemParseError)
                    }
                    return
                }
                
                guard let accessToken = items.first(where: {$0.name == accessTokenKey})?.value else {
                    if let delegate = delegate {
                        delegate.twitchSignInError(error:TwitchSignInError.MissingAccessTokenError)
                    }
                    return
                }
                
                let oauth = String(format: "OAuth %@", accessToken)
                
                let validateURL = URL(string: twitchValidateURL)!
                var request = URLRequest(url:validateURL)
                request.addValue(oauth, forHTTPHeaderField: "Authorization")
                URLSession.shared.dataTask(with: request){ (data, response, error) in
                    guard error == nil, let data = data else {
                        if let delegate = self.delegate {
                            delegate.twitchSignInError(error:TwitchSignInError.UserValidationError)
                        }
                        return
                    }

                    if let str = String(data: data, encoding: .utf8) {
                        guard let authData = self.decodeAuthorizationData(authorizationJSON: str) else {
                            if let delegate = self.delegate {
                                delegate.twitchSignInError(error:TwitchSignInError.TwitchResponseDecodeError)
                            }
                            return
                        }
                        
                        if let delegate = self.delegate {
                            delegate.twitchSignInSuccessful(accessToken: accessToken, authData: authData)
                        }
                    }
                }.resume()
            }
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    private func processQueryItemsFromURL(inputURL : String) -> [URLQueryItem]? {
        // Replacing the # symbol to separate the redirect URI and params makes the response string compatible with URLComponents
        if let range = inputURL.range(of: "#") {
            let url = inputURL.replacingCharacters(in: range, with: "?")
            let components = URLComponents(string: url)
            if let queryItems = components?.queryItems {
                return queryItems
            }
            return nil
        }
        return nil
    }
    
    private func decodeAuthorizationData(authorizationJSON : String) -> TwitchAuthorizationData? {
        let decoder = JSONDecoder()
        let data = Data(authorizationJSON.utf8)
        do {
            let authData = try decoder.decode(TwitchAuthorizationData.self, from: data)
            return authData
        } catch {
            return nil
        }
    }
}

struct TwitchAuthorizationData : Codable {
    var client_id : String
    var login : String?
    var scopes : [String]?
    var user_id : String
    var expires_in : Int
}

enum TwitchSignInError : Error {
    case MissingAccessTokenError //Twitch did not return an access token
    case TwitchResponseDecodeError //The response from Twitch failed to decode
    case QueryItemParseError // Failed to parse the query items returned from Twitch
    case UserValidationError // The call to fetch the logged in user failed
}
