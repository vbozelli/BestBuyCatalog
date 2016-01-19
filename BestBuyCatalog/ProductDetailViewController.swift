//
//  ProductDetailViewController.swift
//  BestBuyCatalog
//
//  Created by Victor Bozelli Alvarez on 1/14/16.
//  Copyright © 2016 Bozelli. All rights reserved.
//

import AlamofireImage
import Social
import UIKit

class ProductDetailViewController: UIViewController, UIScrollViewDelegate
{
    let imageDownloader = ImageDownloader.defaultInstance
    var product: Product!
    @IBOutlet var photo: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var name: UILabel!
    @IBOutlet var brand: UILabel!
    @IBOutlet var price: UILabel!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        photo.frame = scrollView.bounds
        scrollView.contentSize = scrollView.bounds.size
        //cached image
        imageDownloader.downloadImage(URLRequest: NSURLRequest(URL: NSURL(string: product.image!)!, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60), filter: ScaledToSizeFilter(size: self.scrollView.bounds.size)) { (response) -> Void in
            self.photo.image = response.result.value
        }
        name.text = "Name: \(product.name!)"
        name.adjustsFontSizeToFitWidth = false
        brand.text = "Brand: \(product.brand!)"
        price.text = "Price: U$ \(product.price)"
    }
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    @IBAction func share(sender: AnyObject)
    {
        let alertController = UIAlertController(title: "Atention", message: "Select the social network to share the product", preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: "Facebook", style: .Default, handler: { (_) -> Void in
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook)
            {
                let composeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                composeViewController.setInitialText("\(self.name.text!)\n\(self.brand.text!)\n\(self.price.text!)")
                composeViewController.addImage(self.photo.image)
                self.presentViewController(composeViewController, animated: true, completion: nil)
            }
            else
            {
                let alertController1 = UIAlertController(title: "Atention", message: "Login on Facebook to share the product", preferredStyle: .Alert)
                alertController1.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (_) -> Void in
                    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                }))
                alertController1.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(alertController1, animated: true, completion: nil)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Twitter", style: .Default, handler: { (_) -> Void in
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter)
            {
                let composeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                composeViewController.setInitialText("\(self.name.text!)\n\(self.brand.text!)\n\(self.price.text!)")
                composeViewController.addImage(self.photo.image)
                self.presentViewController(composeViewController, animated: true, completion: nil)
            }
            else
            {
                let alertController1 = UIAlertController(title: "Atention", message: "Login on Twitter to share the product", preferredStyle: .Alert)
                alertController1.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (_) -> Void in
                    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                }))
                alertController1.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(alertController1, animated: true, completion: nil)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
    {
        return photo
    }
}