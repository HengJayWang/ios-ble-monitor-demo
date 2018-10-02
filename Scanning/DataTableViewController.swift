//
//  DataTableViewController.swift
//  ITRI-ECG-Recorder
//
//  Created by Ｍ200_Macbook_Pro on 2018/10/2.
//  Copyright © 2018 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreData

class DataTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
 
    // IBOutlet
    @IBOutlet weak var energyLabel: UILabel!
    @IBOutlet weak var bloodLabel: UILabel!
    @IBOutlet weak var energySlider: UISlider!
    @IBOutlet weak var bloodSlider: UISlider!
    @IBOutlet weak var syndromeTextfield: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var dataTable: UITableView!
    
    
    // Global Varible
    var energyValue: Int = 0
    var bloodValue: Int = 0
    var patients: [Patient] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUI()
        dataTable.delegate = self
        dataTable.dataSource = self
        fetchData()
        
        // Refresh Control
        dataTable.refreshControl = UIRefreshControl()
        dataTable.refreshControl?.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return patients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dataTable.dequeueReusableCell(withIdentifier: "PatientDataTableViewCell", for: indexPath) as! PatientDataTableViewCell
        
        cell.fillData(patient: patients[indexPath.row])

        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (rowAction, indexPath) in
            self.deleteItem(index: indexPath)
            self.fetchData()
            self.dataTable.deleteRows(at: [indexPath], with: .fade)
            
        }
        
        deleteAction.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        
        return [deleteAction]
    }
    
    @IBAction func changeEnergyValue(_ sender: UISlider) {
        energyLabel.text = "\(Int(sender.value))"
        energyValue = Int(sender.value)
    }
    
    @IBAction func changeBloodValue(_ sender: UISlider) {
        bloodLabel.text = "\(Int(sender.value))"
        bloodValue = Int(sender.value)
    }
    
    @IBAction func saveData(_ sender: UIButton) {
        save()
        resetLabel()
        
        
        let message = UIAlertController(title: "Save data success !", message: nil, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        message.addAction(cancelAction)
        
        present(message, animated: true, completion: nil)
        
    }
    
    @IBAction func exportData(_ sender: UIButton) {
        
    }
    
    func loadUI() {
        setBtnCorner(btn: saveButton)
        setBtnCorner(btn: exportButton)
    }
    
    func save() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Save Data
        let patient = Patient(context: context)
        
        patient.energy = Int16(energyValue)
        print("energy is \(patient.energy)")
        patient.blood = Int16(bloodValue)
        print("blood is \(patient.blood)")
        patient.syndrome = syndromeTextfield.text
        print("syndrome is \(patient.syndrome!)")
        patient.date = getCurrentDate()
        print("date is \(patient.date!)")
        
        print("Ready save to Core Data Container...")
        do {
            try context.save()
            print("Save success !!")
        } catch  {
            print("Save failed")
        }
        
        fetchData()
        dataTable.reloadData()
        
    }
    
    func setBtnCorner(btn: UIButton) {
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        btn.layer.masksToBounds = false
        btn.layer.shadowRadius = 2.0
        btn.layer.shadowOpacity = 0.5
        btn.layer.cornerRadius = 20.0
    }
    
    func resetLabel() {
        energyValue = 0
        energyLabel.text = "0"
        energySlider.value = 0
        bloodValue = 0
        bloodLabel.text = "0"
        bloodSlider.value = 0
        syndromeTextfield.text = ""
    }
    
    func fetchData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //Fetch Data
        let fetchRequest = NSFetchRequest<Patient>(entityName: "Patient")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            patients = try context.fetch(fetchRequest)
        } catch {
            print("No Result")
        }
    }
    
    func deleteItem(index: IndexPath) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        context.delete(patients[index.row])
        
        do {
            try context.save()
        } catch  {
            print("Save error ! Data could not be deleted.")
        }
        
    }
    
    @objc func refreshTable() {
        fetchData()
        dataTable.refreshControl?.endRefreshing()
        dataTable.reloadData()
    }
    
    func getCurrentDate() -> String {
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        let dateString = String(format: "%4d", year!) + "-"
                       + String(format: "%02d", month!) + "-"
            + String(format: "%02d", day!) + "  "
            + String(format: "%02d", hour!) + ":"
            + String(format: "%02d", minute!) + ":"
            + String(format: "%02d", second!)
        print(dateString)
        
        return dateString
    }
    
}
