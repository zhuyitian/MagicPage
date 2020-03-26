//
//  EmptyView.swift
//  H5
//
//  Created by Oneday on 2019/11/27.
//  Copyright © 2018 Sample. All rights reserved.
//

import UIKit

class EmptyView: UIView {
    
    var retry:(()->Void)?
    
    
    lazy var tipLabel: UILabel = {
        let label = UILabel.init()
        label.text = "暂无网络\n如网络良好，请检查设置，是否允许网络访问！"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.3)
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    lazy var btn: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.backgroundColor = UIColor.init(red: 74/255, green: 153/255, blue: 207/255, alpha: 1)
        btn.layer.cornerRadius = 4
        btn.clipsToBounds = true
        btn.setTitle("重试", for: .normal)
        btn.addTarget(self, action: #selector(clickAction), for: .touchUpInside)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        creatUI()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func creatUI() {
        backgroundColor = .white
        addSubview(tipLabel)
        addSubview(btn)
        
        tipLabel.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }
        
        btn.snp.makeConstraints { (make) in
            make.top.equalTo(tipLabel.snp.bottom).offset(15)
            make.width.equalTo(200)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
        }
    }
    
    @objc func clickAction() {
        retry?()
    }
    
    
}
