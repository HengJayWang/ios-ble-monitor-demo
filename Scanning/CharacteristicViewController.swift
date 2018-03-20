//
//  CharacteristicViewController.swift
//  ReadCharacteristic
//
//  Created by Created by Created by HengJay on 2017/12/04.
//  Copyright © 2017 ITRI All rights reserved.
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
    @IBOutlet weak var writeCharacteristicButton: UIButton!
    @IBOutlet weak var writeCharacteristicTextField: UITextField!
    
    @IBOutlet weak var accelerXLabel: UILabel!
    
    @IBOutlet weak var accelerYLabel: UILabel!
    
    @IBOutlet weak var accelerZLabel: UILabel!
    
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
    //var receivedData = [UInt8]()
    
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
        
    }
    /**
     Load UI elements
     */
    func loadUI() {
        advertizedNameLabel.text = blePeripheral.advertisedName
        identifierLabel.text = blePeripheral.peripheral.identifier.uuidString
        characteristicUuidlabel.text = connectedCharacteristic.uuid.uuidString
        
        // characteristic is not writeable
        if !BlePeripheral.isCharacteristic(isWriteable: connectedCharacteristic) {
            writeCharacteristicTextField.isHidden = true
            writeCharacteristicButton.isHidden = true
        }
        
    }

    let header : UInt32 = 0x49545249
    let cmdType : [UInt16] = [0xAB01, 0xAB02, 0xAB03, 0xAB04, 0xAB05, 0xAB06, 0xAB07]
    var cmdData : [Bool] = [false, false, false, false, false, false, false]
    let comment = "FFFFFFFF"
    var lastPressBtn : Int = 0
    
    @IBAction func writeCharacteristic(_ sender: UIButton) {
        print("write button pressed")
        writeCharacteristicButton.isEnabled = false
       
        let stringValue = generateCommandString()
        print("stringValue is \(stringValue)")
        blePeripheral.writeValue(value: stringValue, to: connectedCharacteristic)
        writeCharacteristicTextField.text = ""
        
        writeCharacteristicButton.isEnabled = true
    }
    
    // Generate the command string by bigEndian.
    func generateCommandString() -> String {
        
        var commandStr = ""
        
        let cmdDataValue = cmdData[lastPressBtn] ? UInt16(0x0002) : UInt16(0x0001)
        
        let Header = String(format: "%08X", header.bigEndian)
        
        let CMDType = String(format: "%04X", cmdType[lastPressBtn].bigEndian)
        
        let CMDDataValue = String(format: "%04X", cmdDataValue.bigEndian)
        
        if lastPressBtn == 6 {
            let Comment = String(repeating:comment, count: 5)
            commandStr = Header + CMDType + CMDDataValue + getCurrentDate() + Comment
        } else {
            let Comment = String(repeating:comment, count: 6)
            commandStr = Header + CMDType + CMDDataValue + Comment
        }
        
        cmdData[lastPressBtn] = !cmdData[lastPressBtn]
        cmdData[5] = false
        cmdData[6] = false
        
        return commandStr
    }
        
    @IBAction func writeTestText(_ sender: UIButton) {
        
        let cmdDataValue = cmdData[sender.tag] ? "0002" : "0001"
        
        if sender.tag == 6 {
            writeCharacteristicTextField.text = String(header, radix: 16) +
                String(cmdType[sender.tag], radix: 16) + cmdDataValue + getCurrentDate() + String(repeating:comment, count: 5)
        } else {
            writeCharacteristicTextField.text = String(header, radix: 16) +
                String(cmdType[sender.tag], radix: 16) + cmdDataValue + String(repeating:comment, count: 6)
        }
        
        
        lastPressBtn = sender.tag
    }
    // MARK: BlePeripheralDelegate
    
    /**
     Characteristic was read.  Update UI
     */
    func blePeripheral(characteristicRead byteArray: [UInt8], characteristic: CBCharacteristic, blePeripheral: BlePeripheral) {
        
        var mode : Int = 0
        
        let headerCheck : Bool = (byteArray[0] == 73) && (byteArray[1] == 82) &&
            (byteArray[2] == 84) && (byteArray[3] == 73)
        
        print("headerCheck: \(headerCheck) " )
        if  headerCheck && byteArray[5] == 171 {
            mode = Int(byteArray[4])
        }
        
        switch mode {
        case 2:
            let dataArray = [UInt8](byteArray[12...])
            parseRealTimeMode(dataArray: dataArray)
        case 6:
            print("Parse the date!")
            let dataArray = [UInt8](byteArray[12...])
            let dataLength = Int(byteArray[7]) << 8 + Int(byteArray[6])
            parseGetFileListDate(dataArray: dataArray, dataLenth: dataLength)
        default:
            print("mode not find, mode value is \(mode)")
        }
        
    }
    
    func parseGetFileListDate (dataArray: [UInt8], dataLenth: Int) {
        print("dataArray is \(dataArray)")
        print("The array length is \(dataArray.count)")
        print("The data length is \(dataLenth)")
        let dataInRange = dataArray.count > dataLenth
        print("dataInRange : \(dataInRange)")
        
        if dataLenth >= 8 {
            for i in 1...(dataLenth/8) {
                let year : UInt8 = dataArray[i*8-5] >> 2
                let month : UInt8 = dataArray[i*8-5] % 4 + dataArray[i*8-6] >> 6
                let day : UInt8 = (dataArray[i*8-6] >> 1) % 32
                let hour : UInt8 = (dataArray[i*8-6] % 2) << 4 + dataArray[i*8-7] >> 4
                let min : UInt8 = (dataArray[i*8-7] % 16) << 2 + dataArray[i*8-8] >> 6
                let sec : UInt8 = dataArray[i*8-8] % 64
                
                print("The date(\(i)) : \(Int(year)+2000)-\(month)-\(day) \(hour):\(min):\(sec)")
            }
        }
        
    }
    
    func parseRealTimeMode (dataArray: [UInt8]) {
        print("dataArray length is \(dataArray.count)")
        
        func updateAccelerLabel(isFirst: Bool) {
            let offset = isFirst ? 0 : 6
            let accelerXValue = Int16(dataArray[1+offset]) << 8 + Int16(dataArray[0+offset])
            accelerXLabel.text = String(accelerXValue)
            let accelerYValue = Int16(dataArray[3+offset]) << 8 + Int16(dataArray[2+offset])
            accelerYLabel.text = String(accelerYValue)
            let accelerZValue = Int16(dataArray[5+offset]) << 8 + Int16(dataArray[4+offset])
            accelerZLabel.text = String(accelerZValue)
        }
        updateAccelerLabel(isFirst: true)
    
        for i in 1...50 {
            if i == 26 { updateAccelerLabel(isFirst: false) }
            
            // Update the signal value of channel 1
            let ch1Value = Int16(dataArray[11+i*2]) << 8 + Int16(dataArray[10+i*2])
            waveformArea.pushSignal1BySliding(newValue: CGFloat(ch1Value))
            signal1Value.text = String(ch1Value)
            // Update the signal value of channel 2
            let ch2Value = Int16(dataArray[111+i*2]) << 8 + Int16(dataArray[110+i*2])
            waveformArea.pushSignal2BySliding(newValue: CGFloat(ch2Value))
            signal2Value.text = String(ch2Value)
        }
    }
    
    func getCurrentDate() -> String {
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        let today_string = String(year!) + "-" + String(month!) + "-" + String(day!) + " " + String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
        print(today_string)
        
        let byte1 : UInt8 = UInt8(year!-2000) << 2 + UInt8(month!) >> 2
        let byte2 : UInt8 = (UInt8(month!) % 4) << 6 + UInt8(day!) << 1 + UInt8(hour!) >> 4
        let byte3 : UInt8 = (UInt8(hour!) % 16) << 4 + UInt8(minute!) >> 2
        let byte4 : UInt8 = (UInt8(minute!) % 4) << 6 + UInt8(second!)
        
        let currentTime = String(format: "%02X", byte4) + String(format: "%02X", byte3) +
            String(format: "%02X", byte2) + String(format: "%02X", byte1)
        print(currentTime)
        return currentTime
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
