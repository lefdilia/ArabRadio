//
//  SettingsControllerCell.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 9/5/2021.
//

import UIKit


class SettingsControllerCell: UITableViewCell {
    
    weak var viewController: UIViewController?
    
    var title: String? {
        didSet{
            guard let title = title else { return }
            _settingTitle.text = title
        }
    }
    
    var indexPath: IndexPath? {
        didSet{
            guard let indexPath = indexPath else { return }
            
            _switcher.tag = indexPath.row
            
            switch indexPath.row {
            case 0:
                _switcher.isOn = UserDefaults.standard.bool(forKey: "wifiOnly")
                
            case 1:
                _switcher.isOn = UserDefaults.standard.bool(forKey: "startOnApplaunch")
                
            default: return
            }
        }
    }
    
    lazy var _switcher: UISwitch = {
        let iSwitch = UISwitch()
        iSwitch.addTarget(self, action: #selector(handleSwitchControl), for: .valueChanged)
        iSwitch.translatesAutoresizingMaskIntoConstraints = false
        return iSwitch
    }()
    
    let _settingTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: Theme.mainFontName, size: 17)
        label.textColor = UIColor.darkBlue
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()
    
    @objc private func handleSwitchControl(sender: UISwitch){
        
        switch _switcher.tag {
        case 0:
            UserDefaults.standard.setValue(_switcher.isOn , forKey: "wifiOnly")
            
        case 1:
            UserDefaults.standard.setValue(_switcher.isOn , forKey: "startOnApplaunch")
            
        default: return
        }
        
        if _switcher.tag == 0 && _switcher.isOn == true && AVPlayerSingleton.shared.player.timeControlStatus == .playing && NetworkStatus.shared.ConnectionType == .wifi { AVPlayerSingleton.shared.clearPlayer { return } }
        
        //Check if cellular && Wifi only true
        if UserDefaults.standard.bool(forKey: "wifiOnly") == true && NetworkStatus.shared.ConnectionType == .cellular {
            let playerStatus = AVPlayerSingleton.shared.player.timeControlStatus == .playing
            AVPlayerSingleton.shared.clearPlayer {
                if playerStatus == true {
                    let alertMessage = UIAlertController(title: "", message: "Player stopped, You are running on Cellular Data".localized(), preferredStyle: .alert)
                    
                    self.viewController?.present(alertMessage, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4){
                        alertMessage.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .white
        selectionStyle = .none
        
        contentView.addSubview(_switcher)
        NSLayoutConstraint.activate([
            _switcher.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 34),
            _switcher.centerYAnchor.constraint(equalTo: centerYAnchor),
            _switcher.heightAnchor.constraint(equalToConstant: 42),
            _switcher.widthAnchor.constraint(equalToConstant: 57)
        ])
        
        addSubview(_settingTitle)
        NSLayoutConstraint.activate([
            _settingTitle.leadingAnchor.constraint(equalTo: _switcher.trailingAnchor, constant: 8),
            _settingTitle.centerYAnchor.constraint(equalTo: _switcher.centerYAnchor, constant: -6),
            _settingTitle.heightAnchor.constraint(equalToConstant: 20),
            _settingTitle.widthAnchor.constraint(equalTo: widthAnchor, constant: 30)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

