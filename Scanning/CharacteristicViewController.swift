//
//  CharacteristicViewController.swift
//  ReadCharacteristic
//
//  Created by Adonis Gaitatzis on 11/22/16.
//  Copyright © 2016 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation
/*
extension FileManager {
    static var documentDirectoryURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}*/

/**
 This view talks to a Characteristic
 */
class CharacteristicViewController: UIViewController, CBCentralManagerDelegate, BlePeripheralDelegate {
    
    // MARK: UI elements
    @IBOutlet weak var advertizedNameLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var characteristicUuidlabel: UILabel!
    
    @IBOutlet weak var waveformArea: WaveformView!
    @IBOutlet weak var signal1Value: UILabel!
    @IBOutlet weak var signal2Value: UILabel!
    
    // MARK: Connected devices
    
    // Central Bluetooth Radio
    var centralManager: CBCentralManager!
    
    // Bluetooth Peripheral
    var blePeripheral: BlePeripheral!
    
    // Connected Characteristic
    var connectedService: CBService!
    
    // Connected Characteristic
    var connectedCharacteristic: CBCharacteristic!
    
    // Received Data Buffer
    var receivedData = [UInt8]()
    
    // URL for save the received Data
    /*
    let receivedDataURL = URL(
        fileURLWithPath: "receivedData",
        relativeTo: FileManager.documentDirectoryURL
    )*/
    
    /**
     UIView loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Will connect to device \(blePeripheral.peripheral.identifier.uuidString)")
        print("Will connect to characteristic \(connectedCharacteristic.uuid.uuidString)")
        
        centralManager.delegate = self
        blePeripheral.delegate = self
        
        loadUI()
        
    }
    
    @IBAction func notifyCharacteristic(_ sender: UISwitch) {
        print("notify the characteristic is \(sender.isOn)")
        blePeripheral.peripheral.setNotifyValue(sender.isOn, for: connectedCharacteristic)
        if !sender.isOn {
            // Create the Data instance
            /*
            let myData = Data(bytes: receivedData)
            print("Create the Data instance myData: \(myData)")
            // Write data to the specific directory
            do {
                try myData.write(to: receivedDataURL)
                print("Save data to URL: \(receivedDataURL)")
            } catch {
                print(error)
            }*/
        }
    }
    /**
     Load UI elements
     */
    func loadUI() {
        advertizedNameLabel.text = blePeripheral.advertisedName
        identifierLabel.text = blePeripheral.peripheral.identifier.uuidString
        characteristicUuidlabel.text = connectedCharacteristic.uuid.uuidString
    }

    
    // MARK: BlePeripheralDelegate
    
    /**
     Characteristic was read.  Update UI
     */
    func blePeripheral(characteristicRead byteArray: [UInt8], characteristic: CBCharacteristic, blePeripheral: BlePeripheral) {
    
        receivedData += byteArray
        
        for i in 1...(byteArray.count/4) {
            // Update the signal value of channel 1
            let ch1Value = Int16(byteArray[i*4-3]) << 8 + Int16(byteArray[i*4-4])
            waveformArea.pushSignal1BySliding(newValue: CGFloat(ch1Value))
            signal1Value.text = String(ch1Value)
            // Update the signal value of channel 2
            let ch2Value = Int16(byteArray[i*4-1]) << 8 + Int16(byteArray[i*4-2])
            waveformArea.pushSignal2BySliding(newValue: CGFloat(ch2Value))
            signal2Value.text = String(ch2Value)
        }
    }

    
    
    // MARK: CBCentralManagerDelegate
    
    /**
     Peripheral disconnected
     
     - Parameters:
     - central: the reference to the central
     - peripheral: the connected Peripheral
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // disconnected.  Leave
        print("disconnected")
        if let navController = navigationController {
            navController.popToRootViewController(animated: true)
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    
    /**
     Bluetooth radio state changed
     
     - Parameters:
     - central: the reference to the central
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager updated: checking state")
        
        switch (central.state) {
        case .poweredOn:
            print("bluetooth on")
        default:
            print("bluetooth unavailable")
        }
    }
    

    
    
    // MARK: - Navigation
    
    /**
     Animate the segue
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let connectedBlePeripheral = blePeripheral {
            centralManager.cancelPeripheralConnection(connectedBlePeripheral.peripheral)
        }
    }
    

}
