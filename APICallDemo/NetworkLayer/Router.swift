//
//  Router.swift
//  MagentaTogether
//

import Foundation
import Alamofire

protocol Routable {
    var path                : String { get }
    var method              : HTTPMethod { get }
    var parameters          : Parameters? { get }
    var isMessageOnly       : Bool { get }
}

extension Router {
    var isMessageOnly: Bool {
        switch self {
        case .login, .changeWorkOrderStatus:
            return false
        case .updateProfile:
            return true
        }
    }
}

enum Router: Routable {
    case login(Parameters)
    case changeWorkOrderStatus(Parameters)
    case updateProfile(Parameters)

}

extension Router {
    var path: String {
        switch self {
        case .login:
            return Environment.APIBasePath() + "login"
        case .changeWorkOrderStatus:
            return Environment.APIBasePath() + "changeWorkOrderStatus"
        case .updateProfile:
            return Environment.APIBasePath() + "updateProfile"
        }
    }
}

extension Router {
    var method: HTTPMethod {
        switch self {
        case .login, .changeWorkOrderStatus,.updateProfile:
            return .post
        }
    }
}

extension Router {
    var parameters: Parameters? {
        switch self {
        case .login(let param),
             .changeWorkOrderStatus(let param),
             .updateProfile(let param):
            return param
        }
    }
}
extension Router {
    var imageKey: String? {
        switch self {
        case .changeWorkOrderStatus:
            return "images[]"
        case .updateProfile:
            return "profile_picture"
        default:
            return nil
        }
    }
    
    //get key = let key = Router.changeWorkOrderStatus([:]).imageKey
    //let attachment = AFFileData(image, withKey: key)
    
    //Webservice.API.sendMultipartRequest(.changeWorkOrderStatus(params),
//    type: WorkOrder.self,
//    files: attachments) { [weak self]
}
