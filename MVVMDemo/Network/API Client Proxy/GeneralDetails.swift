//
//  GeneralDetails.swift
//  DeliveryPulse
//
//  Created by Sharad Katre on 20/02/19.
//  Copyright © 2019 Mobisoft Infotech. All rights reserved.
//

import Foundation

struct GeneralDetails: Serializable {
    
    var messageCode: String?
    var message: String?
    
    enum CodingKeys: String, CodingKey {
        
        case messageCode
        case message
    }
    
    init() {
        
    }
    
    init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        messageCode = try values.decodeIfPresent(String.self, forKey: .messageCode)
        
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(messageCode, forKey: .messageCode)
        try container.encode(message, forKey: .message)
    }
}
