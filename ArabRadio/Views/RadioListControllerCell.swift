//
//  RadioListControllerCell.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 24/4/2021.
//

import UIKit

class RadioListControllerCell: UITableViewCell {
    
    var station: Station? {
        didSet {
            guard let station = station else {return}
                    
            _radioTitle.text = station.title
            
            let _signal = station.signal ?? "Stream".localized()
            
            let _type = (station.type ?? []).map{
                $0.capitalizingFirstLetter()
            }.joined(separator: ", ")

            let attributedText = NSMutableAttributedString(string: _type,
                                                           attributes: [.font : UIFont(name: Theme.mainFontName, size: 14) as Any,
                                                                        .foregroundColor : UIColor.darkBlue as Any])
            attributedText.append(NSMutableAttributedString(string: "\n"+"Signal".localized(),
                                                            attributes: [.font : UIFont(name: Theme.displayFontName, size: 14) as Any,
                                                                                             .foregroundColor : UIColor.darkBlue as Any ]))
            attributedText.append(NSMutableAttributedString(string: " : \(_signal.capitalizingFirstLetter())",
                                                            attributes: [.font : UIFont(name: Theme.mainFontName, size: 14) as Any,
                                                                         .foregroundColor : UIColor.darkBlue as Any ]))
            
            _radioDescription.attributedText = attributedText
            
            let isFavorite =  station.isFavorite == true ? "station-remove-L" : "station-add-L"
            _favoriteStation.setImage(UIImage(named: isFavorite), for: .normal)
            
             let _image = URL(string: station.image ?? "") 
            
            _imageView.sd_setImage(with: _image)  { (image, error, cache, urls) in
                
                if (error != nil) {
                    self._imageView.image = UIImage(named: "RadioImage")
                } else {
                    self._imageView.image = image
                }
            }
        }
    }
    
    let _imageView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "radioImage"))
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    let _radioTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: Theme.displayFontName, size: 19.0)
        label.textColor = UIColor.darkBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var _radioDescription: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isSelectable = false
        return textView
    }()
    
    
    lazy var _favoriteStation: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "station-add-L"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleSaveSelector), for: .touchUpInside)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .white
        selectionStyle = .none
        
        addSubview(_imageView)
        NSLayoutConstraint.activate([
            _imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            _imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            _imageView.heightAnchor.constraint(equalToConstant: 72),
            _imageView.widthAnchor.constraint(equalToConstant: 70),
        ])
        
        addSubview(_radioTitle)
        NSLayoutConstraint.activate([
            _radioTitle.topAnchor.constraint(equalTo: _imageView.topAnchor),
            _radioTitle.leadingAnchor.constraint(equalTo: _imageView.trailingAnchor, constant: 12),
            _radioTitle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 51),
            _radioTitle.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        addSubview(_radioDescription)
        NSLayoutConstraint.activate([
            _radioDescription.topAnchor.constraint(equalTo: _radioTitle.bottomAnchor),
            _radioDescription.leadingAnchor.constraint(equalTo: _imageView.trailingAnchor, constant: 5),
            _radioDescription.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            _radioDescription.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        contentView.addSubview(_favoriteStation)
        NSLayoutConstraint.activate([
            _favoriteStation.topAnchor.constraint(equalTo: _radioTitle.topAnchor),
            _favoriteStation.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -18),
            _favoriteStation.heightAnchor.constraint(equalToConstant: 24),
            _favoriteStation.widthAnchor.constraint(equalToConstant: 24)
        ])
        
        
    }
    
    //Functions
    @objc private func handleSaveSelector(){
        
        guard let _station = station else { return }
        
        CoreDataManager.shared.updateFavorite(station: _station, completion: { (isFavorite, error) in
            
            guard let _isFavorite = isFavorite, error == nil else { return }
            
            let isFavorite = _isFavorite == true ? "station-remove-L" : "station-add-L"
            
            self._favoriteStation.setImage(UIImage(named: isFavorite), for: .normal)

        })
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
