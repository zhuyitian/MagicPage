//
//  GeTuiManager.swift
//  BlockchainInfo
//
//  Created by LTDCoinicle on 2019/2/26.
//  Copyright © 2019年 Klub. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftyJSON
import RxSwift
import FBSDKCoreKit





///收到推送跳转页面
let noti_jumpUrl = NSNotification.Name.init("jumpUrl")

class GeTuiManager: NSObject {
    
    static let geTui = GeTuiManager()
    
     func configGeTui() {

        // [ GTSdk ]：自定义渠道
        GeTuiSdk.setChannelId("GT-Channel");
        
        // [ GTSdk ]：使用APPID/APPKEY/APPSECRENT启动个推
        GeTuiSdk.start(withAppId: GTAppid, appKey: GTAppkey, appSecret: GTAppSecret, delegate: self)
        
        // 注册APNs - custom method - 开发者自定义的方法
        registerRemoteNotification();
    }
    // MARK: - 用户通知(推送) _自定义方法
    /** 注册用户通知(推送) */
    func registerRemoteNotification() {
        /*
         警告：Xcode8的需要手动开启“TARGETS -> Capabilities -> Push Notifications”
         */
        
        /*
         警告：该方法需要开发者自定义，以下代码根据APP支持的iOS系统不同，代码可以对应修改。
         以下为演示代码，仅供参考，详细说明请参考苹果开发者文档，注意根据实际需要修改，注意测试支持的iOS系统都能获取到DeviceToken。
         */
        
        if #available(iOS 10.0, *) {
            let center:UNUserNotificationCenter = UNUserNotificationCenter.current()
            center.delegate = self;
            center.requestAuthorization(options: [.alert,.badge,.sound], completionHandler: { (granted:Bool, error:Error?) -> Void in
                if (granted) {
                    print("注册通知成功") //点击允许
                } else {
                    print("注册通知失败") //点击不允许
                }
            })
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            if #available(iOS 8.0, *) {
                let userSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(userSettings)
                
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func clientID() -> String? {
        return GeTuiSdk.clientId()
    }
    //["dataId": 968304704624918529, "classify": 0, "title": 区块财经, "type": 0, "createTime": 1519716085344, "url": http://news.esongbai.abc/api/news-info/news/detail/968304704624918529, "msg": 北京时间2月27日早间消息，自称比特币发明人的克雷格·赖特（Craig Wright）被控从一位计算机安全专家那里诈骗价值50亿美元的加密货币和其他资产。]
    func jumpVC(userInfo: Dictionary<String, Any>?) {
        guard userInfo != nil else {
            return
        }
        guard userInfo?.count != 0 else {
            return
        }
        if let url = userInfo!["url"] as? String {
            if url.contains("http") {
                NotificationCenter.default.post(name: noti_jumpUrl, object: url)
            }else {
                NotificationCenter.default.post(name: noti_jumpUrl, object: "\(BaseUrl)\(url)")
            }
        }
    }
}

extension GeTuiManager: GeTuiSdkDelegate {
    
    /** SDK收到透传消息回调 */
    func geTuiSdkDidReceivePayloadData(_ payloadData: Data!, andTaskId taskId: String!, andMsgId msgId: String!, andOffLine offLine: Bool, fromGtAppId appId: String!) {
        GeTuiSdk.sendFeedbackMessage(90001, andTaskId: taskId, andMsgId: msgId)
        
        if offLine == false {
            do {
                if let dic = try JSON(data: payloadData).dictionaryObject {
                    addlocationNoti(userInfo: dic)
                }
            } catch  {
                
            }
        }
        if let payloadMsg = String.init(data: payloadData, encoding: String.Encoding.utf8) {
            
            let msg:String = "Receive Payload: \(payloadMsg), taskId:\(taskId), messageId:\(msgId)";
        }
    }
    
    func addlocationNoti(userInfo: Dictionary<String, Any>) {
        // 初始化一个通知
        let localNoti = UILocalNotification()

        // 通知上显示的主题内容
        localNoti.alertBody = userInfo["pushContent"] as? String // "通知上显示的提示内容"
        // 收到通知时播放的声音，默认消息声音
        localNoti.soundName = UILocalNotificationDefaultSoundName
        //待机界面的滑动动作提示
        localNoti.alertAction = "打开应用"
        // 应用程序图标右上角显示的消息数
        localNoti.applicationIconBadgeNumber = 0
        // 通知上绑定的其他信息，为键值对
        localNoti.userInfo = userInfo
        
        // 添加通知到系统队列中，系统会在指定的时间触发
        UIApplication.shared.scheduleLocalNotification(localNoti)
    }

}

extension GeTuiManager: UNUserNotificationCenterDelegate {
    
    //  iOS 10: App在前台获取到通知
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("willPresentNotification: %@",notification.request.content.userInfo);
        
        completionHandler([.badge,.sound,.alert]);
    }
    
    //  iOS 10: 点击通知进入App时触发，在该方法内统计有效用户点击数
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo as? Dictionary<String, Any> 
        GeTuiManager.geTui.jumpVC(userInfo: userInfo)
        // [ GTSdk ]：将收到的APNs信息传给个推统计
        GeTuiSdk.handleRemoteNotification(response.notification.request.content.userInfo);
        
        completionHandler();
    }
}

extension AppDelegate {
    // MARK: - 远程通知(推送)回调
    
    /** 远程通知注册成功委托 */
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        GeTuiSdk.registerDeviceTokenData(deviceToken)
    }
    
    /** 远程通知注册失败委托 */
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    // MARK: - APP运行中接收到通知(推送)处理 - iOS 10 以下
    
    /** APP已经接收到“远程”通知(推送) - (App运行在后台) */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        application.applicationIconBadgeNumber = 0;        // 标签
        //当APP在后台运行时，当有通知栏消息时，点击它，就会执行下面的方法跳转到相应的页面
        if UIApplication.shared.applicationState != .active {
            GeTuiManager.geTui.jumpVC(userInfo:userInfo as? Dictionary<String, Any>)
        }
    }
    
    /** APP已经接收到“远程”通知(推送) - 透传推送消息 (离线)   点击通知栏会调用这个 */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // [ GTSdk ]：将收到的APNs信息传给个推统计
        GeTuiSdk.handleRemoteNotification(userInfo);
        //当APP在后台运行时，当有通知栏消息时，点击它，就会执行下面的方法跳转到相应的页面
        if UIApplication.shared.applicationState == .inactive {
            GeTuiManager.geTui.jumpVC(userInfo:userInfo as? Dictionary<String, Any>)
        }
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if UIApplication.shared.applicationState == .inactive {
            GeTuiManager.geTui.jumpVC(userInfo:notification.userInfo as? Dictionary<String, Any>)
        }
    }
    
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        GeTuiSdk.resume()
        completionHandler(.newData)
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        GeTuiSdk.setBadge(0)
        AppEvents.activateApp()
    }
}
