//
//  ProductDetailViewController.swift
//  BestBuyCatalog
//
//  Created by Victor Bozelli Alvarez on 1/14/16.
//  Copyright © 2016 Bozelli. All rights reserved.
//

import UIKit

class ProductDetailViewController: UIViewController, UIScrollViewDelegate
{
    var product: ProductModel!
    @IBOutlet var photo: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var name: UILabel!
    @IBOutlet var brand: UILabel!
    @IBOutlet var price: UILabel!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        photo.frame = CGRect(x: 0, y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
        //photo.image = product.image
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: scrollView.frame.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height), animated: true)
        name.text = "Name: \(product.name)"
        brand.text = "Brand: \(product.brand)"
        price.text = "Price: U$ \(product.price)"
    }
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
    {
        return photo
    }
}