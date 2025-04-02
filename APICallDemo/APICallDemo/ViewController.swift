//
//  ViewController.swift
//  APICallDemo
//
//  Created by macbook pro on 02/04/25.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        Webservice.API.sendRequest(.login([:]), type: User.self){ [weak self] user,total in
            
            guard let self = self else { return }
            
        } failureCompletion: { [weak self] error in
            self?.showAlert(withMessage: error.errorMessage)
        }

    }


}


struct User:Codable {
    
    let userID          : Generic?
}

extension User {
    
    enum CodingKeys: String, CodingKey {
        case userID         = "user_id"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        userID           = try values.decodeIfPresent(Generic.self, forKey: .userID)
    }
}


final class Device {
    class var operatingSystem: String {
        return UIDevice.current.systemVersion
    }
    class var screenSize : CGSize {
        return UIScreen.main.bounds.size
    }
    
    class var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    class var isIphone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    class var isReachable: Bool {
        let reachable = NetworkReachabilityManager()
        return reachable?.isReachable ?? false
    }
}

extension UIViewController{
    func showAlert(withMessage message:String, withActions actions: UIAlertAction... ,withStyle style:UIAlertController.Style = .alert) {
        
        var AppDisplayName: String {return Bundle.main.infoDictionary!["CFBundleDisplayName"] as! String}
        let alert = UIAlertController(title: AppDisplayName, message: message, preferredStyle: style)
        if actions.count == 0 {
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        } else {
            for action in actions {
                alert.addAction(action)
            }
        }
        self.present(alert, animated: true, completion: nil)
    }
}

extension Data {
    static private let expectedMaxSizeInKb = 200
    func compressImageData()-> Data?{
        if count <= Data.expectedMaxSizeInKb * 1024{
            print("ALREADY COMPRESSED IMAGE DATA SIZE IS : \(sizeInKb())")
            let compressionValue : CGFloat = 1.0 //CGFloat(CGFloat(Data.expectedMaxSizeInKb) * CGFloat(1024) / CGFloat(count))
            let compressedData = UIImage(data: self as Data)!.compressImage()!.jpegData(compressionQuality: compressionValue)! as Data
            print("ORG SIZE \(count) COM SIZE \(compressedData.count)")
            return compressedData
//            return self
        }else{
            let compressionValue = CGFloat(CGFloat(Data.expectedMaxSizeInKb) * CGFloat(1024) / CGFloat(count))
            let compressedData = UIImage(data: self as Data)!.compressImage()!.jpegData(compressionQuality: compressionValue)! as Data
            print("ORG SIZE \(count) COM SIZE \(compressedData.count)")
            return compressedData
        }
    }
    private func sizeInKb()-> String{
        let countBytes = ByteCountFormatter()
        countBytes.allowedUnits = [.useKB]
        countBytes.countStyle = .file
        return countBytes.string(fromByteCount: Int64(count))
    }
}

extension UIImage {
    final func compressImage() -> UIImage? {
        // Reducing file size to a 10th
        var actualHeight: CGFloat = size.height
        var actualWidth: CGFloat = size.width
        let maxHeight: CGFloat = 1136.0
        let maxWidth: CGFloat = 640.0
        var imgRatio: CGFloat = actualWidth/actualHeight
        let maxRatio: CGFloat = maxWidth/maxHeight
        var compressionQuality: CGFloat = 0.5
        
        if actualHeight > maxHeight || actualWidth > maxWidth {
            if imgRatio < maxRatio {
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            } else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            } else {
                actualHeight = maxHeight
                actualWidth = maxWidth
                compressionQuality = 1
            }
        }
        let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        draw(in: rect)
        guard let img = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        guard let imageData = img.jpegData(compressionQuality: compressionQuality) else { return nil }
        return UIImage(data: imageData)
    }
}
