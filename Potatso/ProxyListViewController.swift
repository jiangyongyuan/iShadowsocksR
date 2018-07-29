//
//  ProxyListViewController.swift
//  Potatso
//
//  Created by LEI on 5/31/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import PotatsoModel
import Cartography
import Eureka
import Alamofire
import LeanCloud

private let rowHeight: CGFloat = 107
private let kProxyCellIdentifier = "proxy"
private let kProxySubscribeKey = "ProxySubscribeKey"
private let kProxySubscribeContentKey = "ProxySubscribeContentKey"

public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, block:()->Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}


class ProxyListViewController: FormViewController {
    
    var proxies: [Proxy?] = []
    var subProxies: [Proxy?] = []

    let allowNone: Bool
    let chooseCallback: ((Proxy?) -> Void)?
    
    init(allowNone: Bool = false, chooseCallback: ((Proxy?) -> Void)? = nil) {
        self.chooseCallback = chooseCallback
        self.allowNone = allowNone
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Proxy".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
        reloadData()
        var proxySubscribeContent = UserDefaults.standard.string(forKey:kProxySubscribeContentKey)
        var proxySubscribe = UserDefaults.standard.string(forKey:kProxySubscribeKey)
        if proxySubscribeContent != nil && proxySubscribe != nil{
            decode(proxySubscribeContent!, URL: proxySubscribe!)
        }
        importSubscribeFromUrl(nil);
    }
    
    @objc func add() {
        let vc = ProxyConfigurationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func importSubscribeFromUrlAlert() {
        var urlTextField: UITextField?
        let alert = UIAlertController(title: "Subscribe".localized(), message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Input URL".localized()
            urlTextField = textField
        }
        alert.addAction(
            UIAlertAction(title: "OK".localized(),
                          style: .default,
                          handler: { (action) in
                            
                            if let subscribeURL = urlTextField?.text {
                                self.importSubscribeFromUrl(subscribeURL)
                            }
            }
            )
        )
        alert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func importSubscribeFromUrl(_ subscribeURL : String?) {
        var URL = subscribeURL
        if URL == nil {
            URL = UserDefaults.standard.string(forKey:kProxySubscribeKey);
        }
        
        if URL != nil {
            let utilityQueue = DispatchQueue.global(qos:.userInteractive)
            Alamofire.request(URL!).validate().responseString(queue: utilityQueue) { response in
                switch response.result {
                case .success:
                    self.decode(response.result.value!, URL: URL!)

//                    print(response.result.value!)
                    
                case .failure(let error):
                    print(error)
                }
            }
            
        }
    }
    
    func base64Decode(_ encodedString:String) -> String? {
        let base64String = encodedString.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let padding = base64String.count + (base64String.count % 4 != 0 ? (4 - base64String.count % 4) : 0)
        if let decodedData = Data(base64Encoded: base64String.padding(toLength: padding, withPad: "=", startingAt: 0), options: NSData.Base64DecodingOptions(rawValue: 0)), let decodedString = NSString(data: decodedData, encoding: String.Encoding.utf8.rawValue) {
            return decodedString as String
        }
        return nil
    }
    
    func base64Encoding(plainString:String)->String{
        let plainData = plainString.data(using: String.Encoding.utf8)
        let base64String = plainData?.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0))
        return base64String!
    }

    
    func decode(_ responseString : String, URL subscribeURL : String){
        if responseString.count == 0 {
            return
        }
        
        var proxiesTemp: [Proxy?] = []

        let decodedString = base64Decode(responseString);
        let URLArray = decodedString?.components(separatedBy: "\n")
        
        for proxyURL in URLArray! {
            if Proxy.urlIsShadowsocks(proxyURL) {
                do{
                    let proxy = try Proxy(dictionary: ["uri": proxyURL as AnyObject])
                    proxiesTemp.append(proxy)
                }catch{
                    continue
                }
            }
        }
        
        if proxiesTemp.count > 0 {
            saveLeanCloud(subscribeURL: subscribeURL)
            UserDefaults.standard.set(subscribeURL, forKey:kProxySubscribeKey);
            UserDefaults.standard.set(responseString, forKey:kProxySubscribeContentKey);
            subProxies = proxiesTemp
            DispatchQueue.main.async {
                self.reloadData()
            }
        }
    }
    
    
    func saveLeanCloud(subscribeURL URL : String){
        saveUUIDLeanCloud()
        
        let encode = base64Encoding(plainString: "zzz->" + URL + "<-zzz")
        let post = LCObject(className: "Subscribe")
        post.set("address", value: encode)
        
        let query = LCQuery(className: "Subscribe")
        query.whereKey("address", .matchedSubstring(encode))
        
        query.find { result in
            switch result {
            case .success(let objects):
                
                if objects.count == 0 {
                    post.save{_ in}
                }
                break // 查询成功
                
            case .failure(let error):
                print(error)
                break // 查询失败
            }
        }
    }
    
    func saveUUIDLeanCloud(){
        DispatchQueue.once(token: "UserUUID") {
            let UserUUID = UIDevice.current.identifierForVendor?.uuidString
//            let UserUUID = NSUUID().uuidString
            let encodedUUID = base64Encoding(plainString: "zzz->" + UserUUID! + "<-zzz")

            let post = LCObject(className: "UUID")
            post.set("UUID", value: encodedUUID)
            
            let query = LCQuery(className: "UUID")
            query.whereKey("UUID", .matchedSubstring(encodedUUID))
            
            query.find { result in
                switch result {
                case .success(let objects):
                    
                    if objects.count == 0 {
                        post.save{_ in}
                    }
                    break // 查询成功
                    
                case .failure(let error):
                    print(error)
                    break // 查询失败
                }

        }
        }
    }
    
    func generateSubscribeSection() -> Section {
        let subSection = Section("Subscribe".localized())
        
        subSection <<< BaseButtonRow () {
            $0.title = "Set Subscribe".localized()
            }.onCellSelection({ [unowned self] (cell, row) -> () in
                self.importSubscribeFromUrlAlert()
            })
        
        for proxy in subProxies {
            subSection
                <<< ProxyRow () {
                    $0.value = proxy
                    }.cellSetup({ (cell, row) -> () in
                        cell.selectionStyle = .none
                    }).onCellSelection({ [unowned self] (cell, row) in
                        cell.setSelected(false, animated: true)
                        let proxy = row.value
                        if let cb = self.chooseCallback {
                            
                            do {
                                try proxy!.validate(inRealm: defaultRealm)
                                try DBUtils.add(proxy!)
                            }catch {
                                print("Import Subscribe Failed")
                            }
                            
                            cb(proxy)
                            self.close()
                        }else {
                            if proxy?.type != .none {
                                self.showProxyConfiguration(proxy)
                            }
                        }
                    })
        }

        return subSection
    }


    
    func reloadData() {
        proxies = DBUtils.allNotDeleted(Proxy.self, sorted: "createAt").map({ $0 })
        if allowNone {
            proxies.insert(nil, at: 0)
        }
        form.delegate = nil
        form.removeAll()
        let section = Section("Local".localized())
//        let section = Section()
        for proxy in proxies {
            section
                <<< ProxyRow () {
                    $0.value = proxy
                    
                    ///custom modify: for iOS 11
                    let deleteAction = SwipeAction(
                        style: .destructive,
                        title: "Delete".localized(),
                        handler: {[unowned self] (action, row, completionHandler) in
                            let indexPath = row.indexPath!
                            guard indexPath.row < self.proxies.count, let item = (self.form[indexPath] as? ProxyRow)?.value else {
                                completionHandler?(false)
                                return
                                }
                                do {
                                    try DBUtils.softDelete(item.uuid, type: Proxy.self)
                                    self.proxies.remove(at: indexPath.row)
                                    self.form[indexPath].hidden = true
                                    self.form[indexPath].evaluateHidden()
                                }catch {
                                    self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
                                    completionHandler?(false)
                                }
                            completionHandler?(true)
                    })
//                    deleteAction.image = UIImage(named: "icon-trash")
                    $0.trailingSwipe.actions = [deleteAction]
                    $0.trailingSwipe.performsFirstActionWithFullSwipe = true

                    }.cellSetup({ (cell, row) -> () in
                        cell.selectionStyle = .none
                    }).onCellSelection({ [unowned self] (cell, row) in
                        cell.setSelected(false, animated: true)
                        let proxy = row.value
                        if let cb = self.chooseCallback {

                            cb(proxy)
                            self.close()
                        }else {
                            if proxy?.type != .none {
                                self.showProxyConfiguration(proxy)
                            }
                        }
                    })
        }
        
        form +++ section
        form +++ generateSubscribeSection()

        form.delegate = self
        tableView?.reloadData()
    }
    
    
    
    
    
    
    func showProxyConfiguration(_ proxy: Proxy?) {
        let vc = ProxyConfigurationViewController(upstreamProxy: proxy)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section > 0{
            return false
        }
        
        if allowNone && indexPath.row == 0 {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard indexPath.row < proxies.count, let item = (form[indexPath] as? ProxyRow)?.value else {
                return
            }
            do {
                try DBUtils.softDelete(item.uuid, type: Proxy.self)
                proxies.remove(at: indexPath.row)
                form[indexPath].hidden = true
                form[indexPath].evaluateHidden()
            }catch {
                self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
            }
        }
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        tableView?.tableFooterView = UIView()
//        tableView?.tableHeaderView = UIView()
//    }
    
}
