//
//  ViewController.swift
//  OLXChallenge
//
//  Created by Ana Neto on 27/09/16.
//  Copyright © 2016 Ana Neto. All rights reserved.
//

import UIKit
import RealmSwift
import SDWebImage

class AdTableViewController: UIViewController {
    
    //MARK: Variables
    private var olxManager:OLXManager = OLXManager.sharedInstance
    private var isLoadingTableView = true
    private var page:Int = 0
    private var data:List<Ad>?
    private var nextPageURL:String?
    private var selectedId:Int?
    
    //MARK: IBOutlets
    @IBOutlet var loadingCircle: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    //MARK: lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.estimatedRowHeight = 44.0 ;
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.registerNib(UINib(nibName: "MainTableViewCell", bundle:nil), forCellReuseIdentifier: "MainTableViewCell")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        runScreenConfigurations()
        apiCall()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: auxiliar methods
    
    private func runScreenConfigurations(){
        
        self.title = NSLocalizedString("ADS_LIST_TITLE", comment: "")
        self.olxManager.delegate = self
        self.tableView.alpha = 0
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.loadingCircle.startAnimating()
    }
    
    private func apiCall(){
        self.olxManager.getData(nextPageURL, page:self.page)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SegueFromTableToPager" {
            let vc:PagerViewController = segue.destinationViewController as! PagerViewController
            vc.currentIndex = self.selectedId
            vc.comebackDelegate = self
            vc.ads = self.data
            vc.nextPageURL = self.nextPageURL
            vc.page = page
        }
    }
}

//MARK: OLXManagerProtocol methods

extension AdTableViewController:OLXManagerProtocol {
    
    func returnResponse(response: Response) {
        
        if self.data == nil {
            self.data = List<Ad>()
        }
        self.data!.appendContentsOf(response.ads)
        self.page = response.page
        self.nextPageURL = response.nextPageURL
        
        self.loadingCircle.stopAnimating()
        self.tableView.reloadData()
        UIView.animateWithDuration(0.3, animations: {
            self.tableView.alpha = 1
        })
    }
    
    func returnError() {
        let myAlert = UIAlertView()
        myAlert.title = NSLocalizedString("ERROR_TITLE", comment: "")
        myAlert.message = NSLocalizedString("ERROR_MSG", comment: "")
        myAlert.addButtonWithTitle("OK")
        myAlert.delegate = self
        myAlert.show()
    }
}

//MARK: PagerViewControllerProtocol methods

extension AdTableViewController:PagerViewControllerProtocol {
    func continueWithCurrentData(data: List<Ad>, page: Int, nextURL: String) {
        self.data = data
        self.page = page
        self.nextPageURL = nextURL
    }
}

//MARK: UITableViewDelegate methods

extension AdTableViewController:UITableViewDelegate {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:MainTableViewCell = tableView.dequeueReusableCellWithIdentifier("MainTableViewCell", forIndexPath: indexPath) as! MainTableViewCell
        let ad = data![indexPath.row]
        
        if let imgURL = ad.getImageURL(0) {
            cell.adImageView.sd_setImageWithURL(NSURL(string: imgURL), placeholderImage: UIImage(named: "imagePlaceholder"))
        }
        else {
            cell.adImageView.image = UIImage(named: "imagePlaceholder")
        }
        
        cell.delegate = self
        cell.adId = ad.adId
        cell.priceLabel.text = ad.price
        cell.adLocationLabel.text = ad.locationText
        cell.adTitleLabel.text = ad.title
        cell.creationLabel.text = ad.creationDate
        
        cell.contentView.layoutIfNeeded()
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.selectedId = indexPath.row
        self.performSegueWithIdentifier("SegueFromTableToPager", sender: self)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row+1 == data?.count {
            apiCall()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

//MARK: UITableViewDataSource methods

extension AdTableViewController:UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data != nil ? data!.count : 0
    }
}

//MARK: MainTableViewCellProtocol methods

extension AdTableViewController:MainTableViewCellProtocol {
    
    func shareButtonPressed(id: String?) {
        if let str = id {
            let result  = try! Realm().objects(Ad.self).filter("adId = '\(str)'")
            
            //single result
            if result.count == 1 {
                
                let textToShare = result.first!.title
                if let url = result.first!.url {
                    if let adURL = NSURL(string: url) {
                        let objectsToShare = [textToShare!,adURL]
                        
                        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                        
                        // exclude some activity types from the list (optional)
                        activityViewController.excludedActivityTypes = [ UIActivityTypeAirDrop, UIActivityTypePostToFacebook ]
                        
                        // present the view controller
                        self.presentViewController(activityViewController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
