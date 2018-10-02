//
//  patientDataTableViewCell.swift
//  ITRI-ECG-Recorder
//
//  Created by Ｍ200_Macbook_Pro on 2018/10/2.
//  Copyright © 2018 ITRI. All rights reserved.
//

import UIKit
import CoreData


// Custom UITableViewCell
class PatientDataTableViewCell: UITableViewCell {
    
    @IBOutlet weak var energyLabel: UILabel!
    
    @IBOutlet weak var bloodLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var syndrome: UILabel!
    
    func fillData(patient: Patient) {
        let energy = String(format: "%2d", patient.energy)
        let blood = String(format: "%2d", patient.blood)
        let date = patient.date!
        let syndrome = patient.syndrome!
        
        self.energyLabel.text = "氣：\(energy)"
        self.bloodLabel.text = "血：\(blood)"
        self.dateLabel.text = date
        self.syndrome.text = syndrome
    }
    
}
