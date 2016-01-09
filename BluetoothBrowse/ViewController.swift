//
//  ViewController.swift
//  BluetoothBrowse
//
//  Created by Lee Danilek on 12/24/15.
//  Copyright © 2015 Ship Shape. All rights reserved.
//

import Cocoa
import WebKit
import IOBluetoothUI
import IOBluetooth
import CoreBluetooth

class ViewController: NSViewController, WebUIDelegate, WebFrameLoadDelegate, WebDownloadDelegate, WebPolicyDelegate, WebResourceLoadDelegate {
    
    var webView: WebView!
    
    func webView(sender: WebView!, didStartProvisionalLoadForFrame frame: WebFrame!) {
        if sender.mainFrameURL.hasPrefix("http") {
            print("intercepted url \(sender.mainFrameURL)")
            sender.stopLoading(nil)
            sender.mainFrame.loadHTMLString("<!DOCTYPE html><html><head><title>GOOGLE</title></head><body>I'm Mr. Meseeks!</body></html>", baseURL: nil)
        } else {
            print("web view starting to load url \(sender.mainFrameURL)")
        }
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        print("finished loading with title \(sender.mainFrameTitle)")
        self.view.window?.title = sender.mainFrameTitle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView = WebView(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        webView.frameLoadDelegate = self
        webView.downloadDelegate = self
        webView.policyDelegate = self
        webView.UIDelegate = self
        webView.resourceLoadDelegate = self
        self.view.addSubview(webView)
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0))
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.google.com")!)
        self.webView.mainFrame.loadRequest(request)
        
        //let deviceSelector = IOBluetoothDeviceSelectorController(window: NSWindow())
        //deviceSelector.
        //IOBluetooth
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
}

