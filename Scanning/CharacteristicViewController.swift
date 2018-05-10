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

/**
 This view talks to a Characteristic
 */
class CharacteristicViewController: UIViewController, CBCentralManagerDelegate, BlePeripheralDelegate, NotifyCustomDelegate, NotifyFotaDelegate {
    
    // MARK: UI elements
    @IBOutlet weak var advertizedNameLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var characteristicUuidlabel: UILabel!
    
    @IBOutlet weak var waveformArea: WaveformView!
    @IBOutlet weak var signal1Value: UILabel!
    @IBOutlet weak var signal2Value: UILabel!
    @IBOutlet weak var writeCharacteristicButton: UIButton!
    @IBOutlet weak var writeFOTAButton: UIButton!
    @IBOutlet weak var writeCharacteristicTextField: UITextField!
    
    @IBOutlet weak var accelerXLabel: UILabel!
    @IBOutlet weak var accelerYLabel: UILabel!
    @IBOutlet weak var accelerZLabel: UILabel!
    
    @IBOutlet weak var fileIndexTextFiled: UITextField!
    @IBOutlet weak var startTimeTextField: UITextField!
    @IBOutlet weak var durationTimeTextField: UITextField!
    
    @IBOutlet weak var consoleTextView: UITextView!
    
    // MARK: Connected devices
    
    // Central Bluetooth Radio
    var centralManager: CBCentralManager!
    
    // Bluetooth Peripheral
    var blePeripheral: BlePeripheral!
    
    // Connected Characteristic
    var connectedService: CBService!
    
    // Connected Characteristic
    var connectedCharacteristic: CBCharacteristic!
    
    // DOGP Characteristic for FOTA
    var dogpReadCharacteristic: CBCharacteristic!
    var dogpWriteCharacteristic: CBCharacteristic!
    var dogpCharFind: Bool = false
    
    // BtNotify Library
    var btNotify: BtNotify!
 
    // Fota Type
    var FotaType: Int32 = 5 // Full bin
    
    /**
     UIView loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUI()
        printToConsole("Will connect to device \(blePeripheral.peripheral.identifier.uuidString)")
        printToConsole("Will connect to characteristic \(connectedCharacteristic.uuid.uuidString)")
        
        centralManager.delegate = self
        blePeripheral.delegate = self
        
        btNotify = (BtNotify.sharedInstance() as! BtNotify)
        FotaSetting()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        btNotify.register(self as NotifyCustomDelegate)
        btNotify.register(self as NotifyFotaDelegate)
        FotaSetting()
    }
    
    @IBAction func notifyCharacteristic(_ sender: UISwitch) {
        printToConsole("notify the characteristic is \(sender.isOn)")
        blePeripheral.peripheral.setNotifyValue(sender.isOn, for: connectedCharacteristic)
    }
    /* Load UI elements */
    func loadUI() {
        advertizedNameLabel.text = blePeripheral.advertisedName
        identifierLabel.text = blePeripheral.peripheral.identifier.uuidString
        characteristicUuidlabel.text = connectedCharacteristic.uuid.uuidString
        
        // characteristic is not writeable
        if !BlePeripheral.isCharacteristic(isWriteable: connectedCharacteristic) {
            writeCharacteristicTextField.isEnabled = false
            writeCharacteristicButton.isEnabled = false
        }
        writeFOTAButton.isEnabled = false
        startTimeTextField.isEnabled = false
        durationTimeTextField.isEnabled = false
        blePeripheral.peripheral.setNotifyValue(true, for: connectedCharacteristic)
    }
    
    func FotaSetting() {
        if let dogpRead = dogpReadCharacteristic, let dogpWrite = dogpWriteCharacteristic {
            printToConsole("dogpReadCharacteristic find ! uuid is \(dogpRead.uuid.uuidString)")
            printToConsole("dogpWriteCharacteristic find ! uuid is \(dogpWrite.uuid.uuidString)")
            dogpCharFind = true
            printToConsole("dogpCharFind is \(dogpCharFind)")
        }
        if dogpCharFind {
            printToConsole("The FOTA characteristic is found (\(dogpReadCharacteristic.uuid.uuidString),\(dogpWriteCharacteristic.uuid.uuidString)), FOTA setting is running.")
        } else {
            printToConsole("The FOTA characteristic not found, FOTA setting is quit !")
            return
        }
        
        let bundlePath = Bundle.main.url(forResource: "image", withExtension: "bin")
        printToConsole("bundlePath of image.bin is " + (bundlePath?.path)!)
        
       
        if dogpCharFind {
            printToConsole("btNotify.setGattParameters run ! (Start)")
            btNotify.setGattParameters(blePeripheral.peripheral,
                                       write: dogpWriteCharacteristic,
                                       read: dogpReadCharacteristic)
            printToConsole("btNotify.setGattParameters run ! (End)")
        }
        
        btNotify.updateConnectionState(Int32(CBPeripheralState.connected.rawValue))
        
        writeFOTAButton.isEnabled = dogpCharFind
    }
    
    @IBAction func writeFOTA(_ sender: UIButton) {
        let bundlePath = Bundle.main.url(forResource: "image", withExtension: "bin")
        printToConsole("bundlePath of image.bin is " + (bundlePath?.path)!)
        
        let isReady = (BtNotify.sharedInstance() as! BtNotify).isReadyToSend()
        printToConsole("The btNotify.isReadyToSend() return value : \(isReady)")
        
        let returnValue = (BtNotify.sharedInstance() as! BtNotify).sendFotaTypeGetCmd()
        printToConsole("The btNotify.sendFotaTypeGetCmd() return value : \(returnValue)")
        
        checkReturnValue(returnValue)
        
        do {
            let data = try Data(contentsOf: bundlePath!)
            let byteArray = [UInt8](data)
            printToConsole("The content size of image.bin is (Data) : \(data.count)")
            printToConsole("The content size of image.bin is (byteArray): \(byteArray.count)")
            let returnValue = (BtNotify.sharedInstance() as! BtNotify).sendFotaData(FotaType, firmwareData: data)
            printToConsole("btNotify.sendFotaData returnValue is \(returnValue)")
            checkReturnValue(returnValue)
        } catch {
            printToConsole("Parse image.bin string Error !")
        }
    }
    
    func checkReturnValue(_ returnValue: Int32) {
        var message : String
        switch returnValue {
        case ERROR_CODE_OK:
            message = "ERROR_CODE_OK"
        case ERROR_CODE_NOT_INITED:
            message = "ERROR_CODE_NOT_INITED"
        case ERROR_CODE_NOT_STARTED:
            message = "ERROR_CODE_NOT_STARTED"
        case ERROR_CODE_NOT_HANDSHAKE_DONE:
            message = "ERROR_CODE_NOT_HANDSHAKE_DONE"
        default:
            message = "not found"
        }
        printToConsole("returnValue \(returnValue) means \(message) !")
    }
    
    /* Implement function for NotifyCustomDelegete */
    func onDataArrival(_ receiver: String!, arrivalData data: Data!) {
        printToConsole("onDataArrival: the receiver : \(receiver), arrivalData length : \(data.count))")
    }
    
    func onReady(toSend ready: Bool) {
        printToConsole("onReady: the ready is \(ready)")
    }
    
    func onProgress(_ sender: String!, newProgress progress: Float) {
        printToConsole("onProgress: the sender is \(sender), progress: \(progress)")
    }
    
    /* Implement function for NotifyFotaDelegete */
    func onFotaTypeReceived(_ fotaType: Int32) {
        printToConsole("onFotaTypeReceived: the fotaType is \(fotaType)")
        FotaType = fotaType
        var message : String
        switch fotaType {
        case REDBEND_FOTA_UPDATE:
            message = "REDBEND_FOTA_UPDATE"
        case SEPARATE_BIN_FOTA_UPDATE:
            message = "SEPARATE_BIN_FOTA_UPDATE"
        case ROCK_FOTA_UPDATE:
            message = "ROCK_FOTA_UPDATE"
        case FBIN_FOTA_UPDATE:
            message = "FBIN_FOTA_UPDATE"
        default:
            message = "not found"
        }
        printToConsole("returnValue: \(fotaType) means \(message) !")
    }
    
    func onFotaStatusReceived(_ status: Int32) {
        printToConsole("onFotaStatusReceived: the status is \(status)")
        var message : String
        switch status {
        case FOTA_UPDATE_VIA_BT_TRANSFER_SUCCESS:
            message = "FOTA_UPDATE_VIA_BT_TRANSFER_SUCCESS"
        case FOTA_UPDATE_VIA_BT_UPDATE_SUCCESS:
            message = "FOTA_UPDATE_VIA_BT_UPDATE_SUCCESS"
        case FOTA_UPDATE_VIA_BT_COMMON_ERROR:
            message = "FOTA_UPDATE_VIA_BT_COMMON_ERROR"
        case FOTA_UPDATE_VIA_BT_WRITE_FILE_FAILED:
            message = "FOTA_UPDATE_VIA_BT_WRITE_FILE_FAILED"
        case FOTA_UPDATE_VIA_BT_DISK_FULL:
            message = "FOTA_UPDATE_VIA_BT_DISK_FULL"
        case FOTA_UPDATE_VIA_BT_TRANSFER_FAILED:
                message = "FOTA_UPDATE_VIA_BT_TRANSFER_FAILED"
        case FOTA_UPDATE_VIA_BT_TRIGGER_FAILED:
            message = "FOTA_UPDATE_VIA_BT_TRIGGER_FAILED"
        case FOTA_UPDATE_VIA_BT_UPDATE_FAILED:
            message = "FOTA_UPDATE_VIA_BT_UPDATE_FAILED"
        case FOTA_UPDATE_VIA_BT_TRIGGER_FAILED_CAUSE_LOW_BATTERY:
            message = "FOTA_UPDATE_VIA_BT_TRIGGER_FAILED_CAUSE_LOW_BATTERY"
        default:
            message = "not found"
        }
        printToConsole("status: \(status) means \(message) !")
    }
    
    func onFotaProgress(_ progress: Float) {
        printToConsole("onFotaProgress: progress is \(progress)")
    }
    
    func onFotaVersionReceived(_ version: FotaVersion!) {
        printToConsole("onFotaVersionReceived: FotaVersion is \(version)")
    }

    var fileDurationTime : [UInt32] = [UInt32](repeating: 0, count: 32)
    let header : UInt32 = 0x49545249
    let cmdType : [UInt16] = [0xAB01, 0xAB02, 0xAB03, 0xAB04, 0xAB05, 0xAB06, 0xAB07]
    var cmdData : [Bool] = [false, false, false, false, false, false, false]
    let comment = "FFFFFFFF"
    var lastPressBtn : Int = 0
    
    @IBAction func writeCharacteristic(_ sender: UIButton) {
        printToConsole("write button pressed")
        writeCharacteristicButton.isEnabled = false
       
        let stringValue = generateCommandString()
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
        
        if (lastPressBtn == 2) || (lastPressBtn == 3) || (lastPressBtn == 4) {
            let Comment = String(repeating:comment, count: 3)
            commandStr = Header + CMDType + CMDDataValue + getFileCommandString() + Comment
        } else if lastPressBtn == 6 {
            let Comment = String(repeating:comment, count: 5)
            commandStr = Header + CMDType + CMDDataValue + getCurrentDate() + Comment
        } else {
            let Comment = String(repeating:comment, count: 6)
            commandStr = Header + CMDType + CMDDataValue + Comment
        }
        
        cmdData[lastPressBtn] = !cmdData[lastPressBtn]
        cmdData[5] = false
        cmdData[6] = false
        printToConsole("The string will be write to peripheral: \(commandStr)")
        return commandStr
    }
        
    @IBAction func writeTestText(_ sender: UIButton) {
        
        let cmdDataValue = cmdData[sender.tag] ? "0002" : "0001"
        
        if (sender.tag == 2) || (sender.tag == 3) || (sender.tag == 4) {
            let fileIndex = UInt32(fileIndexTextFiled.text!) ?? 0
            let startTime = UInt32(startTimeTextField.text!) ?? 0
            let durationTime = UInt32(durationTimeTextField.text!) ?? 0
            
            if !((fileIndex >= 1) && (fileIndex <= 32)) {
                printToConsole("fileIndex error !! Need to follow the condition: >= 1 && <= 32")
            } else if !((startTime >= 0) && (durationTime >= 0)) {
                printToConsole("startTime or durationTime error !! Need to follow the condition: >= 0")
            } else if !(startTime + durationTime <= fileDurationTime[Int(fileIndex)-1]) {
                printToConsole("Exceed maximum file time error !! The startTime: \(startTime) + durationTime: \(durationTime) need to <= maximum of \(fileIndex) file: \(fileDurationTime[Int(fileIndex)-1]) ")
            } else {
                writeCharacteristicTextField.text = String(header, radix: 16) +
                    String(cmdType[sender.tag], radix: 16) + cmdDataValue +
                    getFileCommandString() + String(repeating:comment, count: 3)
                printToConsole("The input format is valid !! write command text succeed !!")
            }
        } else if sender.tag == 6 {
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
        printToConsole("Characteristic is received ! Data from characteristic: \(characteristic.uuid.uuidString). byteArray length is \(byteArray.count).")
        var mode : Int = 0
        guard byteArray.count > 10 else {
            printToConsole("byteArray too small, length only \(byteArray.count) !")
            printToConsole("byteArray : \(byteArray)")
            return
        }
        let headerCheck : Bool = (byteArray[0] == 73) && (byteArray[1] == 82) &&
            (byteArray[2] == 84) && (byteArray[3] == 73)
        printToConsole("byteArray : \(byteArray)")
        printToConsole("headerCheck is \(headerCheck) ")
        
        if lastPressBtn == 1 {
            printToConsole("signal Max is \(waveformArea.signal1Max), min is \(waveformArea.signal1Min)")
        }
        if  headerCheck && byteArray[5] == 171 {
            mode = Int(byteArray[4])
        }
        
        switch mode {
        case 2:
            let dataArray = [UInt8](byteArray[12...])
            if dataArray.count == 212 { parseRealTimeMode(dataArray: dataArray) }
        case 3:
            let dataArray = [UInt8](byteArray[12...])
            if dataArray.count == 212 { parseRPeakMode(dataArray: dataArray) }
        case 6:
            let dataArray = [UInt8](byteArray[12...])
            let dataLength = Int(byteArray[7]) << 8 + Int(byteArray[6])
            parseGetFileListDate(dataArray: dataArray, dataLength: dataLength)
        default:
            printToConsole("Parse mode not find, mode value is \(mode)")
        }
        
    }
    
    func parseGetFileListDate (dataArray: [UInt8], dataLength: Int) {
       
        let dataInRange = dataArray.count > dataLength

        let message = """
        Parse GetFileList Mode :
        The dataArray is \(dataArray)
        The array length is \(dataArray.count)
        The data length is \(dataLength)
        dataInRange is \(dataInRange)
        """
        printToConsole(message)
        
        if dataLength >= 12 {
            for i in 1...(dataLength/12) {
                let year : UInt8 = dataArray[i*12-5] >> 2
                //printToConsole("The year byte is : \(dataArray[i*12-5])")
                //printToConsole("in binary : " + String(dataArray[i*12-5], radix: 2))
                let month : UInt8 = (dataArray[i*12-5] % 4) << 2 + dataArray[i*12-6] >> 6
                let day : UInt8 = (dataArray[i*12-6] >> 1) % 32
                let hour : UInt8 = (dataArray[i*12-6] % 2) << 4 + dataArray[i*12-7] >> 4
                let min : UInt8 = (dataArray[i*12-7] % 16) << 2 + dataArray[i*12-8] >> 6
                let sec : UInt8 = dataArray[i*12-8] % 64
                
                let durationTime : UInt32 = UInt32(dataArray[i*12-1]) << 24 +
                                            UInt32(dataArray[i*12-2]) << 16 +
                                            UInt32(dataArray[i*12-3]) << 8 +
                                            UInt32(dataArray[i*12-4])
                
                let fileIndex : UInt32 = UInt32(dataArray[i*12-9]) << 24 +
                                         UInt32(dataArray[i*12-10]) << 16 +
                                         UInt32(dataArray[i*12-11]) << 8 +
                                         UInt32(dataArray[i*12-12])
                
                if (fileIndex >= 1) && (fileIndex <= 32) {
                    fileDurationTime[Int(fileIndex)-1] = durationTime
                }
                let message = "The date of \(fileIndex) file : \(Int(year)+2000)-\(month)-\(day) \(hour):\(min):\(sec)  Duration Time: \(durationTime)"
                printToConsole(message)
            }
        }
        startTimeTextField.isEnabled = true
        durationTimeTextField.isEnabled = true
        durationTimeTextField.text = String(fileDurationTime[0])
        printToConsole("duration times is saved in array: \(fileDurationTime)")
    }
    
    func parseRealTimeMode (dataArray: [UInt8]) {

        let message = "Parse Real-Time Mode Data: dataArray length is \(dataArray.count)"
        printToConsole(message)
        
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
    
    func parseRPeakMode (dataArray: [UInt8]) {
        let message = "Parse R-Peak Mode Data: dataArray length is \(dataArray.count)"
        printToConsole(message)
        /*
        for i in 1...(dataArray.count/4) {
            let rPeakValue : UInt32 = UInt32(dataArray[i*4-1]) << 24 +
                                      UInt32(dataArray[i*4-2]) << 16 +
                                      UInt32(dataArray[i*4-3]) << 8 +
                                      UInt32(dataArray[i*4-4])
            printToConsole("The \(i)th of R-Peak value is: \(rPeakValue)")
        }
        printToConsole("\(dataArray.count/4) R-Peak value in total.")
        */
    }
    
    func printToConsole (_ message: String) {
        print(message)
        consoleTextView.insertText(message + "\n")
        let stringLength = consoleTextView.text.count
        consoleTextView.scrollRangeToVisible(NSMakeRange(stringLength-1,0))
    }
    
    func getFileCommandString() -> String {
        let fileIndex = UInt32(fileIndexTextFiled.text!) ?? 0
        let startTime = UInt32(startTimeTextField.text!) ?? 0
        let durationTime = UInt32(durationTimeTextField.text!) ?? 0
        printToConsole("getFileCommandString : fileIndex: \(fileIndex), startIndex: \(startTime), durationTime: \(durationTime)")
        let commandString = String(format: "%08X", fileIndex.bigEndian) +
                            String(format: "%08X", startTime.bigEndian) +
                            String(format: "%08X", durationTime.bigEndian)
        printToConsole("commandString is \(commandString)")
        return commandString
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
        
        let today_string = String(year!) + "-" + String(month!) + "-" + String(day!) + " " + String(hour!) + ":" + String(minute!) + ":"
            + String(second!)
        printToConsole(today_string)
        
        let byte1 : UInt8 = UInt8(year!-2000) << 2 + UInt8(month!) >> 2
        let byte2 : UInt8 = (UInt8(month!) % 4) << 6 + UInt8(day!) << 1 + UInt8(hour!) >> 4
        let byte3 : UInt8 = (UInt8(hour!) % 16) << 4 + UInt8(minute!) >> 2
        let byte4 : UInt8 = (UInt8(minute!) % 4) << 6 + UInt8(second!)
        
        let currentTime = String(format: "%02X", byte4) + String(format: "%02X", byte3) +
            String(format: "%02X", byte2) + String(format: "%02X", byte1)
        printToConsole("currentTime in 4 bytes formatis : " + currentTime)
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
