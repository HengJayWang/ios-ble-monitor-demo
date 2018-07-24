//
//  PeripheralDelegate.swift
//  FlowControl
//
//  Created by Created by HengJay on 2017/12/04.
//  Copyright © 2017 ITRI All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 BlePeripheral relays important status changes from BlePeripheral
 */
@objc protocol BlePeripheralDelegate: class {

    /**
     Characteristic was read
     
     - Parameters:
     - stringValue: the value read from the Charactersitic
     - characteristic: the Characteristic that was read
     - blePeripheral: the BlePeripheral
     */
    @objc optional func blePeripheral(characteristicRead stringValue: [UInt8], characteristic: CBCharacteristic, blePeripheral: BlePeripheral, error: Error?)

    /**
     Characteristic was write
     
     - Parameters:
     - peripheral: CBPeripheral
     - characteristic: the Characteristic that was read
     - blePeripheral: the BlePeripheral
     */
    @objc optional func blePeripheral(characteristicWrite peripheral: CBPeripheral, characteristic: CBCharacteristic, blePeripheral: BlePeripheral, error: Error?)

    /**
     Characteristics were discovered for a Service
     
     - Parameters:
     - characteristics: the Characteristic list
     - forService: the Service these Characteristics are under
     - blePeripheral: the BlePeripheral
     */
    @objc optional func blePerihperal(discoveredCharacteristics characteristics: [CBCharacteristic], forService: CBService, blePeripheral: BlePeripheral)

    /**
     RSSI was read for a Peripheral
     
     - Parameters:
     - rssi: the RSSI
     - blePeripheral: the BlePeripheral
     */
    @objc optional func blePeripheral(readRssi rssi: NSNumber, blePeripheral: BlePeripheral)
}
