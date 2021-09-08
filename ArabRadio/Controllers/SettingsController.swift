//
//  SettingsController.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 25/4/2021.
//

import UIKit

class SettingsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let cellId = "settingsCell"
    
    let listOfTitles = ["Listen Only on Wi-fi".localized(), "Autoplay on app start".localized()]
    
    var activityIndicator = UIActivityIndicatorView()
    
    let _settingView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .init(top: 1, left: 31, bottom: 1, right: 31)
        tableView.separatorColor = UIColor.separatorColor
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    lazy var _bottomView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let _changeCountryButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleChangeCountry), for: .touchUpInside)
        //
        button.setBackgroundImage(UIImage(named: "changeCountry"), for: .normal)
        //
        let tempImage = UIImage(named: "change")
        let lightTempImage = tempImage?.withTintColor(UIColor.extraColor ?? .gray, renderingMode: .alwaysTemplate)
        let _image = NSTextAttachment(image: lightTempImage!)
        _image.bounds = CGRect(x: 0, y: -3, width: 12, height: 18)
        let attributedText =  NSMutableAttributedString(attachment: _image)
        let extString = NSAttributedString(string: "  "+"Change Country".localized(), attributes: [.font : UIFont(name: Theme.displayFontName, size: 16) as Any,
                                                                                                   .foregroundColor : UIColor.darkBlue as Any
        ])
        attributedText.append(extString)
        button.setAttributedTitle(attributedText, for: .normal)
        return button
    }()
    
    let _resetButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleReset), for: .touchUpInside)
        //
        button.setBackgroundImage(UIImage(named: "Reset"), for: .normal)
        //
        let tempImage = UIImage(systemName: "trash")
        let lightTempImage = tempImage?.withTintColor(UIColor.MRed ?? .gray, renderingMode: .alwaysTemplate)
        let _image = NSTextAttachment(image: lightTempImage!)
        _image.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
        let attributedText =  NSMutableAttributedString(attachment: _image)
        let extString = NSAttributedString(string: " "+"Reset".localized(), attributes: [.font : UIFont(name: Theme.displayFontName, size: 15) as Any,
                                                                                         .foregroundColor : UIColor.MRed as Any
        ])
        attributedText.append(extString)
        button.setAttributedTitle(attributedText, for: .normal)
        
        return button
    }()
    
    @objc private func handleChangeCountry(){
        let CountryListVc = CountryListController(collectionViewLayout: CustomLayout())
        navigationItem.backButtonTitle = ""
        UserDefaults.standard.removeObject(forKey: "country")
        
        //Start : Clean after changing country
        UserDefaults.standard.removeObject(forKey: "stationObjectUrl")
        UserDefaults.standard.removeObject(forKey: "startOnApplaunch")
        //End
        
        AVPlayerSingleton.shared.clearPlayer {
            self.navigationController?.pushViewController(CountryListVc, animated: true)
        }
    }
    
    @objc private func handleReset(){
        let alert = UIAlertController(title: "Reset Application".localized(), message: "Would you like to reset the application to initial setup ?".localized(), preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .default) { _ in
            return
        }
        
        let resetAction = UIAlertAction(title: "Reset".localized(), style: .destructive) { _ in
            self.showIndicator()
            CoreDataManager.shared.resetApp { (countries, error)  in
                DispatchQueue.main.async {
                    let CountryListVc = CountryListController(collectionViewLayout: CustomLayout())
                    CountryListVc._reloadedCountries = countries
                    self.hideIndicator()
                    sleep(3)
                    AVPlayerSingleton.shared.clearPlayer {
                        self.navigationController?.pushViewController(CountryListVc, animated: true)
                    }
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(resetAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showIndicator(){
        self._bottomView.addSubview(activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    func hideIndicator(){
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        _ = BannerManager.shared.setupBannerView(view: view, viewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationItem.title = "Settings".localized()
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = CGRect(x: view.frame.width / 2, y: 100, width: activityIndicator.frame.width, height: activityIndicator.frame.height)
        activityIndicator.style = UIActivityIndicatorView.Style.large
        activityIndicator.color = UIColor.darkBlue

        _settingView.register(SettingsControllerCell.self, forCellReuseIdentifier: cellId)
        _settingView.delegate = self
        _settingView.dataSource = self
        
        
        //Add Settings Table
        view.addSubview(_settingView)
        NSLayoutConstraint.activate([
            _settingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            _settingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _settingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            _settingView.heightAnchor.constraint(equalToConstant: 230)
            // 3 rows + header -- (3 * 60)+48 = 228 + 2  Seprator |<3
        ])
        
        //Bottom View (1/2)
        view.addSubview(_bottomView)
        NSLayoutConstraint.activate([
            _bottomView.topAnchor.constraint(equalTo: _settingView.bottomAnchor),
            _bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            _bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        _bottomView.addSubview(_changeCountryButton)
        NSLayoutConstraint.activate([
            _changeCountryButton.heightAnchor.constraint(equalToConstant: 35),
            _changeCountryButton.widthAnchor.constraint(equalToConstant: 200),
            _changeCountryButton.topAnchor.constraint(equalTo: _bottomView.topAnchor, constant: 20),
            _changeCountryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        _bottomView.addSubview(_resetButton)
        NSLayoutConstraint.activate([
            _resetButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(BannerManager.bannerHeight*2)),
            _resetButton.heightAnchor.constraint(equalToConstant: 35),
            _resetButton.widthAnchor.constraint(equalToConstant: 200),
            _resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let jumbetron = UIView()
        jumbetron.backgroundColor = UIColor.CLJumbetron
        
        let headerLabel: UILabel = {
            let label = UILabel()
            let attributedText = NSMutableAttributedString(string: "User Preferences".localized(),
                                                           attributes: [ .font : UIFont(name: Theme.readFontName, size: 16) as Any,
                                                                         .foregroundColor : UIColor.darkBlue as Any ])
            label.attributedText = attributedText
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        jumbetron.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.centerYAnchor.constraint(equalTo: jumbetron.centerYAnchor),
            headerLabel.centerXAnchor.constraint(equalTo: jumbetron.centerXAnchor)
        ])
        
        return jumbetron
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! SettingsControllerCell
        cell.title = listOfTitles[indexPath.row]
        
        cell.indexPath = indexPath
        cell.viewController = self
        
        return cell
        
    }
}


