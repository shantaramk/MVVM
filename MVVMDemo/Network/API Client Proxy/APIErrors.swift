//
//  APIErrors.swift

import Foundation

struct APIErrors: Codable {
    
    var general: [GeneralDetails]?
    var numCountryCode: [GeneralDetails]?
    var sessionExpired: [GeneralDetails]?
    var email: [GeneralDetails]?
    
    enum CodingKeys: String, CodingKey {
        
        case general
        case numCountryCode = "users.invalidCountryCode"
        case sessionExpired = "main.httpSessionExpired"
        case email
    }
    
    init(from decoder: Decoder) throws {
        log.verbose(decoder.userInfo)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        general = try values.decodeIfPresent([GeneralDetails].self, forKey: .general)
        numCountryCode = try values.decodeIfPresent([GeneralDetails].self, forKey: .numCountryCode)
        sessionExpired = try values.decodeIfPresent([GeneralDetails].self, forKey: .sessionExpired)
        email = try values.decodeIfPresent([GeneralDetails].self, forKey: .email)

    }
    
    init () {
        
    }
}
