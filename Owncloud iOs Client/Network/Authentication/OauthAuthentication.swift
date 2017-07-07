//
//  OauthAuthentication
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 29/06/2017.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


import Foundation


class OauthAuthentication: NSObject, URLSessionDelegate, URLSessionTaskDelegate {


    func accessTokenAuthRequest(_ url: URL, authCode: String, completionHandler completion: @escaping (_ data: NSData?,_ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void) {
     
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue(UtilsUrls.getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let authId = k_oauth2_client_id+":"+k_oauth2_client_secret
        let base64EncodedAuthId: String = UtilsFramework.afBase64EncodedString(from: authId)
        request.setValue("Basic \(base64EncodedAuthId)", forHTTPHeaderField: "Authorization")

        let body =  "grant_type=authorization_code&code=\(authCode)&redirect_uri=\(k_oauth2_redirect_uri)&client_id=\(k_oauth2_client_id)"
        let bodyEncoded = body.data(using: String.Encoding.utf8)
        request.httpBody = bodyEncoded
        print("request body: \(bodyEncoded))")
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        //        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if let error = error {
                print(error.localizedDescription)
                completion(nil, nil, error)
                
            } else if let data = data {
                completion(data as NSData, response as? HTTPURLResponse, error)
                
                //check if exist error, error_description or error_uri in json, -> completion(nil, response as? HTTPURLResponse, error)
                do {
                    if let dict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject] {
                        print("accessTokenAuthRequest json:", dict)
                        completion(data as NSData, response as? HTTPURLResponse, error)
                    }
                    
                } catch let error {
                    print("accessTokenAuthRequest  no data error:", error.localizedDescription)
                    completion(nil, response as? HTTPURLResponse, error)
                }
                
            } else {
                completion(nil, response as? HTTPURLResponse, error)
            }
        })
        task.resume()
    }
    
    func getAuthDataBy(url: URL, authCode: String, withCompletion completion: @escaping (_ data: NSData? ,_ error: Error?) -> Void)  {
        
        self.accessTokenAuthRequest(url, authCode: authCode, completionHandler: { (data: NSData?, response: URLResponse?, error: Error?) -> Void in
            
            if data != nil {
                completion(data, nil )
            } else {
               completion(nil, error)
            }
        })
        
    }
    
    func storeOauthDataInKeychain(data: NSData) {
        
        //TODO: get user id, name,
        
//        let userId = ""
//        let username = ""
//        OCKeychain.setCredentialsById(, withUsername: , andData: data)
    }
    
    
    func oauthUrlTogetAuthCodeWith (serverPath : String) -> URL {
        
        let oauth2RedirectUri = k_oauth2_redirect_uri
        let oauth2RedirectUriEncoded = oauth2RedirectUri.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        
        let fullServerPath = serverPath + k_oauth2_authorization_endpoint
        let urlComps: NSURLComponents = NSURLComponents(string: fullServerPath)!
        
        let queryItems = [NSURLQueryItem(name: "response_type", value: "code"),
                          NSURLQueryItem(name: "redirect_uri", value: oauth2RedirectUriEncoded),
                          NSURLQueryItem(name: "client_id", value: k_oauth2_client_id)
                        ]
        urlComps.queryItems = queryItems as [URLQueryItem]
        
        let fullOauthUrl = urlComps.url
        
        return fullOauthUrl!
        
    }

    func oauthUrlToGetTokenWith(serverPath : String) -> URL {
    
        var serverPathUrl = URL(string: serverPath)
        serverPathUrl = serverPathUrl?.appendingPathComponent(k_oauth2_token_endpoint)
        let urlComps = NSURLComponents(string: (serverPathUrl?.absoluteString)!)
        
        let fullOauthUrl = urlComps?.url!
        
        return fullOauthUrl!
    }

    
}
