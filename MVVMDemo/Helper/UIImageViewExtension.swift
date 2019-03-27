//
//  UIImageViewExtension.swift
//  DeliveryPulse
//
//  Created by Sharad Katre on 26/02/19.
//  Copyright © 2019 Mobisoft Infotech. All rights reserved.
//

import UIKit
import SDWebImage

private var activityIndicatorAssociationKey: UInt8 = 0

let imageCache = NSCache<AnyObject, AnyObject>()

enum ImageSize {
    case original
    case thumbnail
}

extension UIImageView {
    
    func setImage(withImageId imageId: String, placeholderImage: String) {
        
        let baseURL = Environment().configuration(Plist.baseURL)
        
        let url =  String(format: "%@%@%@%@", baseURL, TenantConfig.tenantId, APIEndpoint.imageDownload, imageId)
        
        self.showActivityIndicator()
        self.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: placeholderImage), options: .retryFailed, progress: { (_, _, _) in
            
        }, completed: { (_, _, _, _) in
            self.hideActivityIndicator()
        })
    }
    
    func setImage(withImageId imageId: String, placeholderImage: UIImage, size: ImageSize) {
        
        let baseURL = Environment().configuration(Plist.baseURL)
        
        var urlString: String!
        
        if size == .thumbnail {
            urlString = String(format: "%@%@%@thumbnail_%@", baseURL, TenantConfig.tenantId, APIEndpoint.imageDownload, imageId)
        } else {
            urlString = String(format: "%@%@%@%@", baseURL, TenantConfig.tenantId, APIEndpoint.imageDownload, imageId)
        }
        cacheImage(urlString: urlString, placeholder: placeholderImage)
        /*
         self.showActivityIndicator()
         self.sd_setImage(with: URL(string: urlString), placeholderImage: placeholderImage, options: .retryFailed, progress: { (_, _, _) in
         
         }, completed: { (image, _, _, _) in
         self.hideActivityIndicator()
         }) */
    }
    
    var activityIndicator: UIActivityIndicatorView! {
        get {
            return objc_getAssociatedObject(self, &activityIndicatorAssociationKey) as? UIActivityIndicatorView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &activityIndicatorAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func showActivityIndicator() {
        
        if self.activityIndicator == nil {
            self.activityIndicator = UIActivityIndicatorView(style: .gray)
            
            self.activityIndicator.hidesWhenStopped = true
            self.activityIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
            self.activityIndicator.style = .gray
            self.activityIndicator.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
            self.activityIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            self.activityIndicator.isUserInteractionEnabled = false
            
            OperationQueue.main.addOperation({ () -> Void in
                self.addSubview(self.activityIndicator)
                self.activityIndicator.startAnimating()
            })
        }
    }
    
    func hideActivityIndicator() {
        OperationQueue.main.addOperation({ () -> Void in
            self.activityIndicator.stopAnimating()
        })
    }
    
    func cacheImage(urlString: String, placeholder: UIImage) {
        
        self.showActivityIndicator()
        
        image = nil
        
        if let imageFromCache = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = imageFromCache
             self.hideActivityIndicator()
            return
        }
        
        let urlwithPercent = urlString.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        
        var urlRequest = URLRequest(url: URL(string: urlwithPercent!)!)
        
        log.verbose(urlRequest)
        
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
        
        self.image = placeholder
        URLSession.shared.dataTask(with: urlRequest) {data, _, _ in
            if data != nil {
                DispatchQueue.main.async {
                    let imageToCache = UIImage(data: data!)
                    if imageToCache != nil {
                        imageCache.setObject(imageToCache!, forKey: urlString as AnyObject)
                        self.image = imageToCache
                    }
                     self.hideActivityIndicator()
                }
            }
            }.resume()
    }
}
