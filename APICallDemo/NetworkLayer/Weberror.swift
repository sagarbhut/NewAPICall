//
//  Weberror.swift
//  MagentaTogether
//

import Foundation

struct MessageResponse: Codable {
    let success: Generic?
    let message: Generic?
}

struct SuccessResponse<T: Codable>: Codable {
   
    let success: Generic?
    let message: Generic?
    let total: Generic?
    let model  : T?
   
    enum CodingKeys: String, CodingKey {
        case status, message, total
        case model = "data"
    }
    
    init(from decoder: Decoder) throws {
        let values  = try decoder.container(keyedBy: CodingKeys.self)
        success     = try values.decodeIfPresent(Generic.self, forKey: .status)
        message     = try values.decodeIfPresent(Generic.self, forKey: .message)
        total       = try values.decodeIfPresent(Generic.self, forKey: .total)
        
        if T.self is MessageResponse.Type {
            model       = MessageResponse(success: success, message: message) as? T
        }else{
            model       = try values.decodeIfPresent(T.self, forKey: .model)
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy : CodingKeys.self)
        try container.encode(success, forKey: .status)
        try container.encode(message, forKey: .message)
        try container.encode(total, forKey: .total)
        try container.encode(model, forKey: .model)
    }
}

struct ErrorResponse: Codable {
    let errorMessage : Generic?
    let errorCode   : Generic?
    
    enum CodingKeys: String, CodingKey {
        case errorMessage   = "ErrorFallbackMessage"
        case errorCode      = "ErrorCode"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        errorMessage     = try values.decodeIfPresent(Generic.self, forKey: .errorMessage)
        errorCode        = try values.decodeIfPresent(Generic.self, forKey: .errorCode)
    }
}

enum WebError: Error, Equatable  {
    case badRequest
    case noData
    case noInternet
    case hostFail
    case parseFail
    case timeout
    case unAuthorise
    case cancel
    case unknown
    case forbidden
    case noContent
    case customError(_ errorMessage: String)
    
    static let serverDefinedError = Set([204, 422, 423, 403, 401, 404, 409])
    
//    SUCCESS => 200
//    NO_CONTENT => 204
//    VALIDATION_ERROR => 422
//    OTHER_ERROR => 423
//    FORBIDDEN => 403
//    UNAUTHORIZED => 401
//    NOT_FOUND => 404
//    CONFLICT => 409
    
    init?(rawValue: Int) {
        switch rawValue {
        case 400:
            self = .badRequest
        case 401:
            self = .unAuthorise
        case 403:
            self = .forbidden
        case 404:
            self = .noData
        case 500:
            self = .hostFail
        case 204:
            self = .noContent
        default:
            self = .unknown
        }
    }
    
    var errorMessage: String {
        switch self {
        case .noData:
            return "No data found."
        case .noInternet:
            return "Network not reachable."
        case .hostFail:
            return "Failed to retrieve host."
        case .parseFail:
            return "Failed to parse data."
        case .timeout:
            return "Request timed out."
        case .unAuthorise:
            return "You are not authorised."
        case .cancel:
            return "Canceled request."
        case .unknown:
            return "Coundn't process request at the moment, please try again later."
        case .forbidden:
            return "You do not have access to requested data."
        case .badRequest:
            return "Bad network request!"
        case .noContent:
            return "No content"
        case .customError(let message):
            return message
        }
    }
}
