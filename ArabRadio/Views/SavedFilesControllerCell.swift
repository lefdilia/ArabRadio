//
//  SavedFilesControllerCell.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 8/7/2021.
//

import UIKit
import AVKit
import MediaPlayer

class SavedFilesControllerCell: UITableViewCell {
    
    var selectionCallback: (() -> Void)?
    
    var stopCallback: (() -> Void)?
    
    var recordPlayer: AVPlayer!
    
    var timePlayed: Double = 0
    var playerTimeObserver: Any?
    
    
    var recordFile: Records? {
        didSet {
            guard let recordFile = recordFile else {return}
            
            _fileTitle.text = recordFile.name
            _sizeLabel.text = recordFile.size
            
            let df = DateFormatter()
            df.dateFormat = "dd-MM-yyyy HH.mm.ss"
            
            let creationDate = df.string(from: recordFile.creationDate).replacingOccurrences(of: ".", with: ":")
            _creationDateLabel.text = creationDate
        }
    }
    
    lazy var _playPauseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "AVPlay")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handlePlayRecord), for: .touchUpInside)
        return button
    }()
    
    let _creationDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: Theme.readFontName, size: 13)
        label.textColor = UIColor.darkBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    let _fileTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: Theme.displayFontName, size: 16)
        label.textColor = UIColor.darkBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let _sizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: Theme.readFontName, size: 12)
        label.textColor = UIColor.darkBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .MRed
        return label
    }()
    
    lazy var vStackView: UIStackView = {
        let stack =  UIStackView(arrangedSubviews: [_fileTitle, _sizeLabel])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    @objc func handlePlayRecord(_ sender: UIButton){
        self.selectionCallback?()
        
        guard let stream = recordFile?.path.absoluteString else { return }
        guard let streamUrl = URL(string: stream) else { return }
        
        self._playPauseButton.setImage(UIImage(named: "AVStop"), for: .normal)
        
        let asset = AVURLAsset(url: streamUrl)
        let playerItem = AVPlayerItem(asset: asset)
        
        self.recordPlayer.replaceCurrentItem(with: playerItem)
        self.recordPlayer.volume = 1.0
        self.recordPlayer.play()
        
        
        let interval = CMTime.init(value: 1, timescale: 2)
        self.playerTimeObserver = recordPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            self.timePlayed = CMTimeGetSeconds(time)
            
            let duration =  CMTimeGetSeconds(self.recordPlayer.currentItem?.duration ?? CMTimeMake(value: 999999, timescale: 1))
            if self.timePlayed >= duration {
                self._playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
            }
        }
    }
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .white
        selectionStyle = .none
        
        contentView.addSubview(_playPauseButton)
        NSLayoutConstraint.activate([
            _playPauseButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            _playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            _playPauseButton.heightAnchor.constraint(equalToConstant: 40),
            _playPauseButton.widthAnchor.constraint(equalToConstant: 40),
        ])
        
        addSubview(vStackView)
        NSLayoutConstraint.activate([
            vStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            vStackView.leadingAnchor.constraint(equalTo: _playPauseButton.trailingAnchor, constant: 10)
        ])
        
        addSubview(_creationDateLabel)
        NSLayoutConstraint.activate([
            _creationDateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            _creationDateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            _creationDateLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
