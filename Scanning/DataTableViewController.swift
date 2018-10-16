//
//  DataTableViewController.swift
//  ITRI-ECG-Recorder
//
//  Created by Ｍ200_Macbook_Pro on 2018/10/2.
//  Copyright © 2018 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

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
        patient.blood = Int16(bloodValue)
        patient.syndrome = syndromeTextfield.text
        patient.date = getCurrentDate(space: true)
 
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
    
    func getCurrentDate(space: Bool) -> String {
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        if space {
            let dateString = String(format: "%4d", year!) + "-"
                + String(format: "%02d", month!) + "-"
                + String(format: "%02d", day!) + "  "
                + String(format: "%02d", hour!) + ":"
                + String(format: "%02d", minute!) + ":"
                + String(format: "%02d", second!)
            
            return dateString
        } else {
            let dateString = String(format: "%4d", year!) + "-"
                + String(format: "%02d", month!) + "-"
                + String(format: "%02d", day!) + "_"
                + String(format: "%02d", hour!) + "_"
                + String(format: "%02d", minute!) + "_"
                + String(format: "%02d", second!)
            
            return dateString
        }
        
    }
    
}

extension DataTableViewController: MFMailComposeViewControllerDelegate {
    
    enum MIMEType: String {
        case jpg = "image/jpeg"
        case png = "image/png"
        case doc = "application/msword"
        case ppt = "application/vnd.ms-powerpoint"
        case html = "text/html"
        case csv = "text/csv"
        case pdf = "application/pdf"
        
        init?(type: String) {
            switch type.lowercased() {
            case "jpg": self = .jpg
            case "png": self = .png
            case "doc": self = .doc
            case "ppt": self = .ppt
            case "html": self = .html
            case "csv": self = .csv
            case "pdf": self = .pdf
            default: return nil
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result {
        case .cancelled:
            print("Mail cancelled")
        case .saved:
            print("Mail saved")
        case .sent:
            print("Mail sent")
        case .failed:
            print("Failed to send: \(error?.localizedDescription ?? "")")
        default:
            print("Failed to send: \(error?.localizedDescription ?? "")")
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func exportData(_ sender: UIButton) {
        
        let csvText = generateCSVText()
        
        let fileName = "Patients_Data_" + getCurrentDate(space: false) + ".csv"
        
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        do {
            try csvText.write(to: path , atomically: true, encoding: String.Encoding.utf8)
            print("Write Success !")
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
        
        // check device will able to send email
        guard MFMailComposeViewController.canSendMail() else {
            print("This device doesn't allow you to send mail.")
            return
        }
        
        let emailTitle = "TCM Patient Data: .csv File"
        let messageBody = "Testing for export .csv file from my iPad app."
        let toRecipients = ["hengjay.wang@itri.org.tw"]
        
        // init the mail composor and fill content
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setSubject(emailTitle)
        mailComposer.setMessageBody(messageBody, isHTML: false)
        mailComposer.setToRecipients(toRecipients)
        
        // recognize the file name and extension
        let fileparts = fileName.components(separatedBy: ".")
        let filename = fileparts[0]
        let fileExtension = fileparts[1]
        
        
        // Get file data and MIME type
        if let fileData = try? Data(contentsOf: path), let mimeType = MIMEType(type: fileExtension) {
            
            // add attachment
            mailComposer.addAttachmentData(fileData, mimeType: mimeType.rawValue, fileName: filename + "." + fileExtension)
            
            // show mail controller
            present(mailComposer, animated: true, completion: nil)
            
        }
    }
    
    func generateCSVText() -> String {
        
        var csvText = "Energy,Blood,Syndrome,Date\n"
        
        fetchData()
        
        for patient in patients {
            let newLine = "\(String(format: "%2d", patient.energy)),\(String(format: "%2d", patient.blood)),\(patient.syndrome!),\(patient.date!)\n"
            csvText += newLine
        }
        
        return csvText
    }
}
