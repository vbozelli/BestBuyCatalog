//
//  ProductCollectionViewCell.swift
//  BestBuyCatalog
//
//  Created by Victor Bozelli Alvarez on 1/13/16.
//  Copyright © 2016 Bozelli. All rights reserved.
//

import UIKit

class ProductCollectionViewCell: UICollectionViewCell
{
    @IBOutlet var photo: UIImageView!
    @IBOutlet var price: UILabel!
    @IBOutlet var name: UILabel!
    @IBOutlet var brand: UILabel!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
}