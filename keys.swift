//
//  keys.swift
//  BluetoothBrowse
//
//  Created by Lee on 1/8/16.
//  Copyright © 2016 Ship Shape. All rights reserved.
//

import Foundation

let SERVICE_UUID = "9B937226-E1F2-4983-A447-9A7B3059361A"
let ONLINE_UUID = "78E17BAE-82A2-4B13-81FE-9B71D7EF886D"
let URL_UUID = "050AB168-ED74-4B98-BBB2-C9E93E5F968E"
let DATA_UUID = "72B8C08A-1B75-4F50-B211-CEB0521E88BE"

func hasResourceSuffix(url: String) -> Bool {
    for suffix in ["js", "css", "png", "JPG"] {
        if url.hasSuffix("."+suffix) {
            return true
        }
    }
    return false
}