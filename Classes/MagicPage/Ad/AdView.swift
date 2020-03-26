import UIKit

class AdView: UIView {

    typealias JRAdTapClosure = () -> Void
    typealias JRSkipClosure = () -> Void
    typealias JREndCountDownClosure = () -> Void
    
    private var timer: DispatchSourceTimer?
    private var waitTime: Int = 5
    var adTapClosure: JRAdTapClosure?
    var skipClosure: JRSkipClosure?
    var endCountDownClosure: JREndCountDownClosure?
    
    private lazy var adImageView: UIImageView = {
        let imageView = UIImageView(frame: self.bounds)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = AdManager.default.getCacheAdvImg()
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(ad))
        imageView.addGestureRecognizer(tapGR)
        return imageView
    }()
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: screenWidth - 70, y: UIScreen.statusBarHeight+20, width: 60, height: 30)
        button.setTitle("\(waitTime) 跳过", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13.scale)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.backgroundColor = UIColor(white: 0, alpha: 0.3)
        button.addTarget(self, action: #selector(skip), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        setupsUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit - \(type(of:self))")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        setupsTimer()
    }
}

extension AdView {

    func show() {
        UIApplication.shared.delegate?.window??.addSubview(self)
    }
    
    func remove() {
        if timer?.isCancelled == false { timer?.cancel() }
        self.removeFromSuperview()
    }
}

private extension AdView {

    func setupsUI() {
        backgroundColor = .white
        addSubview(adImageView)
        addSubview(skipButton)
    }
    
    func setupsTimer() {
        var duration: Int = waitTime
        timer = DispatchSource.makeTimerSource(flags: [], queue: .global())
        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(duration))
        timer?.setEventHandler {
            if duration == 0 {
                DispatchQueue.main.async {
                    self.remove()
                    self.endCountDownClosure?()
                }
            }
            duration -= 1
            DispatchQueue.main.async {
                self.skipButton.setTitle("\(duration) 跳过", for: .normal)
            }
        }
        timer?.resume()
    }
    
    @objc func skip() {
        remove()
        skipClosure?()
    }
    
    @objc func ad() {
        let adManager = AdManager.default
        if adManager.checkCacheAdvUrl() == true, adManager.getCacheAdvUrl() != nil {
            remove()
            adTapClosure?()
        }
    }
}
