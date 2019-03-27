import Foundation
import Alamofire

enum NotificationRouter: APIConfiguration {
 
    case get(forLimit: String, offset: String)
    case delete(forId: String)
    case read(forId: String)
    case count
    var requestType: HTTPMethod {
        
        switch self {
        case .get, .count:
            return .get
        case .delete:
            return .delete
        case .read:
            return .put
        }
    }

    internal var path: String {
        switch self {
        case .get(let limit, let offset):
            return String(format: APIEndpoint.notificationList, limit, offset)
        case .delete(let forId):
            return String(format: APIEndpoint.deleteNotification, forId)
        case .read(let forId):
            return String(format: APIEndpoint.readNotification, forId)
        case .count:
            return String(format: APIEndpoint.unreadNotificationCount)
        }
        
    }
 
    var parameters: Parameters? {
        switch self {
        case .get, .delete, .count:
            return nil
        case .read(let forId):
            let notificationRead = NotificationRead(notificationIdList: [forId])
            return notificationRead.convertToDictionary(data: notificationRead.serialize())
        }
        
    }
}
