//
//  BluetoothReceiver.swift
//  BluetoothBrowse
//
//  Created by Lee on 1/8/16.
//  Copyright © 2016 Ship Shape. All rights reserved.
//

import CoreBluetooth

protocol BluetoothReceiverDelegate {
    func receiverStatusUpdate(hotspot: BluetoothReceiver, update: String)
    func dataReceived(data: NSData, url: String)
    func totalBytes(byteCount: UInt64)
    func bytesReceived(byteCount: UInt64)
}

class BluetoothReceiver: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate  {
    var centralManager: CBCentralManager!
    
    let serviceUUID = CBUUID(string: SERVICE_UUID)
    let onlineUUID = CBUUID(string: ONLINE_UUID)
    let urlUUID = CBUUID(string: URL_UUID)
    let dataUUID = CBUUID(string: DATA_UUID)
    
    var urlCharacteristic: CBCharacteristic!
    var dataCharacteristic: CBCharacteristic!
    
    var delegate: BluetoothReceiverDelegate?
    
    func status(stat: String) {
        print(stat)
        self.delegate?.receiverStatusUpdate(self, update: stat)
    }
    
    func setupBluetooth() {
        // main queue
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    func bluetoothReady() {
        self.centralManager.scanForPeripheralsWithServices([self.serviceUUID], options: nil)
        status("Scanning for peripherals")
    }
    
    var hotspot: CBPeripheral!
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        self.hotspot = peripheral
        status("Discovered peripheral \(self.hotspot.name ?? "unnamed")")
        central.stopScan()
        central.connectPeripheral(self.hotspot, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        // the argument peripheral doesn't work for some reason. don't know why.
        status("Peripheral \(hotspot.name ?? "unnamed") connected")
        hotspot.delegate = self
        hotspot.discoverServices([self.serviceUUID])
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        status("Disconnected peripheral")
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        status("Failed to connect peripheral with error \(error)")
    }
    
    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        status("Will restore state")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let e = error {
            status("Error discovering services \(e)")
        } else {
            if let service = peripheral.services?.first {
                status("Discovered services of \(peripheral.name ?? "unnamed")")
                self.hotspot.discoverCharacteristics([self.onlineUUID, self.urlUUID, self.dataUUID], forService: service)
            } else {
                status("no error, but no services")
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let e = error {
            status("Error discovering characteristics \(e)")
        } else if service.characteristics == nil {
            status("No error, but no characteristics")
        } else {
            for characteristic in service.characteristics! {
                if characteristic.UUID.isEqual(self.onlineUUID) {
                    status("Found online characteristic")
                    status("Properties are \(characteristic.properties.rawValue)")
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                } else if characteristic.UUID.isEqual(self.urlUUID) {
                    status("Found URL characteristic")
                    self.urlCharacteristic = characteristic
                } else if characteristic.UUID.isEqual(self.dataUUID) {
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    self.dataCharacteristic = characteristic
                    status("Found data characteristic")
                }
            }
        }
    }
    
    var buildingData = NSMutableData()
    var url: String?
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let data = characteristic.value {
            if characteristic.UUID.isEqual(self.onlineUUID) {
                if data.length == 8 {
                    var dataLength: UInt64 = 0
                    data.getBytes(&dataLength, length: 8)
                    self.delegate?.totalBytes(dataLength)
                } else {
                    let online = NSString(data: data, encoding: NSUTF8StringEncoding)!
                    status("Now \(online)")
                }
            } else if characteristic.UUID.isEqual(self.dataUUID) {
                //self.data.appendData(data)
                status("Fetched this much data: \(data.length)")
                if data.length == 0 {
                    self.delegate?.dataReceived(self.buildingData.copy() as! NSData, url: url!)
                    self.buildingData = NSMutableData()
                } else {
                    self.buildingData.appendData(data)
                    self.delegate?.bytesReceived(UInt64(self.buildingData.length))
                }
            } else {
                status("Updated value for characteristic: \(characteristic.value)")
            }
        } else {
            status("Updated value with no data")
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let e = error {
            status("Error subscribing: \(e)")
        } else {
            status("Subscribing succeeded")
        }
    }
    
    func fetchDataForURL(url: String) {
        status("Fetching URL")
        if self.urlCharacteristic == nil {
            status("Not connected yet")
            return
        }
        self.url = url
        self.hotspot.writeValue(url.dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: self.urlCharacteristic, type: CBCharacteristicWriteType.WithResponse)
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let e = error {
            status("Write had error \(e)")
        } else {
            status("Did write value")
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
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
