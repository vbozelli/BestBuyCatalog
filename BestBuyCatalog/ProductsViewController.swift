//
//  ProductsCollectionViewController.swift
//  BestBuyCatalog
//
//  Created by Victor Bozelli Alvarez on 1/13/16.
//  Copyright © 2016 Bozelli. All rights reserved.
//

import Alamofire
import AlamofireImage
import CoreData
import UIKit

class ProductsViewController: UIViewController, UICollectionViewDataSource, UISearchBarDelegate
{
    let application = UIApplication.sharedApplication()
    let context: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    let imageDownloader = ImageDownloader.defaultInstance
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var ascending = false
    var page = 1
    var products1Model: [ProductModel] = []
    var productsModel: [ProductModel] = []
    var products: [Product] = []
    var search = false
    var request: Request?
    var refreshControlTop: UIRefreshControl!
    var refreshControlBottom: UIRefreshControl!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView?
    @IBOutlet var productsCollectionView: UICollectionView!
    @IBOutlet var searchBar: UISearchBar!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let imageView = UIImageView(image: UIImage(named: "sort"))
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("sort")))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: imageView)
        refreshControlTop = UIRefreshControl()
        refreshControlTop.tintColor = UIColor.whiteColor()
        refreshControlTop.addTarget(self, action: Selector("refreshTop"), forControlEvents: .ValueChanged)
        productsCollectionView.addSubview(refreshControlTop)
        refreshControlBottom = UIRefreshControl()
        refreshControlBottom.tintColor = UIColor.whiteColor()
        refreshControlBottom.addTarget(self, action: Selector("refreshBottom"), forControlEvents: .ValueChanged)
        productsCollectionView.bottomRefreshControl = refreshControlBottom
        let searchField = searchBar.valueForKey("searchField") as! UITextField
        searchField.textColor = UIColor.whiteColor()
        let searchIcon = searchField.leftView as! UIImageView
        searchIcon.image = searchIcon.image?.imageWithRenderingMode(.AlwaysTemplate)
        searchIcon.tintColor = UIColor.whiteColor()
        var results: [Product] = []
        do
        {
            try results = self.context.executeFetchRequest(NSFetchRequest(entityName: "Product")) as! [Product]
        }
        catch(_)
        {
        }
        if results.count > 0
        {
            for product in results
            {
                let productModel = ProductModel()
                productModel.name = product.name
                productModel.brand = product.brand
                productModel.price = product.price
                productModel.imageUrl = product.image
                productModel.largeImageUrl = product.largeImage
                productsModel.append(productModel)
            }
        }
        else
        {
            activityIndicatorView!.startAnimating()
            application.networkActivityIndicatorVisible = true
            Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO)", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk"], encoding: .URL, headers: nil).responseJSON(completionHandler: { (response) -> Void in
                self.activityIndicatorView!.stopAnimating()
                self.application.networkActivityIndicatorVisible = false
                if response.result.error == nil
                {
                    let productsResult: NSArray = response.result.value!["products"] as! NSArray
                    for product in productsResult
                    {
                        let productModel = ProductModel()
                        let productInsert = NSEntityDescription.insertNewObjectForEntityForName("Product", inManagedObjectContext: self.context) as! Product
                        let keys: [String] = (product as! NSDictionary).allKeys as! [String]
                        if keys.contains("name")
                        {
                            if !(product["name"] is NSNull)
                            {
                                let name = product["name"] as! String
                                productInsert.name = name
                                productModel.name = name
                            }
                            else
                            {
                                productInsert.name = "Unknown"
                                productModel.name = "Unknown"
                            }
                        }
                        else
                        {
                            productInsert.name = "Unknown"
                            productModel.name = "Unknown"
                        }
                        if keys.contains("manufacturer")
                        {
                            if !(product["manufacturer"] is NSNull)
                            {
                                let brand = product["manufacturer"] as! String
                                productInsert.brand = brand
                                productModel.brand = brand
                            }
                            else
                            {
                                productInsert.brand = "Unknown"
                                productModel.brand = "Unknown"
                            }
                        }
                        else
                        {
                            productInsert.brand = "Unknown"
                            productModel.brand = "Unknown"
                        }
                        if keys.contains("salePrice")
                        {
                            if !(product["salePrice"] is NSNull)
                            {
                                let price = product["salePrice"] as! Float
                                productInsert.price = price
                                productModel.price = price
                            }
                            else
                            {
                                productInsert.price = 0
                                productModel.price = 0
                            }
                        }
                        else
                        {
                            productInsert.price = 0
                            productModel.price = 0
                        }
                        if keys.contains("image")
                        {
                            if !(product["image"] is NSNull)
                            {
                                let image = product["image"] as! String
                                productInsert.image = image
                                productModel.imageUrl = image
                            }
                            else
                            {
                                productInsert.image = nil
                                productModel.imageUrl = nil
                            }
                        }
                        else
                        {
                            productInsert.image = nil
                            productModel.imageUrl = nil
                        }
                        if keys.contains("largeImage")
                        {
                            if !(product["largeImage"] is NSNull)
                            {
                                let largeImage = product["largeImage"] as! String
                                productInsert.largeImage = largeImage
                            }
                            else
                            {
                                productInsert.largeImage = nil
                            }
                        }
                        else
                        {
                            productInsert.largeImage = nil
                        }
                        self.productsModel.append(productModel)
                        self.products.append(productInsert)
                        self.context.insertObject(productInsert)
                    }
                    self.productsCollectionView.reloadData()
                    do
                    {
                        try self.context.save()
                    }
                    catch(_)
                    {
                    }
                }
                else if response.result.error?.code == NSURLErrorNotConnectedToInternet
                {
                    let alertViewController = UIAlertController(title: "Atention", message: "Internet connection not available", preferredStyle: .Alert)
                    alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(alertViewController, animated: true, completion: nil)
                }
            })
        }
        if userDefaults.dictionaryRepresentation().keys.contains("page")
        {
            userDefaults.setInteger(page, forKey: "page")
        }
        else
        {
            page = userDefaults.integerForKey("page")
        }
    }
    func sort()
    {
        if ascending
        {
            UIView.animateWithDuration(0.5, animations: {
                self.navigationItem.rightBarButtonItem?.customView?.transform = CGAffineTransformIdentity
            })
            productsModel.sortInPlace { (productModel1, productModel2) -> Bool in
                return productModel1.price > productModel2.price
            }
        }
        else
        {
            UIView.animateWithDuration(0.5, animations: {
                self.navigationItem.rightBarButtonItem?.customView?.transform = CGAffineTransformMakeRotation((180.0 * CGFloat(M_PI)) / 180.0)
            })
            productsModel.sortInPlace { (productModel1, productModel2) -> Bool in
                return productModel1.price < productModel2.price
            }
        }
        ascending = !ascending
        productsCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: .Top, animated: true)
        productsCollectionView.reloadData()
    }
    func refreshTop()
    {
        application.networkActivityIndicatorVisible = true
        Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO)", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk"], encoding: .URL, headers: nil).responseJSON(completionHandler: { (response) -> Void in
            self.activityIndicatorView!.stopAnimating()
            self.application.networkActivityIndicatorVisible = false
            if response.result.error == nil
            {
                let productsResult: NSArray = response.result.value!["products"] as! NSArray
                for product in productsResult
                {
                    let productModel = ProductModel()
                    let productInsert = NSEntityDescription.insertNewObjectForEntityForName("Product", inManagedObjectContext: self.context) as! Product
                    let keys: [String] = (product as! NSDictionary).allKeys as! [String]
                    if keys.contains("name")
                    {
                        if product["name"] != nil
                        {
                            let name = product["name"] as! String
                            productInsert.name = name
                            productModel.name = name
                        }
                        else
                        {
                            productInsert.name = "Unknown"
                            productModel.name = "Unknown"
                        }
                    }
                    else
                    {
                        productInsert.name = "Unknown"
                        productModel.name = "Unknown"
                    }
                    if keys.contains("manufacturer")
                    {
                        if product["manufacturer"] != nil
                        {
                            let brand = product["manufacturer"] as! String
                            productInsert.brand = brand
                            productModel.brand = brand
                        }
                        else
                        {
                            productInsert.brand = "Unknown"
                            productModel.brand = "Unknown"
                        }
                    }
                    else
                    {
                        productInsert.brand = "Unknown"
                        productModel.brand = "Unknown"
                    }
                    if keys.contains("salePrice")
                    {
                        if product["salePrice"] != nil
                        {
                            let price = product["salePrice"] as! Float
                            productInsert.price = price
                            productModel.price = price
                        }
                        else
                        {
                            productInsert.price = 0
                            productModel.price = 0
                        }
                    }
                    else
                    {
                        productInsert.price = 0
                        productModel.price = 0
                    }
                    if keys.contains("image")
                    {
                        if product["image"] != nil
                        {
                            let image = product["image"] as! String
                            productInsert.image = image
                            productModel.imageUrl = image
                        }
                        else
                        {
                            productInsert.image = nil
                            productModel.imageUrl = nil
                        }
                    }
                    else
                    {
                        productInsert.image = nil
                        productModel.imageUrl = nil
                    }
                    if keys.contains("largeImage")
                    {
                        if product["largeImage"] != nil
                        {
                            let largeImage = product["largeImage"] as! String
                            productInsert.largeImage = largeImage
                        }
                        else
                        {
                            productInsert.largeImage = nil
                        }
                    }
                    else
                    {
                        productInsert.largeImage = nil
                    }
                    self.productsModel.append(productModel)
                    self.products.append(productInsert)
                    self.context.insertObject(productInsert)
                }
                self.productsCollectionView.reloadData()
                do
                {
                    try self.context.save()
                }
                catch(_)
                {
                }
            }
            else if response.result.error?.code == NSURLErrorNotConnectedToInternet
            {
                let alertViewController = UIAlertController(title: "Atention", message: "Internet connection not available", preferredStyle: .Alert)
                alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alertViewController, animated: true, completion: nil)
            }
        })
    }
    func refreshBottom()
    {
        page++
        userDefaults.setInteger(page, forKey: "page")
        application.networkActivityIndicatorVisible = true
        Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO)", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "page" : page, "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk"], encoding: .URL, headers: nil).responseJSON(completionHandler: { (response) -> Void in
            self.activityIndicatorView!.stopAnimating()
            self.application.networkActivityIndicatorVisible = false
            if response.result.error == nil
            {
                let productsResult: NSArray = response.result.value!["products"] as! NSArray
                for product in productsResult
                {
                    let productModel = ProductModel()
                    let productInsert = NSEntityDescription.insertNewObjectForEntityForName("Product", inManagedObjectContext: self.context) as! Product
                    let name = product["name"] as! String
                    productInsert.name = name
                    productModel.name = name
                    if ((product as! NSDictionary).allKeys as! [String]).contains("manufacturer")
                    {
                        let brand = product["manufacturer"] as! String
                        productInsert.brand = brand
                        productModel.brand = brand
                    }
                    else
                    {
                        productInsert.brand = "Unknown"
                        productModel.brand = "Unknown"
                    }
                    let price = product["salePrice"] as! Float
                    productInsert.price = price
                    self.products.append(productInsert)
                    productModel.price = price
                    productModel.imageUrl = product["image"] as? String
                    productModel.largeImageUrl = product["largeImage"] as? String
                    self.productsModel.append(productModel)
                    self.context.insertObject(productInsert)
                }
                self.productsCollectionView.reloadData()
                do
                {
                    try self.context.save()
                }
                catch(_)
                {
                }
            }
            else if response.result.error?.code == NSURLErrorNotConnectedToInternet
            {
                let alertViewController = UIAlertController(title: "Atention", message: "Internet connection not available", preferredStyle: .Alert)
                alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alertViewController, animated: true, completion: nil)
            }
        })
    }
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1;
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if !search
        {
            if productsModel.count == 0
            {
                refreshControlTop.enabled = false
                refreshControlBottom.enabled = false
            }
            else
            {
                refreshControlTop.enabled = true
                refreshControlBottom.enabled = true
            }
            return productsModel.count;
        }
        else
        {
            if products1Model.count == 0
            {
                refreshControlTop.enabled = false
                refreshControlBottom.enabled = false
            }
            else
            {
                refreshControlTop.enabled = true
                refreshControlBottom.enabled = true
            }
            return products1Model.count;
        }
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ProductCollectionViewCell
        cell.layer.cornerRadius = 10
        cell.brand.adjustsFontSizeToFitWidth = false
        var product: ProductModel!
        if !search
        {
            product = productsModel[indexPath.row]
        }
        else
        {
            product = products1Model[indexPath.row]
        }
        cell.brand.text = "Brand: \(product.brand)"
        cell.name.adjustsFontSizeToFitWidth = false
        cell.name.text = "Name: \(product.name)"
        cell.price.text = "Price: U$ \(product.price)"
        cell.photo.image = nil
        cell.activityIndicatorView.startAnimating()
        if product.imageUrl != nil && product.imageUrl != ""
        {
            imageDownloader.downloadImage(URLRequest: NSURLRequest(URL: NSURL(string: product.imageUrl!)!, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60), filter: ScaledToSizeFilter(size: CGSize(width: cell.photo.frame.width, height: cell.photo.frame.height)), completion: { (response) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    cell.activityIndicatorView.stopAnimating()
                    let cell1 = collectionView.cellForItemAtIndexPath(indexPath) as? ProductCollectionViewCell
                    if cell1 != nil
                    {
                        cell1!.photo.image = response.result.value
                    }
                })
            })
        }
        else if product.largeImageUrl != nil && product.largeImageUrl != ""
        {
            imageDownloader.downloadImage(URLRequest: NSURLRequest(URL: NSURL(string: product.largeImageUrl!)!, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60), filter: ScaledToSizeFilter(size: CGSize(width: cell.photo.frame.width, height: cell.photo.frame.height)), completion: { (response) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    cell.activityIndicatorView.stopAnimating()
                    let cell1 = collectionView.cellForItemAtIndexPath(indexPath) as? ProductCollectionViewCell
                    if cell1 != nil
                    {
                        cell1!.photo.image = response.result.value
                    }
                })
            })
        }
        return cell
    }
    func searchBarTextDidBeginEditing(searchBar: UISearchBar)
    {
        search = true
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        if searchText != ""
        {
//            products1Model = productsModel.filter({ (product) -> Bool in
//                return product.name.hasPrefix(searchText)
//            })
//            if products1Model.count > 0
//            {
//                productsCollectionView.reloadData()
//            }
//            else
//            {
//                products1Model = []
//                productsCollectionView.reloadData()
//                application.networkActivityIndicatorVisible = true
//                activityIndicatorView.startAnimating()
//                request = Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO&search=\(searchText))", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk"], encoding: .URL, headers: nil).responseData({ (response) -> Void in
//                    self.activityIndicatorView.stopAnimating()
//                    self.application.networkActivityIndicatorVisible = false
//                    if response.result.error == nil
//                    {
//                        let productsResult = JSON(data: response.result.value!)["products"].arrayValue
//                        for product in productsResult
//                        {
//                            let productModel = ProductModel()
//                            let productInsert = NSEntityDescription.insertNewObjectForEntityForName("Product", inManagedObjectContext: self.context) as! Product
//                            productInsert.name = product["name"].stringValue
//                            productModel.name = product["name"].stringValue
//                            if product["manufacturer"] == nil
//                            {
//                                productInsert.brand = "Unknown"
//                                productModel.brand = "Unknown"
//                            }
//                            else
//                            {
//                                productInsert.brand = product["manufacturer"].stringValue
//                                productModel.brand = product["manufacturer"].stringValue
//                            }
//                            productInsert.price = product["salePrice"].floatValue
//                            self.products.append(productInsert)
//                            productModel.price = product["salePrice"].floatValue
//                            productModel.imageUrl = product["image"].stringValue
//                            productModel.largeImageUrl = product["largeImage"].stringValue
//                            self.products1Model.append(productModel)
//                            self.context.insertObject(productInsert)
//                        }
//                        self.productsCollectionView.reloadData()
//                        do
//                        {
//                            try self.context.save()
//                        }
//                        catch(_)
//                        {
//                        }
//                    }
//                    else if response.result.error?.code == NSURLErrorNotConnectedToInternet
//                    {
//                        let alertViewController = UIAlertController(title: "Atention", message: "Internet connection not available", preferredStyle: .Alert)
//                        alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
//                        self.presentViewController(alertViewController, animated: true, completion: nil)
//                    }
//                })
//            }
        }
        else
        {
            products1Model = productsModel
            productsCollectionView.reloadData()
        }
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        request?.cancel()
        search = false
        searchBar.text = ""
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "productDetail"
        {
            let productDetailViewController = segue.destinationViewController as! ProductDetailViewController
            if search
            {
                productDetailViewController.product = products1Model[productsCollectionView.indexPathsForSelectedItems()![0].row]
            }
            else
            {
                productDetailViewController.product = productsModel[productsCollectionView.indexPathsForSelectedItems()![0].row]
            }
        }
    }
}