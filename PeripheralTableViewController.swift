//
//  PeripheralTableViewController.swift
//  Scanning
//
//  Created by Created by HengJay on 2017/12/04.
//  Copyright © 2017 ITRI All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 This view lists Peripherals during a Bluetooth Low Energy Scan
 */
class PeripheralTableViewController: UITableViewController, CBCentralManagerDelegate {
    
    // MARK: UI Elements
    @IBOutlet weak var scanButton: UIButton!
    
    // Default unknown advertisement name
    let unknownAdvertisedName = "(UNMARKED)"
    
    // PeripheralTableViewCell reuse identifier
    let peripheralCellReusedentifier = "PeripheralTableViewCell"
    
    
    // MARK: Scan Properties
    
    // total scan time
    let scanTimeout_s = 10; // seconds
    
    // current countdown
    var scanCountdown = 0
    
    // scan timer
    var scanTimer:Timer!
    
    // Central Bluetooth Manager
    var centralManager:CBCentralManager!
    
    // discovered peripherals
    var blePeripherals = [BlePeripheral]()
    
    
    
    
    //let perihperalSegueIdentifier = "ShowPeripheralSegue"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Initializing central manager")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //centralManager = nil
        print("Clean centralManager")
    }
    
    /**
     User touched the "Scan/Stop" button
     */
    @IBAction func onScanButtonClicked(_ sender: UIButton) {
        print("scan button clicked")
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
            print("Re-Initializing central manager")
        }
        // if scanning
        if centralManager.isScanning {
            stopBleScan()
        } else {
            startBleScan()
        }
    }
    
    
    /**
     Scan for Bluetooth peripherals
     */
    func startBleScan() {
        scanButton.setTitle("Stop", for: UIControlState.normal)
        blePeripherals.removeAll()
        tableView.reloadData()
        print ("discovering devices")
        print(centralManager)
        print(blePeripherals)
        scanCountdown = scanTimeout_s
        scanTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateScanCounter), userInfo: nil, repeats: true)
        
        if let centralManager = centralManager {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        
    }
    
    /**
     Stop scanning for Bluetooth Peripherals
     */
    func stopBleScan() {
        if let centralManager = centralManager {
            centralManager.stopScan()
        }
        scanTimer.invalidate()
        scanCountdown = 0
        scanButton.setTitle("Start", for: UIControlState.normal)
    }
    
    
    /**
     Update the scan countdown timer
     */
    func updateScanCounter() {
        //you code, this is an example
        if scanCountdown > 0 {
            print("\(scanCountdown) seconds until Ble Scan ends")
            scanCountdown -= 1
        } else {
            stopBleScan()
        }
    }
    
    
    
    // MARK:  CBCentralManagerDelegate Functions
    
    /**
     New Peripheral discovered
     
     - Parameters
     - central: the CentralManager for this UIView
     - peripheral: a discovered Peripheral
     - advertisementData: the Bluetooth GAP data discovered
     - rssi: the radio signal strength indicator for this Peripheral
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("Discovered \(peripheral.name)")
        print("Discovered \(peripheral.identifier.uuidString) (\(String(describing: peripheral.name)))")
        
        
        
        // check if this peripheral has already been discovered
        var peripheralFound = false
        for blePeripheral in blePeripherals {
            if blePeripheral.peripheral.identifier == peripheral.identifier {
                peripheralFound = true
                break
            }
        }
        
        
        // don't duplicate discovered devices
        if !peripheralFound {
            print(advertisementData)
            
            // Broadcast name in advertisement data may be different than the actual broadcast name
            // It's ideal to use the advertisement data version as it's supported on programmable bluetooth devices
            var advertisedName = unknownAdvertisedName
            if let alternateName = BlePeripheral.getNameFromAdvertisementData(advertisementData: advertisementData) {                    advertisedName = alternateName
            } else {
                if let peripheralName = peripheral.name {
                    advertisedName = peripheralName
                }
            }
            
            // don't display peripherals that can't be connected to
            if BlePeripheral.isConnectable(advertisementData: advertisementData) {
                let blePeripheral = BlePeripheral(delegate: nil, peripheral: peripheral)
                blePeripheral.rssi = RSSI
                blePeripheral.advertisedName = advertisedName
                blePeripherals.append(blePeripheral)
                tableView.reloadData()
            }
            
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
            print("BLE Hardware powered on and ready")
            scanButton.isEnabled = true
        default:
            print("Bluetooth unavailable")
        }
    }
    
    
    
    
    // MARK: - Table view data source
    
    /**
     return number of sections.  Only 1 is needed
     */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /**
     Return number of Peripheral cells
     */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blePeripherals.count
    }
    
    
    /**
     Return rendered Peripheral cell
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("setting up table cell")
        let cell = tableView.dequeueReusableCell(withIdentifier: peripheralCellReusedentifier, for: indexPath) as! PeripheralTableViewCell
        
        // fetch the appropritae peripheral for the data source layout
        let peripheral = blePeripherals[indexPath.row]
        cell.renderPeripheral(peripheral)
        
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        stopBleScan()
        
        let selectedRow = indexPath.row
        print("Row: \(selectedRow)")
        
        print(blePeripherals[selectedRow])
    }
    
    
    
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let peripheralViewController = segue.destination as! PeripheralViewController
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            let selectedRow = selectedIndexPath.row
            
            if selectedRow < blePeripherals.count {
                // prepare next UIView
                peripheralViewController.centralManager = centralManager
                peripheralViewController.blePeripheral = blePeripherals[selectedRow]
            }
            
            
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        
    }
    
    
    
    
}
