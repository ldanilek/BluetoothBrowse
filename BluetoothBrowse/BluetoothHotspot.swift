//
//  BluetoothPeripheral.swift
//  BluetoothBrowse
//
//  Created by Lee on 1/8/16.
//  Copyright © 2016 Ship Shape. All rights reserved.
//

import CoreBluetooth

// iPhone app is the peripheral
// see https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/AboutCoreBluetooth/Introduction.html

// specifically https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/PerformingCommonPeripheralRoleTasks/PerformingCommonPeripheralRoleTasks.html#//apple_ref/doc/uid/TP40013257-CH4-SW1

protocol BluetoothHotspotDelegate {
    func hotspotStatusUpdate(hotspot: BluetoothHotspot, update: String)
    func getHTMLForURL(url: String) // when ready, calls gotHTMLForURL(url:)
}

class BluetoothHotspot: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    
    var onlineCharacteristic: CBMutableCharacteristic!
    var urlCharacteristic: CBMutableCharacteristic!
    var dataCharacteristic: CBMutableCharacteristic!
    
    var data: NSData?
    var dataOffset = 0
    
    var service: CBMutableService!
    
    var delegate: BluetoothHotspotDelegate?
    
    func status(stat: String) {
        print(stat)
        self.delegate?.hotspotStatusUpdate(self, update: stat)
    }
    
    var onlineBool = false {
        didSet {
            let sent = self.peripheralManager.updateValue(self.amOnline, forCharacteristic: self.onlineCharacteristic, onSubscribedCentrals: nil)
            if !sent {
                status("didn't send data to new subscriber")
            }
        }
    }
    var amOnline: NSData {
        return (onlineBool ? "online" : "offline").dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    // call on startup
    func setupBluetooth() {
        // queue nil means main queue
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    // when bluetooth is ready to be used
    func bluetoothReady() {
        // broadcast whether I'm online
        let onlineUUID = CBUUID(string: ONLINE_UUID)
        let onlineProperties: CBCharacteristicProperties = .Notify
        self.onlineCharacteristic = CBMutableCharacteristic(type: onlineUUID, properties: onlineProperties, value: nil, permissions: CBAttributePermissions.Readable)
        
        let urlUUID = CBUUID(string: URL_UUID)
        self.urlCharacteristic = CBMutableCharacteristic(type: urlUUID, properties: CBCharacteristicProperties.Write, value: nil, permissions: CBAttributePermissions.Writeable)
        
        let dataUUID = CBUUID(string: DATA_UUID)
        self.dataCharacteristic = CBMutableCharacteristic(type: dataUUID, properties: [.Notify, .Read], value: nil, permissions: .Readable)
        
        let serviceUUID = CBUUID(string: SERVICE_UUID)
        
        self.service = CBMutableService(type: serviceUUID, primary: true)
        
        self.service.characteristics = [self.onlineCharacteristic, self.urlCharacteristic, self.dataCharacteristic]
        
        self.peripheralManager.addService(self.service)
        
        self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID], CBAdvertisementDataLocalNameKey: "Bluetooth Hotspot"])
        
        status("Setup bluetooth hotspot")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        if let e = error {
            status("Peripheral manager had error when adding service: \(e)")
        } else {
            status("Peripheral manager added service")
        }
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if let e = error {
            status("Peripheral manager had error when starting advertising: \(e)")
        } else {
            status("Started advertising")
        }
    }
    
    // ideas from http://stackoverflow.com/questions/19280429/reading-long-characteristic-values-using-corebluetooth
    
    var waitingToSendData = false
    var onlineToSend: NSData?
    
    // starting at offset, sends a single chunk of data. calls itself recursively if queue didn't back up
    let CHUNK_SIZE = 100 // bytes. this isn't a lot, but it may be all bluetooth can handle
    // self.data must be non-nil
    func sendChunkedData() {
        let chunkSize = min(self.CHUNK_SIZE, self.data!.length - self.dataOffset)
        let chunk = self.data!.subdataWithRange(NSMakeRange(self.dataOffset, chunkSize))
        let sent = self.peripheralManager.updateValue(chunk, forCharacteristic: self.dataCharacteristic, onSubscribedCentrals: nil)
        if sent {
            self.dataOffset += chunkSize
            status("Sent chunk of size \(chunkSize)")
            if chunkSize > 0 {
                self.sendChunkedData()
            }
        } else {
            status("Sending chunk of size \(chunkSize) failed")
            waitingToSendData = true
        }
    }
    
    func gotHTMLForURL(html: String?, url: String) {
        self.dataOffset = 0
        self.data = html?.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        let dataSize = UInt64(self.data!.length)
        let dataSizeData = NSData(bytes: [dataSize], length: 8)
        self.onlineToSend = dataSizeData
        self.sendChunkedData()
    }
    
    func fetchURL(url: String) {
        status("Fetching URL \(url)")
        self.delegate?.getHTMLForURL(url)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        if request.characteristic.UUID.isEqual(self.onlineCharacteristic.UUID) {
            if request.offset > 0 {
                peripheral.respondToRequest(request, withResult: CBATTError.InvalidOffset)
                return
            }
            request.value = self.amOnline
            peripheral.respondToRequest(request, withResult: CBATTError.Success)
        } else if request.characteristic.UUID.isEqual(self.dataCharacteristic.UUID) {
            if self.data == nil || self.data?.length == 0 {
                request.value = "<html><head><title>Not Found</title></head><body><h1>Data Lookup Failed</h1></body></html>".dataUsingEncoding(NSUTF8StringEncoding)
                peripheral.respondToRequest(request, withResult: CBATTError.Success)
                return
            }
            if request.offset > self.data!.length {
                peripheral.respondToRequest(request, withResult: CBATTError.InvalidOffset)
                return
            }
            status("Request with offset \(request.offset)")
            // respond with data
            request.value = self.data!.subdataWithRange(NSMakeRange(request.offset, self.data!.length - request.offset))
            peripheral.respondToRequest(request, withResult: CBATTError.Success)
        } else {
            peripheral.respondToRequest(request, withResult: CBATTError.AttributeNotFound)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        status("Received write request")
        // only use the last write request, which is the most recent one hopefully
        // make sure to respond with the first one though
        if let request = requests.last {
            let response = requests.first!
            if request.characteristic.UUID.isEqual(self.urlCharacteristic.UUID) {
                if request.value == nil || request.value?.length == 0 {
                    peripheral.respondToRequest(response, withResult: CBATTError.WriteNotPermitted)
                    return
                }
                self.urlCharacteristic.value = request.value
                self.fetchURL(NSString(data: request.value!, encoding: NSUTF8StringEncoding) as! String)
                peripheral.respondToRequest(response, withResult: CBATTError.Success)
            } else {
                peripheral.respondToRequest(response, withResult: CBATTError.AttributeNotFound)
            }
        } else {
            status("No requests")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        let sent = peripheral.updateValue(self.amOnline, forCharacteristic: self.onlineCharacteristic, onSubscribedCentrals: nil)
        status("Central subscribed")
        if !sent {
            status("didn't send data to new subscriber")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        status("Unsubscribed")
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        if let dataSizeData = self.onlineToSend {
            self.peripheralManager.updateValue(dataSizeData, forCharacteristic: self.onlineCharacteristic, onSubscribedCentrals: nil)
            self.onlineToSend = nil
        }
        if waitingToSendData {
            waitingToSendData = false
            self.sendChunkedData()
        }
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        
        switch (peripheral.state) {
        case .PoweredOff:
            status("CoreBluetooth BLE hardware is powered off")
            
        case .PoweredOn:
            status("CoreBluetooth BLE hardware is powered on and ready")
            bluetoothReady()
            
        case .Resetting:
            status("CoreBluetooth BLE hardware is resetting")
            
        case .Unauthorized:
            status("CoreBluetooth BLE state is unauthorized")
            
        case .Unknown:
            status("CoreBluetooth BLE state is unknown");
            
        case .Unsupported:
            status("CoreBluetooth BLE hardware is unsupported on this platform");
            
        }
    }
}
