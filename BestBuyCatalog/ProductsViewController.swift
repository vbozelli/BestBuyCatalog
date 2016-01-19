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
    var searchProducts: [Product] = []
    var products: [Product] = []
    var search = false
    var request: Request?
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: imageView)
        refreshControlTop = UIRefreshControl()
        refreshControlTop.tintColor = UIColor.whiteColor()
        refreshControlTop.addTarget(self, action: Selector("refreshTop"), forControlEvents: .ValueChanged)
        productsCollectionView.addSubview(refreshControlTop)
        //infinite scroll collection view
        refreshControlBottom = UIRefreshControl()
        refreshControlBottom.tintColor = UIColor.whiteColor()
        refreshControlBottom.addTarget(self, action: Selector("refreshBottom"), forControlEvents: .ValueChanged)
        productsCollectionView.bottomRefreshControl = refreshControlBottom
        let searchField = searchBar.valueForKey("searchField") as! UITextField
        searchField.textColor = UIColor.whiteColor()
        let searchIcon = searchField.leftView as! UIImageView
        searchIcon.image = searchIcon.image?.imageWithRenderingMode(.AlwaysTemplate)
        searchIcon.tintColor = UIColor.whiteColor()
        //products from core data
        do
        {
            try products = self.context.executeFetchRequest(NSFetchRequest(entityName: "Product")) as! [Product]
        }
        catch(_)
        {
        }
        if products.count == 0
        {
            activityIndicatorView!.startAnimating()
            application.networkActivityIndicatorVisible = true
            //get products from BestBuy API and register on core data
            Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO)", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk"], encoding: .URL, headers: nil).responseJSON(completionHandler: { (response) -> Void in
                self.activityIndicatorView.stopAnimating()
                self.application.networkActivityIndicatorVisible = false
                if response.result.error == nil
                {
                    let productsResult: NSArray = response.result.value!["products"] as! NSArray
                    for product in productsResult
                    {
                        self.insertProduct(product as! NSDictionary)
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
        //current page
        if userDefaults.dictionaryRepresentation().keys.contains("page")
        {
            userDefaults.setInteger(page, forKey: "page")
        }
        else
        {
            page = userDefaults.integerForKey("page")
        }
    }
    //order by price
    func sort()
    {
        if ascending
        {
            UIView.animateWithDuration(0.5, animations: {
                self.navigationItem.rightBarButtonItem?.customView?.transform = CGAffineTransformIdentity
            })
            products.sortInPlace { (product1, product2) -> Bool in
                return product1.price > product2.price
            }
        }
        else
        {
            UIView.animateWithDuration(0.5, animations: {
                self.navigationItem.rightBarButtonItem?.customView?.transform = CGAffineTransformMakeRotation((180.0 * CGFloat(M_PI)) / 180.0)
            })
            products.sortInPlace { (productModel1, productModel2) -> Bool in
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
            self.application.networkActivityIndicatorVisible = false
            self.refreshControlTop.endRefreshing()
            if response.result.error == nil
            {
                let productsResult: NSArray = response.result.value!["products"] as! NSArray
                for product in productsResult
                {
                    let fetchRequest = NSFetchRequest(entityName: "Product")
                    fetchRequest.predicate = NSPredicate(format: "name == %@", argumentArray: [product["name"] as! String])
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
                        self.insertProduct(product as! NSDictionary)
                    }
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
    //infinite scroll loads products from BestBuy API
    func refreshBottom()
    {
        application.networkActivityIndicatorVisible = true
        Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO)", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "page" : page + 1, "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk"], encoding: .URL, headers: nil).responseJSON(completionHandler: { (response) -> Void in
            self.application.networkActivityIndicatorVisible = false
            if response.result.error == nil
            {
                let productsResult: NSArray = response.result.value!["products"] as! NSArray
                var indexPaths: [NSIndexPath] = []
                var indice = self.products.count - 1
                for product in productsResult
                {
                    self.insertProduct(product as! NSDictionary)
                    indice++
                    indexPaths.append(NSIndexPath(forItem: indice, inSection: 0))
                }
                self.productsCollectionView.performBatchUpdates({ () -> Void in
                    self.productsCollectionView.insertItemsAtIndexPaths(indexPaths)
                }, completion: { (_) -> Void in
                    self.refreshControlBottom.endRefreshing()
                })
                self.page++
                self.userDefaults.setInteger(self.page, forKey: "page")
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
            if products.count == 0
            {
                refreshControlTop.enabled = false
                refreshControlBottom.enabled = false
            }
            else
            {
                refreshControlTop.enabled = true
                refreshControlBottom.enabled = true
            }
            return products.count;
        }
        else
        {
            if searchProducts.count == 0
            {
                refreshControlTop.enabled = false
                refreshControlBottom.enabled = false
            }
            else
            {
                refreshControlTop.enabled = true
                refreshControlBottom.enabled = true
            }
            return searchProducts.count;
        }
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ProductCollectionViewCell
        cell.layer.cornerRadius = 10
        cell.brand.adjustsFontSizeToFitWidth = false
        var product: Product!
        if !search
        {
            product = products[indexPath.row]
        }
        else
        {
            product = searchProducts[indexPath.row]
        }
        cell.brand.text = "Brand: \(product.brand!)"
        cell.name.adjustsFontSizeToFitWidth = false
        cell.name.text = "Name: \(product.name!)"
        cell.price.text = "Price: U$ \(product.price)"
        cell.photo.image = nil
        if product.image != nil
        {
            cell.activityIndicatorView.startAnimating()
            //async image loading and image cache
            imageDownloader.downloadImage(URLRequest: NSURLRequest(URL: NSURL(string: product.image!)!, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60), filter: ScaledToSizeFilter(size: CGSize(width: cell.photo.frame.width, height: cell.photo.frame.height)), completion: { (response) -> Void in
                cell.activityIndicatorView.stopAnimating()
                let cell1 = collectionView.cellForItemAtIndexPath(indexPath) as? ProductCollectionViewCell
                if cell1 != nil
                {
                    cell1!.photo.image = response.result.value
                }
            })
        }
        return cell
    }
    func searchBarTextDidBeginEditing(searchBar: UISearchBar)
    {
        search = true
        productsCollectionView.reloadData()
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        if searchText != ""
        {
            searchProducts = products.filter({ (product) -> Bool in
                return product.name!.hasPrefix(searchText)
            })
            if searchProducts.count > 0
            {
                productsCollectionView.reloadData()
            }
            else
            {
                request?.cancel()
                productsCollectionView.reloadData()
                application.networkActivityIndicatorVisible = true
                activityIndicatorView.startAnimating()
                request = Alamofire.request(.GET, "http://api.bestbuy.com/v1/products(department=AUDIO&search=\(searchText))", parameters: ["show" : "name,salePrice,image,largeImage,manufacturer", "pageSize" : "100", "format" : "json", "apiKey" : "djshsuz99nvppzr6gqs8h2yk"], encoding: .URL, headers: nil).responseJSON(completionHandler: { (response) -> Void in
                    self.activityIndicatorView.stopAnimating()
                    self.application.networkActivityIndicatorVisible = false
                    if response.result.error == nil
                    {
                        let productsResult: NSArray = response.result.value!["products"] as! NSArray
                        for product in productsResult
                        {
                            self.insertProduct(product as! NSDictionary)
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
        }
        else
        {
            searchProducts = products
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
        productsCollectionView.reloadData()
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "productDetail"
        {
            let productDetailViewController = segue.destinationViewController as! ProductDetailViewController
            if search
            {
                productDetailViewController.product = searchProducts[productsCollectionView.indexPathsForSelectedItems()![0].row]
            }
            else
            {
                productDetailViewController.product = products[productsCollectionView.indexPathsForSelectedItems()![0].row]
            }
        }
    }
    func insertProduct(product: NSDictionary)
    {
        let productInsert = NSEntityDescription.insertNewObjectForEntityForName("Product", inManagedObjectContext: self.context) as! Product
        let keys: [String] = product.allKeys as! [String]
        if keys.contains("name")
        {
            if !(product["name"] is NSNull)
            {
                let name = product["name"] as! String
                productInsert.name = name
            }
            else
            {
                productInsert.name = "Unknown"
            }
        }
        else
        {
            productInsert.name = "Unknown"
        }
        if keys.contains("manufacturer")
        {
            if !(product["manufacturer"] is NSNull)
            {
                let brand = product["manufacturer"] as! String
                productInsert.brand = brand
            }
            else
            {
                productInsert.brand = "Unknown"
            }
        }
        else
        {
            productInsert.brand = "Unknown"
        }
        if keys.contains("salePrice")
        {
            if !(product["salePrice"] is NSNull)
            {
                let price = product["salePrice"] as! Float
                productInsert.price = price
            }
            else
            {
                productInsert.price = 0
            }
        }
        else
        {
            productInsert.price = 0
        }
        if keys.contains("largeImage")
        {
            if !(product["largeImage"] is NSNull)
            {
                productInsert.image = product["largeImage"] as? String
            }
            else
            {
                if keys.contains("image")
                {
                    if !(product["image"] is NSNull)
                    {
                        productInsert.image = product["image"] as? String
                    }
                    else
                    {
                        productInsert.image = nil
                    }
                }
                else
                {
                    productInsert.image = nil
                }
            }
        }
        else
        {
            productInsert.image = nil
        }
        self.products.append(productInsert)
        self.context.insertObject(productInsert)
    }
}