import Foundation
import UIKit

extension UIScreen {
    
    /// 屏幕显示内容的高度
    public static var screenActHeight: CGFloat {
        return UIScreen.screenHeight - UIScreen.navigationBarHeight - UIScreen.tabBarHeight
    }
    
    /// 屏幕宽度
    public static var screenWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    /// 屏幕高度
    public static var screenHeight: CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    /// 状态栏高度
    public static var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height
    }
    
    /// 导航栏高度（包括状态栏）
    public static var navigationBarHeight: CGFloat {
        return UIScreen.statusBarHeight + 44.0
    }
    
    /// 底部指示器高度
    public static var indicatorHeight: CGFloat {
        if #available(iOS 11.0, *) {
            if let keyWindow = UIApplication.shared.keyWindow {
                return keyWindow.safeAreaInsets.bottom
            } else {
                return CGFloat(0.0)
            }
        } else {
            return CGFloat(0.0)
        }
    }
    
    /// 标签栏（包括指示器高度）
    public static var tabBarHeight: CGFloat {
        return UIScreen.indicatorHeight + 49.0
    }
    
    /// 以iPhone6的尺寸为标准适配
    public static func screenScaleWidth(width: CGFloat) -> CGFloat {
        return (UIScreen.screenWidth/375.0)*width
    }
    
    public static func screenScaleHeight(height: CGFloat) -> CGFloat {
        return (UIScreen.screenHeight/667.0)*height
    }
    
    public static var screenScale: CGFloat {
        return UIScreen.screenWidth/375.0
    }
}

extension UIScreen {
    
    enum ZJJNPZCoinCommunityScreenSize {
        case retain35
        case retain4
        case retain47
        case retain55
        case retain58
        case retain61
        case retain65
        case unknow
        
        static func size() -> (width: CGFloat, height: CGFloat) {
            let height  = UIScreen.main.bounds.height
            let width   = UIScreen.main.bounds.width
            let minWidth   = min(height, width)
            let maxHeight  = max(height, width)
            return (minWidth, maxHeight)
        }
        
        init() {
            let width  = ZJJNPZCoinCommunityScreenSize.size().width*UIScreen.main.scale
            let height = ZJJNPZCoinCommunityScreenSize.size().height*UIScreen.main.scale
            if width == 640 && height == 960 {
                self = .retain35
            } else if width == 640 && height == 1136 {
                self = .retain4
            } else if width == 750 && height == 1334 {
                self = .retain47
            } else if width == 1242 && height == 2208 {
                self = .retain55
            } else if width == 1125 && height == 2436 {
                self = .retain58
            } else if width == 828 && height == 1792 {
                self = .retain61
            } else if width == 1242 && height == 2688 {
                self = .retain65
            } else {
                self = .unknow
            }
        }
    }
}
