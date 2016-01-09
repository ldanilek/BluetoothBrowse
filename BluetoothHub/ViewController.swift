//
//  ViewController.swift
//  BluetoothHub
//
//  Created by Lee on 1/8/16.
//  Copyright © 2016 Ship Shape. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, BluetoothHotspotDelegate, BluetoothReceiverDelegate, UIWebViewDelegate {
    @IBOutlet weak var statusLabel: UITextView!
    @IBOutlet weak var webView: UIWebView!
    
    var hotspot = BluetoothHotspot()
    //var receiver = BluetoothReceiver()
    
    func hotspotStatusUpdate(hotspot: BluetoothHotspot, update: String) {
        self.statusLabel.text! += "\n"+update
    }
    
    func bytesReceived(byteCount: UInt64) {
        
    }
    
    func totalBytes(byteCount: UInt64) {
        
    }
    
    func receiverStatusUpdate(hotspot: BluetoothReceiver, update: String) {
        self.statusLabel.text! += "\n"+update
    }
    
    func dataReceived(data: NSData, url: String) {
        
    }
    
    func getHTMLForURL(url: String) {
        self.webView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let html = "<!DOCTYPE html><html>" + (webView.stringByEvaluatingJavaScriptFromString("document.head.outerHTML") ?? "") + (webView.stringByEvaluatingJavaScriptFromString("document.body.outerHTML") ?? "") + "</html>"
        self.hotspot.gotHTMLForURL(html, url: webView.request!.URL!.absoluteString)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.hotspot.delegate = self
        self.hotspot.setupBluetooth()
        //self.receiver.delegate = self
        //self.receiver.setupBluetooth()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

