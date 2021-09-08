//
//  SavedFilesController.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 8/7/2021.
//

import UIKit
import AVKit
import MediaPlayer


class SavedFilesController: UIViewController {
    
    var _audioFiles = [Records]()
    
    var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .white
        table.contentInset.bottom = 120 // try to add it only when mini player exist + extend more until 150 (small iphone size PR)
        return table
    }()
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent {
            AVPlayerSingleton.shared.stopPlayer { _ in }
        }
    }
    
    let cellId = "cellId"
        
    override func viewDidAppear(_ animated: Bool) {
        _ = BannerManager.shared.setupBannerView(view: view, viewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Recorded Audio Files".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(handleSetupSettings))
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.register(SavedFilesControllerCell.self, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .init(top: 0, left: 31, bottom: 0, right: 31)
        tableView.separatorColor = UIColor.separatorColor
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    
    @objc func handleSetupSettings (){
        let _settingsController = SettingsController()
        navigationController?.pushViewController(_settingsController, animated: true)
    }
    
    
    func listRecordingFiles(completion: @escaping ([Records], Error?)->() ){
        
        var files: [Records] = []
        
        let recordingFolder = AppConfig.recording.folder
        let manager = FileManager.default
        
        guard let documentDirectory = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return completion([], "Error Finding .DocumentDirectory" as? Error)
        }
        
        let group = DispatchGroup()
        let _folderPath = documentDirectory.appendingPathComponent(recordingFolder)
        
        do {
            
            let items = try manager.contentsOfDirectory(at: _folderPath, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: .skipsHiddenFiles)
            
            for item in items {
                
                group.enter()
                
                let fileName = item.lastPathComponent
                let _path = _folderPath.appendingPathComponent(fileName)
                let _size = _path.fileSizeString
                let _creationDate = _path.creationDate ?? Date()
                
                var fm = fileName as NSString
                fm = fm.deletingPathExtension as NSString
                
                let _name = fm.components(separatedBy: "|").first
                
                files.append(Records(name: _name ?? fm as String, size: _size, creationDate: _creationDate, path: _path))
                group.leave()
                
            }
            
            group.notify(queue: .main) {
                let sortedFiles = files.sorted {$0.creationDate.compare($1.creationDate) == .orderedDescending}
                completion(sortedFiles, nil)
            }
            
        } catch let errorDirectory {
            completion(files, errorDirectory.localizedDescription as? Error)
        }
        
    }
    
    var recordPlayer: AVPlayer = {
        let player = AVPlayer()
        return player
    }()
    
    var playerTimeObserver: Any?
    var timePlayed: Double = 0
    
}

extension SavedFilesController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let jumbetron = UIView()
        jumbetron.backgroundColor = UIColor.CLJumbetron
        
        let headerLabel: UILabel = {
            let label = UILabel()
            let attributedText = NSMutableAttributedString(string: "Recorded Files".localized(), attributes: [ .font : UIFont(name: Theme.readFontName, size: 16) as Any, .foregroundColor : UIColor.darkBlue as Any ])
            label.attributedText = attributedText
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        let _recordIcon: UIImageView = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "RecordButton")
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        
        jumbetron.addSubview(_recordIcon)
        jumbetron.addSubview(headerLabel)
        
        NSLayoutConstraint.activate([
            _recordIcon.centerYAnchor.constraint(equalTo: jumbetron.centerYAnchor),
            _recordIcon.leadingAnchor.constraint(equalTo: jumbetron.leadingAnchor, constant: 8),
            headerLabel.centerYAnchor.constraint(equalTo: _recordIcon.centerYAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: _recordIcon.trailingAnchor, constant: 7)
        ])
        return jumbetron
    }
    
    private func createLinkToFile(atURL fileURL: URL, withName fileName: String) -> URL? {
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let linkURL = tempDirectoryURL.appendingPathComponent(fileName)
        do {
            if fileManager.fileExists(atPath: linkURL.path) {
                try fileManager.removeItem(at: linkURL)
            }
            try fileManager.linkItem(at: fileURL, to: linkURL)
            return linkURL
        } catch {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let fileManager = FileManager.default
        
        let shareAction = UIContextualAction(style: .normal, title: "") { (_, _, completion) in
            
            let recordFile = self._audioFiles[indexPath.row]
            let audioFile = recordFile.path.relativePath
            
            let df = DateFormatter()
            df.dateFormat = "MM-dd-yyyy HH.mm.ss"
            let creationDate = df.string(from: recordFile.creationDate).replacingOccurrences(of: ".", with: ":")
            
            let sharedMessage = "\("Recording".localized()) \(recordFile.name) \(creationDate).mp3"
            
            if fileManager.fileExists(atPath: audioFile) {
                
                let audioData = self.createLinkToFile(atURL: URL(fileURLWithPath: audioFile), withName: sharedMessage)
                
                guard let audioData = audioData else { return completion(false) }
                
                let activityViewController = UIActivityViewController(activityItems: [audioData], applicationActivities: nil)   // and present it
                
                activityViewController.excludedActivityTypes = [.airDrop]
                
                if let popoverController = activityViewController.popoverPresentationController {
                    popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                    popoverController.sourceView = self.view
                    popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                }
                
                DispatchQueue.main.async {
                    activityViewController.completionWithItemsHandler = { activity, success, items, error in
                        UINavigationBar.appearance().tintColor = .white
                        activityViewController.dismiss(animated: true)
                    }
                    
                    self.present(activityViewController, animated: true) {() -> Void in
                        UINavigationBar.appearance().tintColor = .darkBlue
                        completion(true)
                    }
                }
            }
        }
        
        
        let deleteAction = UIContextualAction(style: .destructive, title: "") { (_, _, completion) in
            
            let recordFile = self._audioFiles[indexPath.row]
            let audioFile = recordFile.path.relativePath
            
            if  fileManager.fileExists(atPath: audioFile) {
                
                do {
                    try fileManager.removeItem(atPath: audioFile)
                    self._audioFiles.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                    
                } catch{ }
            }
            completion(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        shareAction.backgroundColor = .extraColor
        
        let swipes = UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
        return swipes
        
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        
        AVPlayerSingleton.shared.stopPlayer { _ in
            let cells = self.tableView.visibleCells as! [SavedFilesControllerCell]
            cells.forEach { _cell in
                _cell._playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
                _cell._playPauseButton.isEnabled = true
            }
        }
    }
    
    //MARK - fix empty Tableview
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = "No recording files found".localized()
        label.textColor = .darkBlue
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return _audioFiles.count == 0 ? 150 : 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self._audioFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! SavedFilesControllerCell
        
        cell._playPauseButton.tag = indexPath.row
        cell.recordFile = self._audioFiles[indexPath.row]
        
        cell.recordPlayer = AVPlayerSingleton.shared.player
        
        cell.selectionCallback = {
            AVPlayerSingleton.shared.toggleStatusMPRemoteCenter(status: false)
                        
            cell.timePlayed = self.timePlayed
            cell.playerTimeObserver = self.playerTimeObserver
            
            if let token = self.playerTimeObserver {
                self.recordPlayer.removeTimeObserver(token)
                self.playerTimeObserver = nil
            }
            
            let cells = self.tableView.visibleCells as! [SavedFilesControllerCell]
            cells.forEach { _cell in
                _cell._playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
            }
            
        }
        
        return cell
    }

    

    
}


