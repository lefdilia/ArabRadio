//
//  RadioListController.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 23/4/2021.
//

import UIKit
import AVKit
import MediaPlayer
import GoogleMobileAds

class RadioListController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var countryChoosed = UserDefaults.standard.string(forKey: "country") ?? ""
    var tableViewMain: Bool = true
    
    var _stations = [Station]()
    let _refreshControl = UIRefreshControl()
    
    var _country: Country? {
        didSet{
            guard let scountry = _country else { return }
            countryChoosed = scountry.title ?? ""
        }
    }
    
    let cellId = "cellId"
    
    @objc private func refreshData() {
        CoreDataManager.shared.updateCountries { (_countries, _error) in
            DispatchQueue.main.async { [weak self] in
                UIView.transition(with: self!.tableView,
                                  duration: 1,
                                  options: .curveEaseOut,
                                  animations: {
                                    self?.reloadData(favorite: false)
                                  }, completion : { _ in
                                    self?._refreshControl.endRefreshing()
                                  })
            }
        }
    }
    
    
    func reloadData(favorite: Bool = false, completion: ()->() = {} ) {
        _stations = CoreDataManager.shared.fetchStations(country: self.countryChoosed, favorite)
        AVPlayerSingleton.shared.playlistStations = self._stations
        self.tableView.reloadData() // To update favorite Status
        completion()
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var timer: Timer?
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self._stations = CoreDataManager.shared.searchStations(country: self.countryChoosed, searchText: searchText)
            
            self.tableView.reloadData()
        })
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self._stations = CoreDataManager.shared.searchStations(country: self.countryChoosed, searchText: "")
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        searchBar.endEditing(true)
    }
    
    var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .white
        table.contentInset.bottom = 120
        return table
    }()
    
    override func viewWillAppear(_ animated: Bool) {

        AVPlayerSingleton.shared.toggleStatusMPRemoteCenter(status: true)
        
        self._starButton.setImage(UIImage(named: "saved-list"), for: .normal)
        self.tableViewMain = true
        
        self.reloadData(favorite: false) {
                        
            if UserDefaults.standard.bool(forKey: "startOnApplaunch") == true
                && AVPlayerSingleton.shared.startupStation == false {
                
                if let objectURL = UserDefaults.standard.url(forKey: "stationObjectUrl") {
                    
                    CoreDataManager.shared.fetchStartStation(objectURL: objectURL) { _station in
                        
                        if self._stations.count > 0 {
                            let stationIndex = self._stations.firstIndex { _sts in
                                return _sts.title == _station.title
                            }
                            
                            guard let _stationIndex = stationIndex else { return }
                            
                            //Trigger player
                            DispatchQueue.main.async {
                                let indexPath = IndexPath(row: _stationIndex, section: 0)
                                self.tableView(self.tableView, didSelectRowAt: indexPath)
                                
                                AVPlayerSingleton.shared.startupStation = true
                                
                            }
                        }
                    }
                }
            }
        }
        
        //returned From Settings
        if AVPlayerSingleton.shared.player.timeControlStatus != .playing {
            playerDetailsView.playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
            playerDetailsView.miniPlayPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        _ = BannerManager.shared.setupBannerView(view: view, viewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.keyboardDismissMode = .onDrag
        
        //Styling searchController && SearchBar
        searchController.searchBar.placeholder = "Hit Radio...".localized()
        searchController.searchBar.searchTextField.backgroundColor = .CLJumbetron
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        //
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        //
        navigationItem.title = "Radio Stations".localized()
        navigationItem.backButtonTitle = ""
        navigationItem.setHidesBackButton(true, animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(handleSetupSettings))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "externaldrive.connected.to.line.below.fill"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(handleAudioFiles))
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.register(RadioListControllerCell.self, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .init(top: 0, left: 31, bottom: 0, right: 31)
        tableView.separatorColor = UIColor.separatorColor
        
        tableView.delegate = self
        tableView.dataSource = self
        
        _refreshControl.addTarget(self, action: #selector(self.refreshData), for: .valueChanged)
        _refreshControl.tintColor = .white
        _refreshControl.attributedTitle = NSMutableAttributedString(string: "Updating Stations".localized(), attributes: [.foregroundColor : UIColor.white, .font : UIFont.systemFont(ofSize: 16, weight: .regular)])
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = _refreshControl
        } else {
            tableView.addSubview(_refreshControl)
        }
        
        //Setup Player Details View
        setupPlayerDetailsView()
        
    }
    
    @objc func handleSetupSettings (){
        let _settingsController = SettingsController()
        navigationController?.pushViewController(_settingsController, animated: true)
    }
    
    @objc func handleAudioFiles (){
        let _savedFilesController = SavedFilesController()
        
        if AVPlayerSingleton.shared.isRecording == true {
            playerDetailsView.finishRecording(success: true)
        }
        
        _savedFilesController.listRecordingFiles { (_records, _) in
            _savedFilesController._audioFiles = _records
            self.navigationController?.pushViewController(_savedFilesController, animated: true)
        }
        
    }
    
    let playerDetailsView = PlayerDetailsView.initFromNib()
    
    var maximizeTopAnchorConstraint: NSLayoutConstraint!
    var minimizeTopAnchorConstraint: NSLayoutConstraint!
    var bottomAnchorConstraint: NSLayoutConstraint!
    
    @objc func minimizePlayerDetails(){
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.maximizeTopAnchorConstraint.isActive = false
        self.bottomAnchorConstraint.constant = view.frame.height
        self.minimizeTopAnchorConstraint.isActive = true
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear) {
            self.view.layoutIfNeeded()
            
            self.playerDetailsView.maximizedStackView.alpha = 0
            self.playerDetailsView.miniPlayerView.alpha = 1
        }
    }
    
    func maximizePlayerDetails(station: Station?){
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        self.minimizeTopAnchorConstraint.isActive = false
        self.maximizeTopAnchorConstraint.isActive = true
        self.maximizeTopAnchorConstraint.constant = 0
        
        self.bottomAnchorConstraint.constant = 0
        
        if station != nil { // not sure if handle it correctly
            playerDetailsView.station = station
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear) {
            self.view.layoutIfNeeded()
            
            self.playerDetailsView.maximizedStackView.alpha = 1
            self.playerDetailsView.miniPlayerView.alpha = 0
        }
    }
    
    
    fileprivate func setupPlayerDetailsView(){
        
        view.addSubview(playerDetailsView)
        
        playerDetailsView.translatesAutoresizingMaskIntoConstraints = false
        
        maximizeTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height)
        maximizeTopAnchorConstraint.isActive = true
        
        minimizeTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -70 - BannerManager.bannerHeight)
        
        bottomAnchorConstraint = playerDetailsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.frame.height)
        bottomAnchorConstraint.isActive = true
        
        playerDetailsView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playerDetailsView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
    }
    
    
    let _starButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "saved-list"), for: .normal)
        button.addTarget(self, action: #selector(handleSavedList), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let jumbetron = UIView()
        jumbetron.backgroundColor = UIColor.CLJumbetron
        
        let headerLabel: UILabel = {
            let label = UILabel()
            let attributedText = NSMutableAttributedString(string: "Stations".localized(), attributes: [ .font : UIFont(name: Theme.readFontName, size: 16) as Any, .foregroundColor : UIColor.darkBlue as Any ])
            label.attributedText = attributedText
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        let _stationIcon: UIImageView = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "stations-list")
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        
        
        jumbetron.addSubview(_stationIcon)
        jumbetron.addSubview(headerLabel)
        jumbetron.addSubview(_starButton)
        
        NSLayoutConstraint.activate([
            _stationIcon.centerYAnchor.constraint(equalTo: jumbetron.centerYAnchor),
            _stationIcon.leadingAnchor.constraint(equalTo: jumbetron.leadingAnchor, constant: 8),
            headerLabel.centerYAnchor.constraint(equalTo: _stationIcon.centerYAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: _stationIcon.trailingAnchor, constant: 7),
            _starButton.centerYAnchor.constraint(equalTo: _stationIcon.centerYAnchor),
            _starButton.trailingAnchor.constraint(equalTo: jumbetron.trailingAnchor, constant: -10)
        ])
        
        return jumbetron
    }
    
    @objc private func handleSavedList(){
        // change star button
        if self.tableViewMain == true {
            self._starButton.setImage(UIImage(named: "tableview"), for: .normal)
            self.reloadData(favorite: true) {
                self.tableViewMain = false //
            }
        }else{
            self._starButton.setImage(UIImage(named: "saved-list"), for: .normal)
            self.reloadData(favorite: false) {
                self.tableViewMain = true //
            }
        }
    }
    
    //MARK - fix empty Tableview
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = "No stations found...".localized()
        label.textColor = .darkBlue
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        
        return label
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return _stations.count == 0 ? 150 : 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 115
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _stations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! RadioListControllerCell
        
        if _stations.count > 0 {
            cell.station = _stations[indexPath.row]
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "") { (_, _, completion) in
            
            let station = self._stations[indexPath.row]
            
            self._stations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            let context = CoreDataManager.shared.persistentContainer.viewContext
            context.delete(station)
            
            try? context.save()
            completion(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        let swipes = UISwipeActionsConfiguration(actions: [deleteAction])
        return swipes
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let _station = _stations[indexPath.row]
        self.maximizePlayerDetails(station: _station)
        self.searchController.searchBar.endEditing(true)
    }
}


