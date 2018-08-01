//
//  ViewController.swift
//  Bootstrapping
//
//  Created by Created by HengJay on 2017/12/04.
//  Copyright © 2017 ITRI All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 This view lists the GATT profile of a connected characteristic
 */
class PeripheralViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate, BlePeripheralDelegate {

    // MARK: UI Elements
    @IBOutlet weak var advertisedNameLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var gattProfileTableView: UITableView!
    @IBOutlet weak var gattTableView: UITableView!

    // Gatt Table Cell Reuse Identifier
    let gattCellReuseIdentifier = "GattTableViewCell"

    // Segue
    let segueIdentifier = "LoadCharacteristicViewSegue"

    // MARK: Connected Peripheral Properties

    // Central Manager
    var centralManager: CBCentralManager!

    // connected Peripheral
    var blePeripheral: BlePeripheral!

    // DOGP Characteristic for FOTA
    var dogpReadCharacteristic: CBCharacteristic!
    var dogpWriteCharacteristic: CBCharacteristic!

    // Info Characteristic
    var batteryCharacteristic: CBCharacteristic!
    var commandCharacteristic: CBCharacteristic!
    var systemInfoCharacteristic: CBCharacteristic!

    /**
     UIView loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Will connect to \(blePeripheral.peripheral.identifier.uuidString)")

        // Assign delegates
        blePeripheral.delegate = self
        centralManager.delegate = self
        centralManager.connect(blePeripheral.peripheral)
    }

    // MARK: BlePeripheralDelegate

    /**
     Characteristics were discovered.  Update the UI
     */
    func blePerihperal(discoveredCharacteristics characteristics: [CBCharacteristic], forService: CBService, blePeripheral: BlePeripheral) {
        gattTableView.reloadData()
    }

    /**
     RSSI discovered.  Update UI
     */
    func blePeripheral(readRssi rssi: NSNumber, blePeripheral: BlePeripheral) {
        rssiLabel.text = rssi.stringValue
    }

    // MARK: CBCentralManagerDelegate code

    /**
     Peripheral connected.  Update UI
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected Peripheral: \(String(describing: peripheral.name))")

        advertisedNameLabel.text = blePeripheral.advertisedName
        identifierLabel.text = blePeripheral.peripheral.identifier.uuidString

        blePeripheral.connected(peripheral: peripheral)
    }

    /**
     Connection to Peripheral failed.
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("failed to connect")
        print(error.debugDescription)
    }

    /**
     Peripheral disconnected.  Leave UIView
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected Peripheral: \(String(describing: peripheral.name))")
        dismiss(animated: true, completion: nil)
    }

    /**
     Bluetooth radio state changed.
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

    // MARK: UITableViewDataSource

    /**
     Return number of rows in Service section
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("returning num rows in section")
        if section < blePeripheral.gattProfile.count {
            if let characteristics = blePeripheral.gattProfile[section].characteristics {
                return characteristics.count
            }
        }
        return 0
    }

    /**
     Return a rendered cell for a Characteristic
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("returning table cell")
        let cell = tableView.dequeueReusableCell(withIdentifier: gattCellReuseIdentifier, for: indexPath) as! GattTableViewCell

        let section = indexPath.section
        let row = indexPath.row

        if section < blePeripheral.gattProfile.count {
            if let characteristics = blePeripheral.gattProfile[section].characteristics {
                if row < characteristics.count {
                    cell.renderCharacteristic(characteristic: characteristics[row])
                }
            }
        }

        return cell
    }

    /**
     Return the number of Service sections
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        print("returning number of sections")
        print(blePeripheral)
        print(blePeripheral.gattProfile)
        return blePeripheral.gattProfile.count
    }

    /**
     Return the title for a Service section
     */
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        print("returning title at section \(section)")
        if section < blePeripheral.gattProfile.count {
            return blePeripheral.gattProfile[section].uuid.uuidString
        }
        return nil
    }

    /**
     User selected a Characteristic table cell.  Update UI and open the next UIView
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRow = indexPath.row
        print("Selected Row: \(selectedRow)")
    }

    // MARK: Navigation

    /**
     Handle the Segue.  Prepare the next UIView with necessary information
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("leaving view - disconnecting from peripheral")

        if let indexPath = gattTableView.indexPathForSelectedRow {
            let selectedSection = indexPath.section
            let selectedRow = indexPath.row

            let characteristicViewController = segue.destination as! CharacteristicViewController

            if selectedSection < blePeripheral.gattProfile.count {
                // find DOGP characteristic
                for service in blePeripheral.gattProfile {
                    if let chars = service.characteristics {
                        for char in chars {
                            switch (char.uuid.uuidString) {
                            case "2AA0":
                                dogpReadCharacteristic = char
                                print("Find DOGP Read Characteristic ! uuid is \(dogpReadCharacteristic.uuid.uuidString)")
                            case "2AA1":
                                dogpWriteCharacteristic = char
                                print("Find DOGP Write Characteristic ! uuid is \(dogpWriteCharacteristic.uuid.uuidString)")
                            case "2A19":
                                batteryCharacteristic = char
                                print("Find Battery Characteristic ! uuid is \(batteryCharacteristic.uuid.uuidString)")
                            case "4AA0":
                                commandCharacteristic = char
                                print("Find Command Characteristic ! uuid is \(commandCharacteristic.uuid.uuidString)")
                            case "4AA1":
                                systemInfoCharacteristic = char
                                print("Find System Info Characteristic ! uuid is \(systemInfoCharacteristic.uuid.uuidString)")
                            default:
                                print("Characteristic \(char.uuid.uuidString) is not specific char !")
                            }
                        }
                    }
                }

                let service = blePeripheral.gattProfile[selectedSection]

                if let characteristics = blePeripheral.gattProfile[selectedSection].characteristics {

                    if selectedRow < characteristics.count {
                        // populate next UIView with necessary information
                        characteristicViewController.centralManager = centralManager
                        characteristicViewController.blePeripheral = blePeripheral
                        characteristicViewController.connectedService = service
                        characteristicViewController.connectedCharacteristic = characteristics[selectedRow]
                        if let dogpRead = dogpReadCharacteristic {
                            characteristicViewController.dogpReadCharacteristic = dogpRead
                        }
                        if let dogpWrite = dogpWriteCharacteristic {
                            characteristicViewController.dogpWriteCharacteristic = dogpWrite
                        }
                        if let batteryInfo = batteryCharacteristic {
                            characteristicViewController.batteryCharacteristic = batteryInfo
                        }
                        if let command = commandCharacteristic {
                            characteristicViewController.commandCharacteristic = command
                        }
                        if let systemInfo = systemInfoCharacteristic {
                            characteristicViewController.systemInfoCharacteristic = systemInfo
                        }
                    }

                }
            }
            gattTableView.deselectRow(at: indexPath, animated: true)

        } else {
            if let peripheral = blePeripheral.peripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }

    }
}
