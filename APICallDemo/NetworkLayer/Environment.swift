//
//  Environment.swift
//  MagentaTogether
//
//note: make sure for environmentURL while live or staging
import Foundation
enum Server {
    case developement
    case release
    case master
}

class Environment {
    #if DEVELOPMENT
    static let server:Server = .developement
    #elseif RELEASE
    static let server:Server = .release
    #elseif MASTER
    static let server:Server = .master
    #else
    static let server:Server = .master
    #endif
    
    static let debug : Bool = true
    
    static let devURL           = "http://stagingwebapp.linkservicepro.com/api/"
    static let releaseURL       = "http://webapp.linkservicepro.com/api/"
    static let masterURL        = "http://stagingwebapp.linkservicepro.com/api/"

    class func APIBasePath() -> String {
        switch self.server {
        case .developement:
            return devURL
        case .release:
            return devURL
        case .master:
            return devURL
        }
    }
}
