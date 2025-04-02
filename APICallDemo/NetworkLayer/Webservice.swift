
import Foundation
import Alamofire
import SVProgressHUD
import UIKit

enum AFMimeType: String {
    
    case pngImage   = "image/jpeg"
    case jpegImage  = "image/png"
    case pdf        = "application/pdf"
    
    var type: String{
        switch self {
        case .pngImage,.jpegImage:
            return "0"
        case .pdf:
            return "1"
        }
    }
}

struct AFFileData {
    var fileName: String
    var keyName: String
    var mimeType: AFMimeType
    var file: Data?
    
    init(_ image: UIImage, withKey key: String,name :String = "") {
        mimeType = AFMimeType.jpegImage
        if name.isEmpty{
            fileName = UUID().uuidString + ".jpeg"
        }else{
            fileName = name
        }
        file     = image.jpegData(compressionQuality: 0.8)
        keyName  = key
    }
    
    init(_ pdf: Data, withKey key: String, name :String = "") {
        mimeType = AFMimeType.pdf
        if name.isEmpty{
            fileName = UUID().uuidString + ".pdf"
        }else{
            fileName = name
        }
        file     = pdf
        keyName  = key
    }
}

final class Webservice: Session {
    
    // MARK: - Custom header field -
    var header: HTTPHeaders = [
        "Content-Type"  : "application/json",
        "Accept"  : "application/json"
    ]
    
    static let API: Webservice = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 60
        configuration.timeoutIntervalForRequest = 60
        configuration.httpMaximumConnectionsPerHost = 20
        
        var webService = Webservice(configuration: configuration)
        return webService
    }()
    
    /// Set Bearer Token here
    /// - parameter token: string without bearer prefix for `token`
    func set(authorizeToken token: String!) {
        header.add(name: "authorization", value: "Bearer " + token)
    }
    
    /// Remove Bearer token with this method
    func removeAuthorizeToken() {
        header.remove(name: "authorization")
    }
    
    func cancelAllTasks() {
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
    }
    
    /// Send web request without form data
    /// - Parameters:
    ///   - route: URL request data enum
    ///   - type: Response Model Type (Codable)
    ///   - successCompletion: success response closure
    ///   - failureCompletion: failure response closure
    func sendRequest<T: Codable>(_ route: Router, type: T.Type,
                                 showHUD: Bool = true,
                                 successCompletion: @escaping (_ response: T,_ total: Generic) -> Void,
                                 failureCompletion: @escaping (_ failure: WebError) -> Void) {
        
        if showHUD {
            SVProgressHUD.show()
        }
        
        guard Device.isReachable == true else {
            if showHUD {
                SVProgressHUD.dismiss()
            }
            failureCompletion(.noInternet)
            return
        }
        
        let path = route.path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        var parameter = route.parameters
        
        if route.parameters == nil || route.parameters?.count == 0 {
            parameter = [:]
        }else{
            if let param = parameter {
                parameter = ["data" : param]
            }
        }
        
        var encoding: ParameterEncoding = JSONEncoding.default
        if route.method == .get {
            encoding = URLEncoding.default
        }
        
        guard let reqPath = path, let reqParam = parameter else {
            if showHUD {
                SVProgressHUD.dismiss()
            }
            failureCompletion(.badRequest)
            return
        }
        print("time = \(Date()) -- API CALLING \(route.path) WITH Parameters \(parameter ?? [:]) ")
        
        request(reqPath, method: route.method,
                parameters: reqParam,
                encoding: encoding,
                headers: header)
            .responseData { response in
                if showHUD {
                    SVProgressHUD.dismiss()
                }
                print("time = \(Date()) -- API CALLING \(route.path) -- Response: \t", String(data: response.data ?? Data(), encoding: .utf8) ?? "")
                self.parseResponse(response, router: route,type: type,
                                   successCompletion: successCompletion,
                                   failureCompletion: failureCompletion)
            }
    }
    
//    func sendMultipartRequest<T: Codable>(_ route: Router, type: T.Type,
//                                     showHUD: Bool = true,
//                                     files: [AFFileData],
//                                     successCompletion: @escaping (_ response: T,_ total: Generic) -> Void,
//                                     failureCompletion: @escaping (_ failure: WebError) -> Void) {
//            
//        if showHUD {
//            SVProgressHUD.show()
//        }
//        
//        guard Device.isReachable else {
//            if showHUD { SVProgressHUD.dismiss() }
//            failureCompletion(.noInternet)
//            return
//        }
//        
//        guard let path = route.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
//              let reqParam = route.parameters else {
//            if showHUD { SVProgressHUD.dismiss() }
//            failureCompletion(.badRequest)
//            return
//        }
//        
//        print("API CALLING \(route.path) WITH Parameters \(reqParam)")
//        
//        AF.upload(multipartFormData: { multipartData in
//            for model in files where model.file != nil {
//                if model.keyName == route.imageKey {
//                    if let data = model.file?.compressImageData() {
//                        multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
//                    }
//                }
////                    else if (model.keyName == route.documentKey || model.keyName == route.uplaodLeadDocument) {
////                    if let data = model.file {
////                        multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
////                    }
////                }
////                else if model.keyName == route.clientSignatureKey || model.keyName == route.technicianSignatureKey{
////                    if let data = model.file?.compressImageData() {
////                        multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
////                    }
////                }
////                else if model.keyName == route.quoteUploadKey || model.keyName == route.uplaodLeadImage {
////                    if let data = model.file {
////                        multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
////                    }
////                }
////                else if model.keyName == route.expenseUploadKey {
////                    
////                    if model.mimeType == .jpegImage || model.mimeType == .pngImage{
////                        if let data = model.file?.compressImageData() {
////                            multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
////                        }
////                    }else{
////                        if let data = model.file {
////                            multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
////                        }
////                    }
////                }
//            }
//            
//            if let jsonData = try? JSONSerialization.data(withJSONObject: reqParam) {
//                multipartData.append(jsonData, withName: "data")
//            }
//        }, to: path, method: route.method, headers: header)
//        .validate()
//        .responseData { response in
//            if showHUD { SVProgressHUD.dismiss() }
//            print(response)
//            self.parseResponse(response, router: route, type: type, successCompletion: successCompletion, failureCompletion: failureCompletion)
//        }
//    }

    
    func sendMultipartRequest<T: Codable>(_ route: Router, type: T.Type,
                                 showHUD: Bool = true,
                                 files: [AFFileData],
                                          successCompletion: @escaping (_ response: T,_ total: Generic) -> Void,
                                 failureCompletion: @escaping (_ failure: WebError) -> Void) {
        
        if showHUD {
            SVProgressHUD.show()
        }
        
        guard Device.isReachable == true else {
            if showHUD {
                SVProgressHUD.dismiss()
            }
            failureCompletion(.noInternet)
            return
        }

        let path = route.path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        var parameter = route.parameters
        
//        if route.parameters == nil || route.parameters?.count == 0 {
//            parameter = [:]
//        }else{
//            if let param = parameter {
//                parameter = [KEYS.API.Data : param]
//            }
//        }
        
        var encoding: ParameterEncoding = JSONEncoding.default
        if route.method == .get {
            encoding = URLEncoding.default
        }
        
        guard let reqPath = path, let reqParam = parameter else {
            if showHUD {
                SVProgressHUD.dismiss()
            }
            failureCompletion(.badRequest)
            return
        }
        
        print("API CALLING \(route.path) WITH Parameters \(parameter ?? [:])")
        
//        var imageModels = [AFFileData]()
//        if let key = route.imageKey {
//            imageModels = images.map({ AFFileData($0, withKey: key) })
//        }
        
        upload(multipartFormData: { multipartData in
            for model in files where model.file != nil {
                if model.keyName == route.imageKey {
                    if let data = model.file?.compressImageData() {
                        multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
                    }
                }
//                else if (model.keyName == route.documentKey || model.keyName == route.uplaodLeadDocument) {
//                    if let data = model.file {
//                        multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
//                    }
//                }else if model.keyName == route.clientSignatureKey || model.keyName == route.technicianSignatureKey{
//                    if let data = model.file?.compressImageData() {
//                        multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
//                    }
//                }
//                else if model.keyName == route.quoteUploadKey || model.keyName == route.uplaodLeadImage {
//                    if let data = model.file {
//                        multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
//                    }
//                }
//                else if model.keyName == route.expenseUploadKey {
//                    
//                    if model.mimeType == .jpegImage || model.mimeType == .pngImage{
//                        if let data = model.file?.compressImageData() {
//                            multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
//                        }
//                    }else{
//                        if let data = model.file {
//                            multipartData.append(data, withName: model.keyName, fileName: model.fileName, mimeType: model.mimeType.rawValue)
//                        }
//                    }
//                }
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject:reqParam) {
                multipartData.append(jsonData, withName: "data")
            }
        },
               to: reqPath,
               usingThreshold: UInt64.init(),
               method: route.method,
               headers: header)
        .responseData { response in
            if showHUD {
                SVProgressHUD.dismiss()
            }
            print(response)
            self.parseResponse(response, router: route,type: type,
                               successCompletion: successCompletion,
                               failureCompletion: failureCompletion)
        }
    }
    func sendWebRequest<T: Codable>(_ route: Router, type: T.Type,
                                    successCompletion: @escaping (_ response: T,_ total: Generic) -> Void,
                                    failureCompletion: @escaping (_ failure: WebError) -> Void) {
        
        SVProgressHUD.show()
        guard let url = URL(string: route.path) else {
            SVProgressHUD.dismiss()
            failureCompletion(.badRequest)
            return
        }
        
        request(url, method: route.method,
                parameters: route.parameters,
                encoding: URLEncoding.default)
            .responseData { response in
                    SVProgressHUD.dismiss()
                    self.parseResponse(response, router: route,type: type,
                                       successCompletion: successCompletion,
                                       failureCompletion: failureCompletion)
                }
    }
    
    private func parseResponse<T: Codable>(_ response: AFDataResponse<Data>, router: Router, type: T.Type,
                                           successCompletion: @escaping (_ response: T,_ total: Generic) -> Void,
                                           failureCompletion: @escaping (_ failure: WebError) -> Void) {

        
            
            if let statusCode = response.response?.statusCode,
               WebError.serverDefinedError.contains(statusCode){
                do{
                let succResp = try JSONDecoder().decode(SuccessResponse<MessageResponse>.self, from: try response.result.get())
                failureCompletion(.customError(succResp.message?.stringValue ?? "Some error occured"))
                return
                }catch{
                    print(error)
                }
            }
        
        
        switch response.result {
        case .success(let value):
            
            print("API RESPONSE PATH: \(router.path)  PARAMS: \(router.parameters ?? [:])")
            
            if let json = try? JSONSerialization.jsonObject(with: value, options: .mutableContainers) {
                print("JSON RESPONSE IS: \(json)")
            }else{
                print("JSON RESPONSE IS: \(String(data: value, encoding: .utf8))")
            }
           
            do{
                let resp = try JSONDecoder().decode(SuccessResponse<T>.self, from: value)
//                successCompletion(resp)
                
            }catch{
                print(error)
            }
            
            
            if let succResp = try? JSONDecoder().decode(SuccessResponse<T>.self, from: value) {
                if succResp.success?.boolValue ?? false, let model = succResp.model {
                    let total = succResp.total ?? 0
                    successCompletion(model, total)
                }else{
                    failureCompletion(.customError(succResp.message?.stringValue ?? "Some error occured"))
                }
            }else{
                do{
                    let resp = try JSONDecoder().decode(type.self, from: value)
                    successCompletion(resp, 0)
                    
                }catch{
                    print(error)
                }
                
//                if let resp = try? JSONDecoder().decode(type.self, from: value) {
//                    successCompletion(resp)
//                } else {
//                    if response.response?.statusCode == 204 {
//                        failureCompletion(.noContent)
//                    }else {
//                        failureCompletion(.unknown)
//                    }
//                }
            }
        case .failure(let error):
            print(error)
            if error._code == NSURLErrorTimedOut {
                failureCompletion(.timeout)
            } else if error._code == NSURLErrorCannotConnectToHost {
                failureCompletion(.hostFail)
            } else if error._code == NSURLErrorCancelled {
                failureCompletion(.cancel)
            } else if error._code == NSURLErrorNetworkConnectionLost {
                if Device.isReachable == true {
                    //Slow Internet connection
                } else {
                    //Internet disconnected before completion of request
                }
                failureCompletion(.noInternet)
            }  else {
                failureCompletion(.unknown)
            }
        }
    }
}
