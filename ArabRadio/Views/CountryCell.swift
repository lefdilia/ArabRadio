//
//  CountryCell.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 6/5/2021.
//

import UIKit
import SDWebImage

class CountryCell: UICollectionViewCell {
    
    var _country: Country? {
        didSet{
            guard let _country = _country else {return}
            guard let _image = URL(string: _country.image ?? "") else {return}
            
            imageView.sd_setImage(with: _image)  { (image, error, cache, urls) in
                if (error != nil) {
                    self.imageView.image = UIImage(named: "noImage")
                } else {
                    self.imageView.image = image
                }
            }
        }
    }
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius =  6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

