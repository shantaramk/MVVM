//
//  APIConfiguration.swift

import Foundation
import Alamofire

protocol APIConfiguration: URLRequestConvertible {
    
    var requestType: HTTPMethod { get }
    var path: String { get }
    var parameters: Parameters? { get }
    
}

extension APIConfiguration {
    
    func asURLRequest() throws -> URLRequest {
        
        let baseURL = Environment().configuration(Plist.baseURL)
        
        let url =  String(format: "%@%@%@", baseURL, TenantConfig.tenantId, path)
        
        let urlwithPercent = url.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        
        var urlRequest = URLRequest(url: URL(string: urlwithPercent!)!)
        
        log.verbose(urlRequest)
        
        // Http method
        urlRequest.httpMethod = requestType.rawValue
        
        //common headers
        urlRequest.setValue(ContentType.ENUS.rawValue, forHTTPHeaderField: HTTPHeaderField.acceptLangauge.rawValue)
        urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue)
        urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
        if let apiSessionKey = UserDefaultRepository.sharedInstance.getUserDefaultsFromDB(key: UserDefaultKeys.sessionKey) {
            if !apiSessionKey.isEmpty {
                let sessionKey = "Bearer " + apiSessionKey
                log.verbose(sessionKey)
                print(sessionKey)
                urlRequest.setValue( sessionKey, forHTTPHeaderField: HTTPHeaderField.authentication.rawValue)
            }
            
        }
        
        if let parameters = parameters {
            do {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch {
                log.verbose( error)
                throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
                
            }
        }
        
        return urlRequest
    }
}
