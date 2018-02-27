//
//  BlePeripheral.swift
//  Scanning
//
//  Created by Adonis Gaitatzis on 12/12/16.
//  Copyright © 2016 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth


/**
 BlePeripheral Handles communication with a Bluetooth Low Energy Peripheral
 */
class BlePeripheral: NSObject, CBPeripheralDelegate {
    
    // MARK: Peripheral properties
    
    // delegate
    var delegate:BlePeripheralDelegate?
    
    // connected Peripheral
    var peripheral:CBPeripheral!
    
    // advertised name
    var advertisedName:String!
    
    // the size of the characteristic
    let characteristicLength = 20
    
    // RSSI
    var rssi:NSNumber!
    
    // GATT profile tree
    var gattProfile = [CBService]()
    
    
    /**
     Initialize BlePeripheral with a corresponding Peripheral
     
     - Parameters:
     - delegate: The BlePeripheralDelegate
     - peripheral: The discovered Peripheral
     */
    init(delegate: BlePeripheralDelegate?, peripheral: CBPeripheral) {
        super.init()
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.delegate = delegate
    }
    
    
    /**
     Notify the BlePeripheral that the peripheral has been connected
     
     - Parameters:
     - peripheral: The discovered Peripheral
     */
    func connected(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
        // check for services and the RSSI
        self.peripheral.readRSSI()
        self.peripheral.discoverServices(nil)
    }
    
    
    /**
     Get a broadcast name from an advertisementData packet.  This may be different than the actual broadcast name
     */
    static func getNameFromAdvertisementData(advertisementData: [String : Any]) -> String? {
        // grab thekCBAdvDataLocalName from the advertisementData to see if there's an alternate broadcast name
        if advertisementData["kCBAdvDataLocalName"] != nil {
            return (advertisementData["kCBAdvDataLocalName"] as! String)
        }
        return nil
    }
    
    /**
     Determine if this peripheral is connectable from it's advertisementData packet.
     */
    static func isConnectable(advertisementData: [String: Any]) -> Bool {
        let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        return isConnectable
    }
    
    
    /**
     Read from a Characteristic
     */
    func readValue(from characteristic: CBCharacteristic) {
        self.peripheral.readValue(for: characteristic)
    }
    
    /**
     Write to Characteristic
     */
    func writeValue(value: String, to characteristic: CBCharacteristic) {
        
        let byteValue = Array(value.utf8)
        
        // cap the outbound value length to be less than the characteristic length
        var length = byteValue.count
        if length > characteristicLength {
            length = characteristicLength
        }
        
        let transmissableValue = Data(Array(byteValue[0..<length]))
        
        print("transmissableValue is \(transmissableValue)")
        
        var writeType = CBCharacteristicWriteType.withResponse
        if BlePeripheral.isCharacteristic(isWriteableWithoutResponse: characteristic) {
            writeType = CBCharacteristicWriteType.withoutResponse
        }
        
        peripheral.writeValue(transmissableValue, for: characteristic, type: writeType)
        
        print("write request sent")
    }
    
    /**
     Check if Characteristic is writeable without response
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is writeable without response
     */
    static func isCharacteristic(isWriteableWithoutResponse characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            return true
        }
        return false
    }
    
    /**
     Check if Characteristic is readable
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is readable
     */
    static func isCharacteristic(isReadable characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            return true
        }
        return false
    }
    
    /**
     Check if Characteristic is writeable
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is writeable
     */
    static func isCharacteristic(isWriteable characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 ||
            (characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            return true
        }
        return false
    }
    
    // MARK: CBPeripheralDelegate
    
    
    /**
     Value downloaded from Characteristic on connected Peripheral
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let value = characteristic.value {
            
            // Note: if we need to work with byte arrays instead of Strings, we can do this
            let byteArray = [UInt8](value)
            /*print("byteArray is:")
            print(byteArray)
            print("Array length is \(byteArray.count)")*/
            delegate?.blePeripheral?(characteristicRead: byteArray, characteristic: characteristic, blePeripheral: self)
            
            // or this:
            // let byteArray:[UInt8] = Array(outboundValue.withCString)
            /*
            let intValue = value.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
                return ptr.pointee
            }
            print(intValue)
            
            let doubleValue = value.withUnsafeBytes { (ptr: UnsafePointer<Double>) -> Double in
                return ptr.pointee
            }
            print(doubleValue);
            
            
            let floatValue = value.withUnsafeBytes { (ptr: UnsafePointer<Float>) -> Float in
                return ptr.pointee
            }
            print(floatValue);
            */
            
            /*
            if let stringValue = String(data: value, encoding: .ascii) {
                
                print(stringValue)
                print(stringValue.unicodeScalars)
                
                // received response from Peripheral
                delegate?.blePeripheral?(characteristicRead: "New Value: \(byteArray[0])", characteristic: characteristic, blePeripheral: self)
                
            }
            */
 
        }
    }
    
    
    
    /**
     Servicess were discovered on the connected Peripheral
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("services discovered")
        // clear GATT profile - start with fresh services listing
        gattProfile.removeAll()
        
        if error != nil {
            print("Discover service Error: \(String(describing: error))")
        } else {
            print("Discovered Service")
            for service in peripheral.services!{
                self.peripheral.discoverCharacteristics(nil, for: service)
            }
            print(peripheral.services!)
        }
        
    }
    
    
    /**
     Characteristics were discovered for a Service on the connected Peripheral
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("characteristics discovered")
        // grab the service
        let serviceIdentifier = service.uuid.uuidString
        
        
        print("service: \(serviceIdentifier)")
        
        
        gattProfile.append(service)
        
        
        if let characteristics = service.characteristics {
            
            print("characteristics found: \(characteristics.count)")
            for characteristic in characteristics {
                print("-> \(characteristic.uuid.uuidString)")
                
            }
            
            delegate?.blePerihperal?(discoveredCharacteristics: characteristics, forService: service,blePeripheral: self)
        }
    }
    
    
    
    /**
     RSSI read from peripheral.
     */
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("RSSI: \(RSSI.stringValue)")
        rssi = RSSI
        delegate?.blePeripheral?(readRssi: rssi, blePeripheral: self)
    }
    
}
