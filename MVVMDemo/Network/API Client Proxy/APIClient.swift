//
//  APIClient.swift

import UIKit
import Alamofire
import MBProgressHUD

class APIClient: NSObject {
    
    @discardableResult
    static func performRequest<T: Decodable>(route: APIConfiguration,
                                             successCompletion:@escaping (T) -> Void,
                                             failureCompletion:@escaping (APIErrors) -> Void) -> DataRequest {
        
        print("API URL:\(route.path), Paramters:\(String(describing: route.parameters))")

        return Alamofire.request(route)
            
            .responseData(queue: DispatchQueue.main, completionHandler: { (response ) in
                DispatchQueue.main.async {
                    
                    do {
                        if let data = response.data {
                            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                            print(json as Any)
                            log.verbose(json ?? "")
                            
                            if let json = try JSONSerialization.jsonObject(with: response.data!, options: []) as? NSDictionary {
                                print(json)
                            }
                            if let json = try JSONSerialization.jsonObject(with: response.data!, options: []) as? NSArray {
                                print(json)
                            }
                        }
                    } catch let error {
                        log.verbose(error)
                    }
                    
                    if response.result.isFailure {
                        
                        let decoder = JSONDecoder()
                        var errorMsg = "server_error"
                        if response.error != nil {
                            
                            if response.response?.statusCode == -1009 || response.response?.statusCode == nil {
                                
                                errorMsg = LocalizedStringConstant.noInternetConnection
                                
                            } else {
                                errorMsg = (response.error?.localizedDescription)!
                            }
                        }
                        
                        let errorDict = ["errors": ["APIErrors": [["messageCode": "", "message": errorMsg]]]]
                        do {
                            let errorData = try JSONSerialization.data(withJSONObject: errorDict, options: .prettyPrinted)
                            let decodedData = try? decoder.decode(APIErrors.self, from: errorData)
                            
                            failureCompletion(decodedData!)
                            
                        } catch {
                            log.verbose(error.localizedDescription)
                        }
                    } else {
                        
                        let decoder = JSONDecoder()
                        
                        if response.response?.statusCode == 200 {
                            
                            if route.path == APIEndpoint.logoutAPIURL &&
                                route.requestType == .delete {
                                
                                let successDict = ["messageCode": "200", "message": "Success"]
                                
                                do {
                                    
                                    let successData = try JSONSerialization.data(withJSONObject: successDict, options: .prettyPrinted)
                                    let decodedData = try? decoder.decode(T.self, from: successData)
                                    
                                    if decodedData == nil {
                                        let errorDict = ["general": [["messageCode": "", "message": LocalizedAlertConstants.somethingWentWrong]]]
                                        do {
                                            let errorData = try JSONSerialization.data(withJSONObject: errorDict, options: .prettyPrinted)
                                            let decodedData = try? decoder.decode(APIErrors.self, from: errorData)
                                            failureCompletion(decodedData!)
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } else {
                                        successCompletion(decodedData!)
                                    }
                                    
                                } catch {
                                    
                                    log.verbose(error.localizedDescription)
                                }
                                
                            } else {
                                
                                let decodedData = try? decoder.decode(T.self, from: response.data!)
                                
                                successCompletion(decodedData!)
                            }
                            
                        } else if response.response?.statusCode == 401 {
                            
                            //Handle Invalid Session Error
                            //Display invalid session key alert
                            
                            checkForAPIError(response: response,
                                             failureCompletion: failureCompletion)
                            
                        } else {
                            
                            checkForAPIError(response: response,
                                             failureCompletion: failureCompletion)
                        }
                    }
                }
            })
    }
    
    static func checkForAPIError(response: DataResponse<Data>,
                                 failureCompletion:@escaping (APIErrors) -> Void) {
        
        let decoder = JSONDecoder()
        
        var decodedData = try? decoder.decode(APIErrors.self, from: response.data!)
        
        if decodedData != nil {
            
            if let errorDetail  = decodedData?.general?[0] {
                
                if errorDetail.messageCode == "main.httpSessionExpired" {
                    MBProgressHUD.hide(for: NAVIGATIONHELPER.getTopWindow(), animated: true)
                    _ = UserDefaultRepository.sharedInstance.removeValueFromDB(key: UserDefaultKeys.userID)
                    _ = UserDefaultRepository.sharedInstance.removeValueFromDB(key: UserDefaultKeys.sessionKey)
                    let alertView = AlertView(message: LocalizedAlertConstants.sessionExpired, okButtonText: LocalizedStringConstant.okString, cancelButtonText: String.empty()) { (_, button) in
                        
                        if button == .cancel {
                            
                        } else {
                            
                            GLOBALHELPER.clearDatabase()
                            NAVIGATIONHELPER.navigateToLoginScreen()
                            
                        }
                    }
                    alertView.show(animated: true)
                    return
                }
                
                log.verbose(errorDetail as Any)
            }
            
            failureCompletion(decodedData!)
        } else {
            
            failureCompletion(APIErrors())
        }
    }
    
    static  func postMultipartData(multiPartType: MultipartType, fileName: String, imageData: Data, successCompletion:@escaping (FileUpload) -> Void, failureCompletion:@escaping (General) -> Void ) {
        
        let baseURL = Environment().configuration(Plist.baseURL)
        let url =  String(format: "%@%@%@", baseURL, TenantConfig.tenantId, APIEndpoint.imageUpload)
        var mimeType = MimeType.csvText.rawValue
        if multiPartType.rawValue == MultipartType.image.rawValue {
           // url = String(format: "%@%@", baseURL, APIEndpoint.imageUpload)
            mimeType = MimeType.image.rawValue
        }
        
        var headers: HTTPHeaders = [
            HTTPHeaderField.contentType.rawValue: ContentType.multipart.rawValue,
            HTTPHeaderField.acceptLangauge.rawValue: ContentType.ENUS.rawValue
        ]
        
        if let apiSessionKey = UserDefaultRepository.sharedInstance.getUserDefaultsFromDB(key: UserDefaultKeys.sessionKey) {
            let sessionKey = "Bearer " + apiSessionKey
            headers[HTTPHeaderField.authentication.rawValue] = sessionKey
        }
        
        let manager = Alamofire.SessionManager.default
        manager.session.configuration.timeoutIntervalForRequest = 60
        
        manager.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imageData, withName: "file[]", fileName: fileName, mimeType: mimeType)
        },
            to: url,
            headers: headers,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { (response) -> Void in
                        let decoder = JSONDecoder()
                        DispatchQueue.main.async {
                            
                            if response.response?.statusCode == 200 {
                                
                                let decodedData = try? decoder.decode(FileUpload.self, from: response.data!)
                                
                                successCompletion(decodedData!)
                                
                            } else {
                                
                                do {
                                    if let json = try JSONSerialization.jsonObject(with: response.data!, options: []) as? NSDictionary {
                                        print(json)
                                    }
                                } catch let error as NSError {
                                    print("Failed to load: \(error.localizedDescription)")
                                }
                                
                                let decodedData = try? decoder.decode(General.self, from: response.data!)
                                
                                failureCompletion(decodedData!)
                            }
                        }
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
        }
        )
    }
}
