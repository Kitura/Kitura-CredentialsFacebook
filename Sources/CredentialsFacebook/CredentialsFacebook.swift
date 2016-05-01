/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Kitura
import KituraNet
import LoggerAPI
import Credentials

import SwiftyJSON

import Foundation

public class CredentialsFacebook : CredentialsPluginProtocol {
    
    private var clientId : String
    
    private var clientSecret : String
    
    public var callbackUrl : String
    
    public var name : String {
        return "Facebook"
    }
    
    public var type : CredentialsPluginType {
        return .Session
    }
    
    public init (clientId: String, clientSecret : String, callbackUrl : String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.callbackUrl = callbackUrl
    }
    
    public var usersCache : NSCache?
    
    /// https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow
    public func authenticate (request: RouterRequest, response: RouterResponse, options: [String:OptionValue], onSuccess: (UserProfile) -> Void, onFailure: () -> Void, onPass: () -> Void, inProgress: () -> Void) {
        if let code = request.queryParams["code"] {
            var requestOptions = [ClientRequestOptions]()
            requestOptions.append(.Schema("https://"))
            requestOptions.append(.Hostname("graph.facebook.com"))
            requestOptions.append(.Method("GET"))
            requestOptions.append(.Path("/v2.3/oauth/access_token?client_id=\(clientId)&redirect_uri=\(callbackUrl)&client_secret=\(clientSecret)&code=\(code)"))
            var headers = [String:String]()
            headers["Accept"] = "application/json"
            requestOptions.append(.Headers(headers))
            
            let requestForToken = Http.request(requestOptions) { fbResponse in
                if let fbResponse = fbResponse where fbResponse.statusCode == HttpStatusCode.OK {
                    do {
                        var body = NSMutableData()
                        try fbResponse.readAllData(body)
                        var jsonBody = JSON(data: body)
                        if let token = jsonBody["access_token"].string {
                            requestOptions = [ClientRequestOptions]()
                            requestOptions.append(.Schema("https://"))
                            requestOptions.append(.Hostname("graph.facebook.com"))
                            requestOptions.append(.Method("GET"))
                            requestOptions.append(.Path("/me?access_token=\(token)"))
                            headers = [String:String]()
                            headers["Accept"] = "application/json"
                            requestOptions.append(.Headers(headers))
                            
                            let requestForProfile = Http.request(requestOptions) { profileResponse in
                                if let profileResponse = profileResponse where profileResponse.statusCode == HttpStatusCode.OK {
                                    do {
                                        body = NSMutableData()
                                        try profileResponse.readAllData(body)
                                        jsonBody = JSON(data: body)
                                        if let id = jsonBody["id"].string,
                                            let name = jsonBody["name"].string {
                                            let userProfile = UserProfile(id: id, displayName: name, provider: self.name)
                                            let newCacheElement = BaseCacheElement(profile: userProfile)
                                            self.usersCache!.setObject(newCacheElement, forKey: token.bridge())
                                            onSuccess(userProfile)
                                            return
                                        }
                                    }
                                    catch {
                                        Log.error("Failed to read Facebook response")
                                    }
                                }
                                else {
                                    onFailure()
                                }
                            }
                            requestForProfile.end()
                        }
                    }
                    catch {
                        Log.error("Failed to read Facebook response")
                    }
                }
                else {
                    onFailure()
                }
            }
            requestForToken.end()
        }
        else {
            // Log in
            do {
                try response.redirect("https://www.facebook.com/dialog/oauth?client_id=\(clientId)&redirect_uri=\(callbackUrl)&response_type=code")
                inProgress()
            }
            catch {
                Log.error("Failed to redirect to Facebook login page")
            }
        }
    }
}
