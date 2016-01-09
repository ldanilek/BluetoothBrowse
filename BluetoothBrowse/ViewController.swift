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

class ViewController: NSViewController, WebUIDelegate, WebFrameLoadDelegate, WebDownloadDelegate, WebResourceLoadDelegate, WebPolicyDelegate, BluetoothReceiverDelegate, BluetoothHotspotDelegate, NSTextFieldDelegate {
    
    var webView: WebView!
    var textField: NSTextField!
    var progressBar: NSProgressIndicator!
    
    var lastURLLoaded: String?
    var htmlLoaded: String!
    var loadingSomething = false
    
    var willLoadRootNext = false
    
    let receiver = BluetoothReceiver()
    //let hotspot = BluetoothHotspot()
    
    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        if fieldEditor.string == nil {
            print("Nil URL")
            return false
        }
        self.webView.mainFrame.loadRequest(NSURLRequest(URL: NSURL(string: fieldEditor.string!)!))
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
                self.lastURLLoaded = url
                self.resourceQueue = []
                sender.stopLoading(nil)
                if self.loadingSomething {
                    willLoadRootNext = true
                    self.resourceQueue.append(url) // load this when done loading other stuff
                } else {
                    self.loadingSomething = true
                    self.receiver.fetchDataForURL(url, root: true)
                    self.willLoadRootNext = false
                }
            }
        }
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        self.loadingSomething = false
        print("finished loading with title \(sender.mainFrameTitle)")
        self.view.window?.title = sender.mainFrameTitle
        self.loadNextResource()
    }
    
    func loadNextResource() {
        while self.resourceQueue.count > 0 && alreadyDownloaded(self.resourceQueue.last!) {
            self.resourceQueue.removeLast()
        }
        if self.resourceQueue.count == 0 {
            return
        }
        let nextResource = self.resourceQueue.removeLast()
        self.loadingSomething = true
        print("Start loading resource \(nextResource)")
        self.receiver.fetchDataForURL(nextResource, root: willLoadRootNext)
        self.willLoadRootNext = false
    }
    
    var localMappings = [String: String]()
    
    func alreadyDownloaded(url: String) -> Bool {
        if localMappings[url] == nil {
            if let filePath = self.findLocally(url) {
                if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                    localMappings[url] = filePath
                }
            }
        }
        return localMappings[url] != nil
    }
    
    var resourceQueue = [String]()
    
    func webView(sender: WebView!, resource identifier: AnyObject!, willSendRequest request: NSURLRequest!, redirectResponse: NSURLResponse!, fromDataSource dataSource: WebDataSource!) -> NSURLRequest! {
        let url = request.URL!.absoluteString
        if url != self.lastURLLoaded && alreadyDownloaded(url) {
            print("already downloaded \(url)")
        }
        if let locallyStored = localMappings[request.URL!.absoluteString] {
            let newRequest = NSURLRequest(URL: NSURL(fileURLWithPath: locallyStored))
            print("modified request \(request) into \(newRequest)")
            return newRequest
        }
        print("can modify request: \(request)")
        if url != self.lastURLLoaded {
            if !self.resourceQueue.contains(url) && !alreadyDownloaded(url) {
                self.resourceQueue.insert(request.URL!.absoluteString, atIndex: 0)
            }
        }
        return request
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
        webView.resourceLoadDelegate = self
        webView.UIDelegate = self
        self.view.addSubview(webView)
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Top, relatedBy: .Equal, toItem: self.progressBar, attribute: .Bottom, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0))
        
        //let request = NSURLRequest(URL: NSURL(string: "http://www.google.com")!)
        //self.webView.mainFrame.loadRequest(request)
    }
    
    func receiverStatusUpdate(hotspot: BluetoothReceiver, update: String) {
        //htmlBody += "<br />"+update
        //self.webView.mainFrame.loadHTMLString("<!DOCTYPE html><html><head><title>GOOGLE</title></head><body>"+htmlBody+"</body></html>", baseURL: nil)
    }
    
    func hotspotStatusUpdate(hotspot: BluetoothHotspot, update: String) {
        //htmlBody += "<br />"+update
        //self.webView.mainFrame.loadHTMLString("<!DOCTYPE html><html><head><title>GOOGLE</title></head><body>"+htmlBody+"</body></html>", baseURL: nil)
    }
    
    func findLocally(url: String) -> String? {
        let URL = NSURL(string: url)!
        if URL.pathComponents == nil {return nil}
        var mostPathComponents = URL.pathComponents!
        mostPathComponents.removeLast()
        var filePath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/BluetoothBrowseData/" + URL.host! + mostPathComponents.joinWithSeparator("/")
        
        if !NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(filePath, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print("Exception")
            }
        }
        filePath = filePath.stringByAppendingString("/"+URL.pathComponents!.last!)
        if filePath.hasSuffix("/") {
            filePath = filePath.stringByAppendingString("index.html")
        }
        return filePath
    }
    
    func dataReceived(data: NSData, url: String) {
        if url != self.lastURLLoaded {
            if let filePath = findLocally(url) {
            
                if data.writeToFile(filePath, atomically: true) {
                    print("Write to file path \(filePath) succeeded")
                    self.localMappings[url] = filePath
                } else {
                    print("Write to file path \(filePath) failed")
                }
            }
            self.webView.mainFrame.loadHTMLString(self.htmlLoaded, baseURL: NSURL(string: self.lastURLLoaded!))
        } else {
            let htmlString = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
            self.htmlLoaded = htmlString
            //htmlBody += "<br />"+htmlString
            self.webView.mainFrame.loadHTMLString(htmlString, baseURL: NSURL(string: self.lastURLLoaded!))
            print("Base url is \(url)")
        }
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

