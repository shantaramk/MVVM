//
//  APIErrorDetail.swift

import Foundation

struct General: Serializable {

    var general: [GeneralDetails]?
    
    enum CodingKeys: String, CodingKey {
        
        case general
    }
    
    init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        general = try values.decodeIfPresent([GeneralDetails].self, forKey: .general)
        
    }
}
