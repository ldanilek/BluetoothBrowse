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

class ViewController: NSViewController, WebUIDelegate, WebFrameLoadDelegate, WebDownloadDelegate, WebPolicyDelegate, WebResourceLoadDelegate, BluetoothReceiverDelegate, BluetoothHotspotDelegate, NSTextFieldDelegate {
    
    var webView: WebView!
    var textField: NSTextField!
    var progressBar: NSProgressIndicator!
    
    var lastURLLoaded: String?
    
    let receiver = BluetoothReceiver()
    //let hotspot = BluetoothHotspot()
    
    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        if fieldEditor.string == nil {
            print("Nil URL")
            return false
        }
        self.receiver.fetchDataForURL(fieldEditor.string!)
        return true
    }
    
    func webView(sender: WebView!, didStartProvisionalLoadForFrame frame: WebFrame!) {
        if let url = sender?.mainFrameURL {
            print("intercepted url \"\(url)\"")
            self.textField.stringValue = url
            if url.isEmpty {
                // let it load
            } else if url == lastURLLoaded {
                //sender.stopLoading(nil)
                //sender.mainFrame.loadHTMLString(cached, baseURL: url)
                // let it load
            } else {
                sender.stopLoading(nil)
                self.receiver.fetchDataForURL(url)
            }
        }
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        print("finished loading with title \(sender.mainFrameTitle)")
        self.view.window?.title = sender.mainFrameTitle
    }
    
    let PROGRESS_MAX: UInt64 = 1000
    
    func setupWebview() {
        self.textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.delegate = self
        self.view.addSubview(textField)
        self.view.addConstraint(NSLayoutConstraint(item: self.textField, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.textField, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.textField, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.textField, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0.0, constant: 25.0))
        self.textField.lineBreakMode = NSLineBreakMode.ByTruncatingHead
        
        self.progressBar = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
        self.progressBar.indeterminate = false
        self.progressBar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(progressBar)
        self.view.addConstraint(NSLayoutConstraint(item: self.progressBar, attribute: .Top, relatedBy: .Equal, toItem: self.textField, attribute: .Bottom, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.progressBar, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.progressBar, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.progressBar, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0.0, constant: 5.0))
        self.progressBar.minValue = 0
        self.progressBar.maxValue = Double(PROGRESS_MAX)
        self.progressBar.doubleValue = 0
        
        self.webView = WebView(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        webView.frameLoadDelegate = self
        webView.downloadDelegate = self
        webView.policyDelegate = self
        webView.UIDelegate = self
        webView.resourceLoadDelegate = self
        self.view.addSubview(webView)
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Top, relatedBy: .Equal, toItem: self.progressBar, attribute: .Bottom, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0))
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.google.com")!)
        self.webView.mainFrame.loadRequest(request)
    }
    
    func receiverStatusUpdate(hotspot: BluetoothReceiver, update: String) {
        //htmlBody += "<br />"+update
        //self.webView.mainFrame.loadHTMLString("<!DOCTYPE html><html><head><title>GOOGLE</title></head><body>"+htmlBody+"</body></html>", baseURL: nil)
    }
    
    func hotspotStatusUpdate(hotspot: BluetoothHotspot, update: String) {
        //htmlBody += "<br />"+update
        //self.webView.mainFrame.loadHTMLString("<!DOCTYPE html><html><head><title>GOOGLE</title></head><body>"+htmlBody+"</body></html>", baseURL: nil)
    }
    
    func dataReceived(data: NSData, url: String) {
        let htmlString = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        self.lastURLLoaded = url
        //htmlBody += "<br />"+htmlString
        self.webView.mainFrame.loadHTMLString(htmlString, baseURL: NSURL(string: url))
    }
    
    func getHTMLForURL(url: String) {
        return
    }
    
    var totalByteCount = UInt64(0)
    func totalBytes(byteCount: UInt64) {
        self.progressBar.doubleValue = 0
        self.totalByteCount = byteCount
    }
    
    func bytesReceived(byteCount: UInt64) {
        if totalByteCount == 0 {
            totalByteCount = 1000 * byteCount
        }
        self.progressBar.doubleValue = Double(PROGRESS_MAX * byteCount / self.totalByteCount)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.receiver.delegate = self
        self.receiver.setupBluetooth()
        //self.hotspot.delegate = self
        //self.hotspot.setupBluetooth()
        
        self.setupWebview()
        
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

