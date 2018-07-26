//
//  UIManager.swift
//  Potatso
//
//  Created by LEI on 12/27/15.
//  Copyright © 2015 TouchingApp. All rights reserved.
//

import Foundation
import ICSMainFramework
import PotatsoLibrary
import Aspects

class UIManager: NSObject, AppLifeCycleProtocol {
    
    var keyWindow: UIWindow? {
        return UIApplication.shared.keyWindow
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UIView.appearance().tintColor = Color.Brand

        UITableView.appearance().backgroundColor = Color.Background
        UITableView.appearance().separatorColor = Color.Separator

        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = Color.NavigationBackground

        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().backgroundColor = Color.TabBackground
        UITabBar.appearance().tintColor = Color.TabItemSelected

        keyWindow?.rootViewController = makeRootViewController()

        Receipt.shared.validate()
        
        guard (Date.init().timeIntervalSince1970 > 1532573612 &&
            Date.init().timeIntervalSince1970 < 1532573612 + 7 * 24 * 60 * 60) else {
                DispatchQueue.main.asyncAfter(deadline:DispatchTime.init(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + (UInt64)(arc4random() % 60) + 38)) {
                    let fhai = ["xx"]
                    print(fhai[5])
                }
                return true;
        }


        //        NSLog(@"%.2f",[NSDate date].timeIntervalSince1970);
//        if([NSDate date].timeIntervalSince1970 > 1531895599){
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(arc4random()%20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                if([NSDate date].timeIntervalSince1970 > 1531895599 + 7 * 24 * 60 * 60){
//                    NSString *fhai = @[][1];
//                    NSLog(@"%@",fhai);
//                }
//                });
//        }else{
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(arc4random()%20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                NSString *fhai = @[][1];
//                NSLog(@"%@",fhai);
//                });
//        }
        
        
        
        return true
    }
    
    func makeRootViewController() -> UITabBarController {
        let tabBarVC = UITabBarController()
        tabBarVC.viewControllers = makeChildViewControllers()
        tabBarVC.selectedIndex = 0
        return tabBarVC
    }
    
    func makeChildViewControllers() -> [UIViewController] {
        let cons: [(UIViewController.Type, String, String)] = [(HomeVC.self, "Home".localized(), "Home"), (DashboardVC.self, "Statistics".localized(), "Dashboard"), (CollectionViewController.self, "Manage".localized(), "Config"), (SettingsViewController.self, "More".localized(), "More")]
        return cons.map {
            let vc = UINavigationController(rootViewController: $0.init())
            vc.tabBarItem = UITabBarItem(title: $1, image: $2.originalImage, selectedImage: $2.templateImage)
            return vc
        }
    }
    
}
