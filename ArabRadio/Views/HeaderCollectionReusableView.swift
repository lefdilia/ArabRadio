//
//  HeaderCollectionReusableView.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 6/5/2021.
//

import UIKit

class HeaderCollectionReusableView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let _jumbetron: UIView = {
            let jumbetronView = UIView()
            jumbetronView.translatesAutoresizingMaskIntoConstraints = false
            jumbetronView.backgroundColor = UIColor.CLJumbetron
            return jumbetronView
        }()
        
        let headerLabel: UILabel = {
            let label = UILabel()
            let attributedText = NSMutableAttributedString(string: "Country List".localized(),
                                                           attributes: [NSAttributedString.Key.font : UIFont(name: Theme.readFontName, size: 16) as Any, NSAttributedString.Key.foregroundColor : UIColor.darkBlue as Any ])
            label.attributedText = attributedText
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        let _stationIcon: UIImageView = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "flag")
            imageView.tintColor = UIColor.lightGreen
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        
        
        
        // MARK: - Add Top View
        addSubview(_jumbetron)
        NSLayoutConstraint.activate([
            _jumbetron.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            _jumbetron.leadingAnchor.constraint(equalTo: leadingAnchor),
            _jumbetron.trailingAnchor.constraint(equalTo: trailingAnchor),
            _jumbetron.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        _jumbetron.addSubview(_stationIcon)
        _jumbetron.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            _stationIcon.centerYAnchor.constraint(equalTo: _jumbetron.centerYAnchor),
            _stationIcon.leadingAnchor.constraint(equalTo: _jumbetron.leadingAnchor, constant: 8),
            headerLabel.centerYAnchor.constraint(equalTo: _stationIcon.centerYAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: _stationIcon.trailingAnchor, constant: 7)
        ])
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
