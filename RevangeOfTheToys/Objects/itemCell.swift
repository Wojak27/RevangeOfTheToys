//
//  itemCell.swift
//  RevangeOfTheToys
//
//  Created by Karol Wojtulewicz on 2019-01-15.
//  Copyright © 2019 Karol Wojtulewicz. All rights reserved.
//

import UIKit

class itemCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func setImage(image: UIImage){
        imageView.image = image
        imageView.layer.cornerRadius = 50.0
    }
}
