//
//  ProductsCollectionViewController.swift
//  BestBuyCatalog
//
//  Created by Victor Bozelli Alvarez on 1/13/16.
//  Copyright © 2016 Bozelli. All rights reserved.
//

import Alamofire
import CoreData
import SwiftyJSON
import UIKit

class ProductsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate
{
    let application = UIApplication.sharedApplication()
    let context: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    let folder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
    var ascending = false
    var page = 1
    var products1Model: [ProductModel] = []
    var productsModel: [ProductModel] = []
    var products: [Product] = []
    var search = false
    var request: Request! = nil
    var refreshControlTop: UIRefreshControl!
    var refreshControlBottom: UIRefreshControl!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var productsCollectionView: UICollectionView!
    @IBOutlet var searchBar: UISearchBar!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let imageView = UIImageView(image: UIImage(named: "sort"))
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("sort")))
        let barButtonItem = UIBarButtonItem(customView: imageView)
        barButtonItem.style = .Plain
        barButtonItem.target = self
        barButtonItem.action = Selector("sort")
        self.navigationItem.rightBarButtonItem = barButtonItem
        refreshControlTop = UIRefreshControl()
        refreshControlTop.tintColor = UIColor.whiteColor()
        refreshControlTop.addTarget(self, action: Selector("refreshTop"), forControlEvents: .ValueChanged)
        productsCollectionView.addSubview(refreshControlTop)
        refreshControlBottom = UIRefreshControl()
        refreshControlBottom.tintColor = UIColor.whiteColor()
        refreshControlBottom.addTarget(self, action: Selector("refreshBottom"), forControlEvents: .ValueChanged)
        productsCollectionView.bottomRefreshControl = refreshControlBottom
        searchBar.delegate = self
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
                productModel.image = UIImage(data: product.image!)
                productsModel.append(productModel)
            }
        }
        else
        {
            activityIndicatorView.startAnimating()
            application.networkActivityIndicatorVisible = true
            Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO)", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk"], encoding: .URL, headers: nil).responseData { (response) in
                self.refreshControlTop.enabled = true
                self.activityIndicatorView.stopAnimating()
                self.application.networkActivityIndicatorVisible = false
                if response.result.error == nil
                {
                    let productsResult = JSON(data: response.result.value!)["products"].arrayValue
                    for product in productsResult
                    {
                        let fetchRequest = NSFetchRequest(entityName: "Product")
                        fetchRequest.predicate = NSPredicate(format: "name == %@", product["name"].stringValue)
                        var results = []
                        do
                        {
                            try results = self.context.executeFetchRequest(fetchRequest)
                        }
                        catch(_)
                        {
                        }
                        if results.count == 0
                        {
                            let productModel = ProductModel()
                            let productInsert = NSEntityDescription.insertNewObjectForEntityForName("Product", inManagedObjectContext: self.context) as! Product
                            productInsert.name = product["name"].stringValue
                            productModel.name = product["name"].stringValue
                            if product["manufacturer"] == nil
                            {
                                productInsert.brand = "Unknown"
                                productModel.brand = "Unknown"
                            }
                            else
                            {
                                productInsert.brand = product["manufacturer"].stringValue
                                productModel.brand = product["manufacturer"].stringValue
                            }
                            productInsert.price = product["salePrice"].floatValue
                            self.products.append(productInsert)
                            productModel.price = product["salePrice"].floatValue
                            productModel.imageUrl = product["image"].stringValue
                            productModel.largeImageUrl = product["largeImage"].stringValue
                            self.productsModel.append(productModel)
                            self.context.insertObject(productInsert)
                        }
                    }
                    self.productsCollectionView.reloadData()
                }
                else if response.result.error?.code == NSURLErrorNotConnectedToInternet
                {
                    let alertViewController = UIAlertController(title: "Atention", message: "Internet connection not available", preferredStyle: .Alert)
                    alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(alertViewController, animated: true, completion: nil)
                }
            }
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
        Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO)", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk"], encoding: .URL, headers: nil).responseData { (response) in
            self.refreshControlTop.endRefreshing()
            self.application.networkActivityIndicatorVisible = false
            if response.result.error == nil
            {
                //self.products = JSON(data: response.result.value!)["products"].arrayValue
                self.productsCollectionView.reloadData()
            }
            else if response.result.error == NSURLErrorNotConnectedToInternet
            {
                let alertViewController = UIAlertController(title: "Atention", message: "Internet connection not available", preferredStyle: .Alert)
                alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alertViewController, animated: true, completion: nil)
            }
        }
    }
    func refreshBottom()
    {
        application.networkActivityIndicatorVisible = true
        page++
        Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO)", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk", "page" : page], encoding: .URL, headers: nil).responseData { (response) in
            self.application.networkActivityIndicatorVisible = false
            self.refreshControlBottom.endRefreshing()
            if response.result.error == nil
            {
                let productsResult = JSON(data: response.result.value!)["products"].arrayValue
                var indexPaths: [NSIndexPath] = []
                var indice = self.productsModel.count
                for product in productsResult
                {
                    let fetchRequest = NSFetchRequest(entityName: "Product")
                    fetchRequest.predicate = NSPredicate(format: "name == %@", product["name"].stringValue)
                    var results = []
                    do
                    {
                        try results = self.context.executeFetchRequest(fetchRequest)
                    }
                    catch(_)
                    {
                    }
                    if results.count == 0
                    {
                        let productModel = ProductModel()
                        let productInsert = NSEntityDescription.insertNewObjectForEntityForName("Product", inManagedObjectContext: self.context) as! Product
                        productInsert.name = product["name"].stringValue
                        productModel.name = product["name"].stringValue
                        if product["manufacturer"] == nil
                        {
                            productInsert.brand = "Unknown"
                            productModel.brand = "Unknown"
                        }
                        else
                        {
                            productInsert.brand = product["manufacturer"].stringValue
                            productModel.brand = product["manufacturer"].stringValue
                        }
                        productInsert.price = product["salePrice"].floatValue
                        self.products.append(productInsert)
                        productModel.price = product["salePrice"].floatValue
                        productModel.imageUrl = product["image"].stringValue
                        productModel.largeImageUrl = product["largeImage"].stringValue
                        self.productsModel.append(productModel)
                        self.context.insertObject(productInsert)
                        indexPaths.append(NSIndexPath(forRow: indice, inSection: 0))
                        indice++
                    }
                }
                self.productsCollectionView.performBatchUpdates({ () -> Void in
                    self.productsCollectionView.insertItemsAtIndexPaths(indexPaths)
                    }, completion: { (_) -> Void in
                        self.refreshControlBottom.endRefreshing()
                })
            }
            else if response.result.error?.code == NSURLErrorNotConnectedToInternet
            {
                let alertViewController = UIAlertController(title: "Atention", message: "Internet connection not available", preferredStyle: .Alert)
                alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alertViewController, animated: true, completion: nil)
            }
        }
        Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO)", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk", "page" : page], encoding: .URL, headers: nil).responseData { (response) in
            self.refreshControlBottom.endRefreshing()
            self.application.networkActivityIndicatorVisible = false
            if response.result.error == nil
            {
                //self.products = JSON(data: response.result.value!)["products"].arrayValue
                self.productsCollectionView.reloadData()
            }
            else if response.result.error == NSURLErrorNotConnectedToInternet
            {
                let alertViewController = UIAlertController(title: "Atention", message: "Internet connection not available", preferredStyle: .Alert)
                alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alertViewController, animated: true, completion: nil)
            }
        }
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
            return productsModel.count;
        }
        else
        {
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
        if product.image == nil
        {
            cell.activityIndicatorView.startAnimating()
            let productInsert = products[indexPath.row]
            if product.largeImageUrl != nil && product.largeImageUrl != ""
            {
                Alamofire.request(.GET, product.largeImageUrl!).responseData { (response) in
                    product.image = UIImage(data: response.result.value!)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        cell.activityIndicatorView.stopAnimating()
                        let cell1 = collectionView.cellForItemAtIndexPath(indexPath) as? ProductCollectionViewCell
                        if cell1 != nil
                        {
                            cell1!.photo.image = product.image
                        }
                    })
                    productInsert.image = response.result.value!
                    do
                    {
                        try self.context.save()
                    }
                    catch(_)
                    {
                    }
                }
            }
            else if product.imageUrl != nil && product.imageUrl != ""
            {
                Alamofire.request(.GET, product.imageUrl!).responseData { (response) in
                    product.image = UIImage(data: response.result.value!)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        cell.activityIndicatorView.stopAnimating()
                        let cell1 = collectionView.cellForItemAtIndexPath(indexPath) as? ProductCollectionViewCell
                        if cell1 != nil
                        {
                            cell1!.photo.image = product.image
                        }
                    })
                    productInsert.image = response.result.value!
                    do
                    {
                        try self.context.save()
                    }
                    catch(_)
                    {
                    }
                }
            }
        }
        else
        {
            cell.photo.image = product.image
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
        }
        else
        {
            activityIndicatorView.stopAnimating()
        }
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        search = false
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
}