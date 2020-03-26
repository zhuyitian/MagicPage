//
//  ConfigFile.swift
//  H5
//
//  Created by Oneday on 2019/11/27.
//  Copyright © 2018 Sample. All rights reserved.
//

import UIKit


public struct Keys {
    
    static let host = "h5Url"
    static let isVest = "status"
    static let gtid = "gtId"
    static let gtkey = "gtKey"
    static let gtsecret = "gtSecert"
    static let adjust = "adjustToken"
}

var BaseUrl: String = UserDefaults.standard.value(forKey: "baseurl") as? String ?? ""

var Mmark = "IGEZFX4Q"



let lemon_interface = "/admin/client/vestSign.do"

//MARK: - 个推配置参数
var GTAppid = ""
var GTAppSecret = ""
var GTAppkey = ""
var AdjToken = ""
var Status = ""



