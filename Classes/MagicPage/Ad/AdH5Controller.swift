import UIKit
import WebKit
import WebViewJavascriptBridge
import Alamofire
import RxSwift
import SnapKit
import SwifterSwift

class AdH5Controller: UIViewController {

    private let bag = DisposeBag()
    
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
    
    /// 进度条标识
    private let estimatedProgress = "estimatedProgress"
    
    private var brige: WebViewJavascriptBridge?
    
    /// 顶部stateView
    lazy var stateView: UIView = {
        let view = UIView.init()
        view.backgroundColor = .white
        return view
    }()
    /// 返回按钮
    lazy var backBtn: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.setTitle(" Ｘ   ", for: .normal)
        btn.setTitleColor(UIColor.lightGray, for: .normal)
        btn.addTarget(self, action: #selector(clickBackBtn), for: .touchUpInside)
        return btn
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
        progeress.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 2)
        progeress.progressTintColor = .white
        return progeress
    }()
    
    //MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
        creatUI()
        registPushJumpUrl()
        /// TODO: 加载本地缓存的url
        if let url = UserDefaults.standard.object(forKey: kAdvUrl) as? String {
            loadURL(url)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if statusBarIsDefault {
            return .default
        } else {
            return .lightContent
        }
    }
    
    //MARK: - Private Methods
    private func registerNativeFunctions() {
        registGetCookieFunction()
        registerSaveCookie()
        registerPushId()
        registUMStatistical()
        registerStateStyle()
        registerIsHiddenNavi()
        registerOpenUrl()
    }
}

extension AdH5Controller {
    
    private func registPushJumpUrl() {
        NotificationCenter.default.addObserver(self, selector: #selector(getPushJumpUrl(noti:)), name: noti_jumpUrl, object: nil)
    }
    
    @objc private func getPushJumpUrl(noti: Notification) {
        if let jumpUrl = noti.object as? String {
            loadURL(jumpUrl)
        }
    }
}

//MARK: - H5注册调用相关事件
extension AdH5Controller {
    
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
    ///隐藏显示导航栏
    private func registerIsHiddenNavi() {
        brige?.registerHandler("isHiddenNavi", handler: { (data, responseCallback) in
            
        })
    }
    
    /// 打开第三方
    private func registerOpenUrl() {
        brige?.registerHandler("openUrl", handler: { (data, responseCallback) in
            if let urlString = data as? String {
                print(urlString)
                if let url = URL(string: urlString) {
                    if UIApplication.shared.canOpenURL(url) == true {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: { (result) in
                            })
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    } else {
                        print("没有客户端，无法打开")
                    }
                }
            }
        })
    }
}

//MARK: - webView基本配置相关
extension AdH5Controller: UIGestureRecognizerDelegate {
    
    func config() {
        //禁用自动设置内边距
        automaticallyAdjustsScrollViewInsets = false
        //设置手势代理
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(webReload), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func creatUI() {
        
        view.backgroundColor = .white
        creatStateView()
        creatWebView()
        view.addSubview(progressView)
    }
    func creatStateView() {
        view.addSubview(stateView)
        stateView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalTo(0)
            make.height.equalTo(UIApplication.shared.statusBarFrame.height+40)
        }
        view.addSubview(backBtn)
        backBtn.snp.makeConstraints { (make) in
            make.top.equalTo(UIApplication.shared.statusBarFrame.height)
            make.leading.equalTo(15)
            make.height.equalTo(40)
            make.width.equalTo(60)
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
            let request = URLRequest.init(url: urlStr, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 10)
            webView.load(request)
        }else {
        }
    }
    
    private func reload() {
        if Double(UIDevice.current.systemVersion) ?? 0 > 9.0 , Double(UIDevice.current.systemVersion) ?? 0 < 10.0 {
            /// TODO: 加载本地缓存的url
            if let url = UserDefaults.standard.object(forKey: kAdvUrl) as? String {
                loadURL(url)
            }
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
    /// 点击返回按钮
    @objc func clickBackBtn() {
        dismiss(animated: false, completion: nil)
    }
}

//MARK: - webView代理协议相关
extension AdH5Controller: WKUIDelegate, WKNavigationDelegate {
    
    //MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.title != "undefined" {
            self.title = webView.title
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let openurl = navigationAction.request.url {
            print(openurl)
            if "\(openurl)".contains("https://itunes.apple.com") {
                UIApplication.shared.openURL(openurl)
            }else if !"\(openurl)".hasPrefix("http") {
                UIApplication.shared.openURL(openurl)
            }
            //            self.brige?.callHandler("openUrl", data: openurl)/// 测试用
        }
        decisionHandler(.allow)
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

