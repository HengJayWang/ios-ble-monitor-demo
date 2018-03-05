//
//  GattTableViewCell.swift
//  Services
//
//  Created by Created by HengJay on 2017/12/04.
//  Copyright © 2017 ITRI All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 Peripheral Table View Cell
 */
class PeripheralTableViewCell: UITableViewCell {
    
    // MARK: UI elements
    @IBOutlet weak var advertisedNameLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    /**
     Render Cell with Peripheral properties
     */
    func renderPeripheral(_ blePeripheral: BlePeripheral) {
        advertisedNameLabel.text = blePeripheral.advertisedName
        identifierLabel.text = blePeripheral.peripheral.identifier.uuidString
        rssiLabel.text = blePeripheral.rssi.stringValue
        
    }
    
    
}
