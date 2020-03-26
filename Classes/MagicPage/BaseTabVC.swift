
import UIKit
import WebKit
import WebViewJavascriptBridge
import RxSwift
import SnapKit
import Alamofire
import FBSDKShareKit
import Adjust
import AdSupport
import GoogleSignIn
import FBSDKCoreKit
import Branch


class BaseTabVC: UIViewController, GIDSignInDelegate {

    deinit {
        if webView.uiDelegate != nil {
            webView.scrollView.delegate = nil
            webView.uiDelegate = nil
            webView.navigationDelegate = nil
            webView.configuration.userContentController.removeAllUserScripts()
            webView.removeObserver(self, forKeyPath: estimatedProgress)
        }
        NotificationCenter.default.removeObserver(self)            
    }
    
    var statusBarIsDefault: Bool = true {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    let bag = DisposeBag()
    
    var isInContry: Bool = true
    
    //邀请码
    var inviteCode = ""
    //域名
    var domainUrl = ""
    
    var serviceStr : String = ""
    var sign: String = ""
    var host: String = ""
    var GID_clientID = ""
    /// 进度条标识
    private let estimatedProgress = "estimatedProgress"

    private var brige: WebViewJavascriptBridge?
    
    /// 顶部stateView
    lazy var stateView: UIView = {
        let view = UIView.init()
        view.backgroundColor = .white
        return view
    }()
    /// webView
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        ///允许在线播放
        config.allowsInlineMediaPlayback = true
        let web = WKWebView.init(frame: .zero, configuration: config)
        return web
    }()
    /// 进度条
    lazy var progressView: UIProgressView = {
        let progeress = UIProgressView.init(progressViewStyle: UIProgressView.Style.default)
        progeress.frame = CGRect.init(x: 0, y: 0, width: screenWidth, height: 2)
        progeress.progressTintColor = .yellow
        return progeress
    }()
    /// 空白页
    lazy var emptyView: EmptyView = {
        let view = EmptyView.init(frame: CGRect.init(x: 0, y: 0, width: screenWidth, height: screenHeight))
        view.retry = {[weak self] () in
            self?.getHost()
        }
        return view
    }()
    private func setUserAgent() {
        webView.evaluateJavaScript("navigator.userAgent") { [weak self] (res, err) in
            var uaStr = res as? String
            guard uaStr != nil else { return }
            uaStr = "IOS_AGENT/2.0\(uaStr ?? "")"
            UserDefaults.standard.register(defaults: ["UserAgent" : uaStr ?? "IOS_AGENT/2.0"])
            UserDefaults.standard.synchronize()
            self?.webView.customUserAgent = uaStr
            self?.loadURL(BaseUrl)
        }
    }
    init(vHost: String, vCode: String, gId: String) {
        serviceStr = vHost
        Mmark = vCode
        GID_clientID = gId
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if !GID_clientID.isEmpty {
            gidConfig()
        }
        registPushJumpUrl()
        config()
        creatUI()
        getHost()
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if statusBarIsDefault {
            if #available(iOS 13.0, *) {
                return .darkContent
            } else {
                return .default
            }
        } else {
            return .lightContent
        }
    }
    //MARK: - Private Methods
    private func registerNativeFunctions() {
        registGetCookieFunction()
        registerSaveCookie()
        registerPushId()
        registerStateStyle()
        registUMStatistical()
        registerWhatsAppShare()
        registerFacebookShare()
        registWhatsappChat()
        registerGetIDFA()
        registerGetIDFV()
        registPayAction()
        registGIDLOGIN()
    }
}
//MARK: - 请求域名
extension BaseTabVC {
    private func jumpMark1 (data : [String : Any]) {
        BaseUrl = data["h5Url"] as? String ?? ""
        UserDefaults.standard.set(BaseUrl, forKey: "baseurl")//必须存一下url,推送会用
        GTAppid = data[Keys.gtid] as? String ?? ""
        GTAppkey = data[Keys.gtkey] as? String ?? ""
        GTAppSecret = data[Keys.gtsecret] as? String ?? ""
        GeTuiManager.geTui.configGeTui()
        AdjToken = data[Keys.adjust] as? String ?? ""
        if AdjToken.isEmpty {} else {
            let adj = ADJConfig.init(appToken: AdjToken, environment: ADJEnvironmentProduction)
            Adjust.appDidLaunch(adj)
        }
        if data["fieldCol"] as? String == "black" {
            statusBarIsDefault = true
        } else if data["fieldCol"] as? String == "white" {
            statusBarIsDefault = false
        } else {
            statusBarIsDefault = true
        }
        if let bgcolor = data["backgroundCol"] as? String {
            stateView.backgroundColor = UIColor.init(hexString: bgcolor)
        }
        let advOn = data["advOn"] as? Int
        let adManager = AdManager.default
        /// 0 关闭，1 开启
        if advOn == 1 {
            if let advImg = data["advImg"] as? String, advImg.count != 0 {
                adManager.storeCacheAdvImg(advImg)
            } else {
                adManager.clearCacheAdvImg()
            }
            if let advUrl = data["advUrl"] as? String, advUrl.count != 0 {
                adManager.storeCacheAdvUrl(advUrl)
            } else {
                adManager.clearCacheAdvUrl()
            }
        } else {
            adManager.clear()
        }
        adManager.show()
        setUserAgent()
        for view in (self.view.subviews) {
            if view is EmptyView {
                view.removeFromSuperview()
            }
        }
    }
    private func getHost() {
        let device = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let infoDictionary = Bundle.main.infoDictionary!
        let ver = infoDictionary["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let timestamp = Date.init().timeIntervalSince1970
        let requestDic = [
            "vestCode" : Mmark,
            "channelCode" : "iOS",
            "version" : ver,
            "deviceId" : device,
            "timestamp": timestamp
            ] as [String : Any]
        let lemonUrl = String.init(format: "%@%@", serviceStr,lemon_interface)
        Alamofire.request(lemonUrl, method: .get, parameters: requestDic, encoding: URLEncoding.default, headers: nil).responseJSON {[weak self] (response) in
            if response.result.error == nil {
                if let reslut = response.result.value as? [String: Any] {
                    if let data = reslut["data"] as? [String : Any]  {
                        if data[Keys.isVest] as? Int == 0 {
                            self?.jumpMark1(data: data)
                        } else {
                            BaseUrl = data["h5Url"] as? String ?? ""
                            self?.loadURL(BaseUrl)
                            for view in (self?.view.subviews ?? [UIView]()) {
                                if view is EmptyView {
                                    view.removeFromSuperview()
                                }
                            }
                        }
                    }
                }
            } else {
                self?.view.addSubview(self?.emptyView ?? EmptyView())
            }
        }
    }
    private func registPushJumpUrl() {
        NotificationCenter.default.addObserver(self, selector: #selector(getPushJumpUrl(noti:)), name: noti_jumpUrl, object: nil)
    }
    @objc private func getPushJumpUrl(noti: Notification) {
        if let jumpUrl = noti.object as? String {
            loadURL(jumpUrl)
        }
    }
}
extension BaseTabVC {
    //gugedenglu
    private func registGIDLOGIN() {
        brige?.registerHandler("openGoogle", handler: { (data, responseCallback) in
            if let dic: [String : String] = data as? [String : String] {
                self.sign = "\(dic["sign"] ?? "")"
                self.host = "\(dic["host"] ?? "")"
                GIDSignIn.sharedInstance()?.signIn()
            }
        })
    }
    
    func gidConfig() {
        GIDSignIn.sharedInstance()?.clientID = GID_clientID
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            let dic = [
                "id": "\(user.userID ?? "")",
                "name": "\(user.profile.name ?? "")",
                "sign": "\(self.sign )"
                ] as [String : String]
            Alamofire.request("\(self.host)/user/google/doLogin2.do", method: .get, parameters: dic, encoding: URLEncoding.default, headers: nil).responseJSON {[weak self] (response) in
                if response.result.error == nil {
                    if let reslut = response.result.value as? [String: Any] {
                        if let data = reslut["data"] as? [String: Any] {
                            if let url = data["url"] as? String {
                                let token1 = "\(data["token1"] ?? "")"
                                let token2 = "\(data["token2"] ?? "")"
                                if !token1.isEmpty, !token2.isEmpty {
                                    let dic = [
                                        "token1": token1,
                                        "token2": token2
                                    ]
                                    UserDefaults.standard.set(dic, forKey: "WKWebViewKCookieKey")
                                    UserDefaults.standard.synchronize()
                                }
                                self?.loadURL(url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
                                
                            }
                        }
                    }
                }
            }
        } else {
          print("\(error.localizedDescription)")
        }
    }
}
//MARK: - H5注册调用相关事件
extension BaseTabVC: SharingDelegate {
    
    //分享成功调用后台接口
    func shareSuccess(type: String) {
        let dic = [
            "inviteCode": inviteCode,
            "type": type
        ]
        Alamofire.request("\(domainUrl)/user/userTask/dailyFaceAndWhats.do", method: .get, parameters: dic, encoding: URLEncoding.default, headers: nil).responseJSON {[weak self] (response) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self?.webView.reload()
            }
        }
    }
    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        //成功调接口
        shareSuccess(type: "1")
    }
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        //失败调接口
    }
    func sharerDidCancel(_ sharer: Sharing) {
        //取消调接口
    }
    /// 获取idfa
    private func registerGetIDFA() {
        brige?.registerHandler("getIDFA", handler: { (data, responseCallback) in
            let IDFA = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            responseCallback?(IDFA)
        })
    }
    ///获取idfv
    private func registerGetIDFV() {
        brige?.registerHandler("getIDFV", handler: { (data, responseCallback) in
            let idfv = UIDevice.current.identifierForVendor?.uuidString
            responseCallback?(idfv)
        })
    }
    
    private func registUMStatistical() {
        brige?.registerHandler("umConfig", handler: { (data, responseCallback) in
            if let event = data as? String {
                responseCallback?(event)
            }
        })
    }
    private func registGetCookieFunction() {
        brige?.registerHandler("getCookie", handler: { (data, responseCallback) in
            let cookie = UserDefaults.standard.value(forKey: "WKWebViewKCookieKey")
            responseCallback?(cookie)
        })
    }
    private func registerSaveCookie() {
        brige?.registerHandler("saveCookie", handler: { (data, responseCallback) in
            if let cookie = data {
                UserDefaults.standard.set(cookie, forKey: "WKWebViewKCookieKey")
                UserDefaults.standard.synchronize()
            }
        })
    }
    private func registerPushId() {
        brige?.registerHandler("getPushId", handler: { (data, responseCallback) in
            responseCallback?(GeTuiSdk.clientId())
        })
    }
    ///设置状态栏字体颜色
    private func registerStateStyle() {
        brige?.registerHandler("setStateColor", handler: {[weak self] (data, responseCallback) in
            if let color = data as? String {
                if color == "black" {
                    self?.statusBarIsDefault = true
                } else if color == "white" {
                    self?.statusBarIsDefault = false
                }
            }
        })
    }
    
    ///whatsapp联系客服
    private func registWhatsappChat() {
        brige?.registerHandler("openURL", handler: { (data, responseCallback) in
            if let content = data as? String {
                let url = URL.init(string: "\(content)")
                if UIApplication.shared.canOpenURL(url!) {
                    UIApplication.shared.open(url!, options: [:]) { (finish) in }
                } else {
                    responseCallback?("You haven't installed this app yet.")
                }
            }
        })
    }
    ///whatsapp分享
    private func registerWhatsAppShare() {
        brige?.registerHandler("shareWhatsapp", handler: {[weak self] (data, responseCallback) in
            if let dic = data as? [String : String] {
                let content = dic["content"] ?? ""
                self?.inviteCode = dic["inviteCode"] ?? ""
                self?.domainUrl = dic["domainUrl"] ?? ""
                self?.shareSuccess(type: "2")
                let bodyurl = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                let hosturl = URL.init(string: "whatsapp://send?text=\(bodyurl!)")
                if UIApplication.shared.canOpenURL(hosturl!) {
                    UIApplication.shared.open(hosturl!, options: [:]) { (finish) in }
                } else {
                    responseCallback?("You haven't installed this app yet.")
                }
            }
        })
    }
    ///facebook分享
    private func registerFacebookShare() {
        brige?.registerHandler("shareFacebook", handler: {[weak self] (data, responseCallback) in
            if let dic = data as? [String: String] {
                self?.shareFacebookAction(dic)
            }
        })
    }

    private func shareFacebookAction(_ data: [String : String]) {
        let url = data["url"] ?? ""
        let content = data["content"] ?? ""
        inviteCode = data["inviteCode"] ?? ""
        domainUrl = data["domainUrl"] ?? ""
        shareLinkToFacebook(url: url, quote: content)
    }
    func shareLinkToFacebook(url: String?, quote: String?) {
        let content = ShareLinkContent.init()
        content.contentURL = URL.init(string: url ?? "") ?? URL.init(fileURLWithPath: "")
        content.quote = quote
        let dialog = ShareDialog.init(fromViewController: self, content: content, delegate: self)
        dialog.show()
    }
    private func registPayAction() {
        brige?.registerHandler("jumpPay", handler: {[weak self] (data, responseCallback) in
            if let dic = data as? [String : String] {
                self?.tokenFetched(textToken: dic["textToken"] ?? "", orderId: dic["orderId"] ?? "", mid: dic["mid"] ?? "", amount: dic["amount"] ?? "")
            }
        })
    }
    func tokenFetched(textToken: String, orderId: String, mid: String, amount: String) {
        if let payUrl = URL.init(string: "paytm://merchantpayment?txnToken=\(textToken)&orderId=\(orderId)&mid=\(mid)&amount=\(amount)") {
            if UIApplication.shared.canOpenURL(payUrl) {
                UIApplication.shared.open(payUrl, options: [:]) { (finish) in

                }
            } else {
                let dic = ["txnToken": textToken, "ORDER_ID": orderId, "MID": mid]
                UIApplication.shared.open(URL.init(string: "https://securegw.paytm.in/theia/api/v1/showPaymentPage?mid=\(mid)&orderId=\(orderId)&txnToken=\(textToken)")!, options: dic) { (finish) in
                }
            }
        }
    }
}

//MARK: - webView基本配置相关
extension BaseTabVC: UIGestureRecognizerDelegate {
    
    func config() {
        //禁用自动设置内边距
        automaticallyAdjustsScrollViewInsets = false
        //设置手势代理
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(webReload), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    func creatUI() {
        creatStateView()
        creatWebView()
        view.addSubview(progressView)
    }
    func creatStateView() {
        view.addSubview(stateView)
        stateView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalTo(0)
            make.height.equalTo(statuesHeight)
        }
    }
    private func creatWebView() {
        brige = WebViewJavascriptBridge.init(webView)
        webView.uiDelegate = self
        brige?.setWebViewDelegate(self)
        webView.backgroundColor = .white
        webView.addObserver(self, forKeyPath: estimatedProgress, options: NSKeyValueObservingOptions.new, context: nil)
        registerNativeFunctions()
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.leading.bottom.trailing.equalTo(0)
            make.top.equalTo(stateView.snp.bottom)
        }
    }
    /// 加载h5
    func loadURL(_ url: String) {
        if let urlStr = URL.init(string: url) {
            let request = URLRequest.init(url: urlStr, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
            webView.load(request)
        }else {
        }
    }
    private func reload() {
        if Double(UIDevice.current.systemVersion) ?? 0 > 9.0 , Double(UIDevice.current.systemVersion) ?? 0 < 10.0 {
            loadURL(BaseUrl)
        }else {
            webView.reload()
        }
    }
    ///OC里有这个。直接翻译过来的。不知道是不是原本需求
    @objc private func webReload() {
        webView.evaluateJavaScript("webViewCallUp()", completionHandler: { (result, error) in
            if error != nil {
            }
        })
    }
    @objc private func rightswipe(_ sender: UIButton) {
        webView.scrollView.scrollsToTop = false;
        webView.goBack()
    }
    
    /// 重写系统侧滑返回，解决wk在9.x版本可能出现的侧滑返回加载延迟问题
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        reload()
        return true
    }
    
    /// KVO监听更新进度条
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == estimatedProgress {
            if let obj = object as? WKWebView, obj == webView {
                progressView.alpha = 1
                progressView.setProgress(Float(webView.estimatedProgress), animated: true)
                if webView.estimatedProgress >= 1.0 {
                    UIView.animate(withDuration: 0.3, delay: 0.3, options: UIView.AnimationOptions.curveEaseOut, animations: { [weak self] () in
                        self?.progressView.alpha = 0
                        }, completion: {[weak self] (finish) in
                            self?.progressView.setProgress(0, animated: true)
                    })
                }
            }
        }
    }
    
}

//MARK: - webView代理协议相关
extension BaseTabVC: WKUIDelegate, WKNavigationDelegate {
    
    //MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.title != "undefined" {
            self.title = webView.title
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let openurl = navigationAction.request.url {
            if ("\(openurl)".hasPrefix("https://itunes.apple.com")) || (!"\(openurl)".hasPrefix("http")) {
                UIApplication.shared.open(openurl, options: [:]) { (finish) in }
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let card = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, card)
        }
    }
    
    //MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController.init(title: "提示", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction.init(title: "确认", style: UIAlertAction.Style.default, handler: { (action) in
            completionHandler()
        }))
        present(alert, animated: true, completion: nil)
        
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController.init(title: "提示", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction.init(title: "取消", style: UIAlertAction.Style.cancel, handler: { (action) in
            completionHandler(false)
        }))
        alert.addAction(UIAlertAction.init(title: "确认", style: UIAlertAction.Style.default, handler: { (action) in
            completionHandler(true)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController.init(title: prompt, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { (textField) in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction.init(title: "完成", style: UIAlertAction.Style.default, handler: { (action) in
            completionHandler(alert.textFields?.first?.text)
        }))
        present(alert, animated: true, completion: nil)
    }
    
}


enum KlubScreenSize {
    case retain_3_5
    case retain_4
    case retain_4_7
    case retain_5_5
    case retain_5_8
    case unknow
    
    static func size() -> (width: CGFloat, height: CGFloat) {
        let _height = UIScreen.main.bounds.height
        let _width  = UIScreen.main.bounds.width
        let width   = min(_height, _width)
        let height   = max(_height, _width)
        return (width, height)
    }
    
    init() {
        let width  = KlubScreenSize.size().width
        let height = KlubScreenSize.size().height
        if width == 320 && height == 480 {
            self = .retain_3_5
        }else if width == 320 && height == 568 {
            self = .retain_4
        }else if width == 375 && height == 667 {
            self = .retain_4_7
        }else if width == 414 && height == 736 {
            self = .retain_5_5
        }else if width == 375 && height >= 812 {
            self = .retain_5_8
        }else {
            self = .retain_5_8
        }
    }
}
let screenWidth   = KlubScreenSize.size().width
let screenHeight  = KlubScreenSize.size().height
let isIphoneX = (KlubScreenSize.init() == .retain_5_8)
let statuesHeight = UIApplication.shared.statusBarFrame.size.height

struct KlubPlatform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
        isSim = true
        #endif
        return isSim
    }()
}


extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Branch.getInstance().application(app, open: url, options: options)
        ApplicationDelegate.shared.application(app, open: url, options: options)
        GIDSignIn.sharedInstance()?.handle(url)
        return true
    }
}
