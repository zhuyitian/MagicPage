import Foundation
import Kingfisher

let kAdvImg = "kAdvImg"
let kAdvUrl = "kAdvUrl"

class AdManager {
    
    static let `default` = AdManager()
    
    var adTapClosure: (() -> Void)?
    
    init() {}
    
    func show() {
        if checkCahceAdvImg() == true, getCacheAdvImg() != nil {
            let adView = AdView()
            adView.show()
            adView.skipClosure = { () in
                print("跳过")
            }
            adView.endCountDownClosure = { () in
                print("倒计时结束")
            }
            adView.adTapClosure = { () in
                print("点击广告")
                let vc = UIApplication.shared.delegate?.window??.rootViewController
                vc?.present(AdH5Controller(), animated: false, completion: nil)
                
            }
        }
    }
    
    func clear() {
        clearCacheAdvImg()
        clearCacheAdvUrl()
    }
}

// MARK: - 广告图片advImg
extension AdManager {
    
    func checkCahceAdvImg() -> Bool {
        let result = ImageCache.default.imageCachedType(forKey: kAdvImg).cached
        print("本地缓存的广告图片 - \(result)")
        return result
    }
    
    func getCacheAdvImg() -> UIImage? {
        let img = ImageCache.default.retrieveImageInDiskCache(forKey: kAdvImg)
        return img
    }
    
    func storeCacheAdvImg(_ advImg: String) {
      
        if let url = URL(string: advImg) {
            ImageDownloader.default.downloadImage(with: url) { (img, error, url, data) in
                if let tempError = error {
                    print("下载广告图片错误 - \(tempError)")
                } else {
                    print("下载广告图片成功")
                    if let tempImg = img {
                        ImageCache.default.store(tempImg, forKey: kAdvImg)
                    }
                }
            }
        }
    }
    
    func clearCacheAdvImg() {
        ImageCache.default.removeImage(forKey: kAdvImg)
    }
}

// MARK: - 广告链接advUrl
extension AdManager {
    
    func checkCacheAdvUrl() -> Bool {
        let result = UserDefaults.standard.object(forKey: kAdvUrl) != nil
        print("本地缓存的广告链接 - \(result)")
        return result
    }
    
    func getCacheAdvUrl() -> URL? {
        if let advUrl = UserDefaults.standard.object(forKey: kAdvUrl) as? String {
            return URL(string: advUrl)
        }
        return nil
    }
    
    func storeCacheAdvUrl(_ advUrl: String) {
        UserDefaults.standard.set(advUrl, forKey: kAdvUrl)
        UserDefaults.standard.synchronize()
    }
    
    func clearCacheAdvUrl() {
        UserDefaults.standard.removeObject(forKey: kAdvUrl)
    }
}
