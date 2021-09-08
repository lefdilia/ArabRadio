//
//  PlayerDetailsView+Ext.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 4/7/2021.
//

import UIKit


extension PlayerDetailsView: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(pickerData[row]) min"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        typeValue = row
    }
    
    
    @objc func handleSleep(_ sender: Any){
        
        let alert = UIAlertController(title: "Sleep Timer".localized(), message: "Remaining time to play Station before stop!".localized(), preferredStyle: .alert)
        
        let height:NSLayoutConstraint = NSLayoutConstraint(item: alert.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 420)
        
        alert.view.addConstraint(height);
        
        let _pickerView = UIPickerView(frame: CGRect(x: 0, y: 72, width: 250, height: 200))
        _pickerView.dataSource = self
        _pickerView.delegate = self
        
        _pickerView.selectRow(4, inComponent: 0, animated: true)
        
        alert.view.addSubview(_pickerView)
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Start".localized(), style: .default, handler: { (UIAlertAction) in
            
            let selectedValue = self.typeValue ?? _pickerView.selectedRow(inComponent: 0)
            
            if selectedValue > self.pickerData.count {
                return
            }
            
            let timerChoise = self.pickerData[selectedValue]
            
            self.AVSingelton.setSleepMode(timerChoise: timerChoise) {
                
                //set player to pause
                self.playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
                self.miniPlayPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
                
                //Update Sleep Counter..
                self.sleepRemainingTimeLabel.fadeTransition(0.4)
                self.sleepRemainingTimeLabel.text = ""
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Remove Sleep".localized(), style: .destructive, handler: { _ in
            
            //Update Sleep Counter..
            self.sleepRemainingTimeLabel.fadeTransition(0.4)
            self.sleepRemainingTimeLabel.text = ""
            
            //Clear Timer
            self.AVSingelton.sleepTimer?.invalidate()
            self.AVSingelton.sleepTimeInterval = 0.0
            self.AVSingelton.sleepTimeRemaining = 0.0
            
        }))
        
        let navBarController = UIApplication.shared.windows.first?.rootViewController as? UINavigationController
        let radioListController = navBarController?.topViewController as? RadioListController
        radioListController?.present(alert, animated: true, completion: nil)
        
    }
}
