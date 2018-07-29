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

private let rowHeight: CGFloat = 107
private let kProxyCellIdentifier = "proxy"

class ProxyListViewController: FormViewController {
    
    var proxies: [Proxy?] = []
    let allowNone: Bool
    let chooseCallback: ((Proxy?) -> Void)?
    
    init(allowNone: Bool = false, chooseCallback: ((Proxy?) -> Void)? = nil) {
        self.chooseCallback = chooseCallback
        self.allowNone = allowNone
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Proxy".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
        reloadData()
    }
    
    @objc func add() {
        let vc = ProxyConfigurationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func reloadData() {
        proxies = DBUtils.allNotDeleted(Proxy.self, sorted: "createAt").map({ $0 })
        if allowNone {
            proxies.insert(nil, at: 0)
        }
        form.delegate = nil
        form.removeAll()
        let section = Section()
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
        form.delegate = self
        tableView?.reloadData()
    }
    
    func showProxyConfiguration(_ proxy: Proxy?) {
        let vc = ProxyConfigurationViewController(upstreamProxy: proxy)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView?.tableFooterView = UIView()
        tableView?.tableHeaderView = UIView()
    }
    
}



////
////  ProxyListViewController.swift
////  Potatso
////
////  Created by LEI on 5/31/16.
////  Copyright © 2016 TouchingApp. All rights reserved.
////
//
//import Foundation
//import PotatsoModel
//import Cartography
//
//
//
//private let rowHeight: CGFloat = 54
//private let kProxyCellIdentifier = "proxy"
//
//
//class ProxyListViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
//
//    var proxies: [Proxy?] = []
//    let allowNone: Bool
//    let chooseCallback: ((Proxy?) -> Void)?
//
//    var heightAtIndex: [Int: CGFloat] = [:]
//
//    init(allowNone: Bool = false, chooseCallback: ((Proxy?) -> Void)? = nil) {
//        self.chooseCallback = chooseCallback
//        self.allowNone = allowNone
//        super.init(nibName:nil, bundle:nil)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationItem.title = "Proxy".localized()
//        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
//        reloadData()
//    }
//
//    @objc func add() {
//        let vc = ProxyConfigurationViewController()
//        navigationController?.pushViewController(vc, animated: true)
//    }
//
//    func reloadData() {
//        proxies = DBUtils.allNotDeleted(Proxy.self, sorted: "createAt").map({ $0 })
//        if allowNone {
//            proxies.insert(nil, at: 0)
//        }
//        tableView.reloadData();
//    }
//
//    func showProxyConfiguration(_ proxy: Proxy?) {
//        let vc = ProxyConfigurationViewController(upstreamProxy: proxy)
//        navigationController?.pushViewController(vc, animated: true)
//    }
//
//
//
////    form.delegate = nil
////    form.removeAll()
////    let section = MultivaluedSection(multivaluedOptions: [.Delete],
////                                     header: "",
////                                     footer: "") {_ in }
////
////    for proxy in proxies {
////    section
////    <<< ProxyRow () {
////    $0.value = proxy
////    }.cellSetup({ (cell, row) -> () in
////    cell.selectionStyle = .none
////    }).onCellSelection()
////    }
////    form +++ section
////    form.delegate = self
////    tableView?.reloadData()
//
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return proxies.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: kProxyCellIdentifier, for: indexPath) as! ProxyRowCell
//        cell.proxyModel = proxies[indexPath.row]
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        heightAtIndex[indexPath.row] = cell.frame.size.height
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        let cell : ProxyRowCell = self.tableView(tableView, cellForRowAt: indexPath) as! ProxyRowCell
//        let proxy = cell.proxyModel;
//        if let cb = self.chooseCallback {
//            cb(proxy)
//            self.close()
//        }else {
//            if proxy?.type != .none {
//                self.showProxyConfiguration(proxy)
//            }
//        }
//    }
//
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        if let height = heightAtIndex[indexPath.row] {
//            return height
//        } else {
//            return UITableViewAutomaticDimension
//        }
//    }
//
//
//    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        if allowNone && indexPath.row == 0 {
//            return false
//        }
//        return true
//    }
//
//    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
//        return .delete
//    }
//
//
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            guard indexPath.row < proxies.count, let item = (form[indexPath] as? ProxyRow)?.value else {
//                return
//            }
//            do {
//                try DBUtils.softDelete(item.uuid, type: Proxy.self)
//                proxies.remove(at: indexPath.row)
//                form[indexPath].hidden = true
//                form[indexPath].evaluateHidden()
//            }catch {
//                self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
//            }
//        }
//    }
//
//
//
////    override func viewDidLayoutSubviews() {
////        super.viewDidLayoutSubviews()
////        tableView?.tableFooterView = UIView()
////        tableView?.tableHeaderView = UIView()
////    }
////
//
//    override func loadView() {
//        super.loadView()
//        view.backgroundColor = UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
//        view.addSubview(tableView)
//        tableView.register(ProxyRowCell.self, forCellReuseIdentifier: kProxyCellIdentifier)
//
//        constrain(tableView, view) { tableView, view in
//            tableView.edges == view.edges
//        }
//    }
//
//    lazy var tableView: UITableView = {
//        let v = UITableView(frame: CGRect.zero, style: .plain)
//        v.dataSource = self
//        v.delegate = self
//        v.tableFooterView = UIView()
//        v.tableHeaderView = UIView()
//        v.separatorStyle = .singleLine
//        v.rowHeight = UITableViewAutomaticDimension
//        return v
//    }()
//
//}
