//
//  AppInitilizer.swift
//  Potatso
//
//  Created by LEI on 12/27/15.
//  Copyright © 2015 TouchingApp. All rights reserved.
//

import Foundation
import ICSMainFramework
import Appirater
import Fabric
import LogglyLogger_CocoaLumberjack

import LeanCloud

let appID = "1070901416"

class AppInitializer: NSObject, AppLifeCycleProtocol {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        LeanCloud.initialize(applicationID: "EDi3uUcJhRLi3hjOY96bYG8K-gzGzoHsz", applicationKey: "Q5WNLGA7HNev3dC1CcrRmLUo")
        
//        let query = LCQuery(className: "Subscribe")
//        query.whereKey("address", .matchedSubstring("WePNdffr"))
//
//        query.find { result in
//            switch result {
//            case .success(let objects):
//
//                if objects.count == 0 {
//                    let post = LCObject(className: "Subscribe")
//                    post.set("address", value: "WePNbbb")
//                    post.save{ result in
//                        switch result {
//                        case .success:
//
//                            break
//                        case .failure(let error):
//                            print(error)
//                            break
//                        }
//                    }
//                }
//                break // 查询成功
//
//            case .failure(let error):
//                print(error)
//                break // 查询失败
//            }
//        }
        
        
        _  = UIViewController.shared
        configLogging()
        configAppirater()
        #if !DEBUG
            Fabric.with([Answers.self, Crashlytics.self])
        #endif
        configHelpShift()
        return true
    }

    func configAppirater() {
        Appirater.setAppId(appID)
    }

    func configLogging() {
        let fileLogger = DDFileLogger() // File Logger
        fileLogger?.rollingFrequency = TimeInterval(60*60*24*3)  // 24 hours
        fileLogger?.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger!)

        let logglyLogger = LogglyLogger() // Loggy Logger
        logglyLogger.logglyKey = InfoInternal.shared.getLogglyAPIKey()
        let fields = LogglyFields()
        fields.userid = User.currentUser.id
        fields.appversion = AppEnv.fullVersion
        let formatter = LogglyFormatter(logglyFieldsDelegate: fields)
        formatter?.alwaysIncludeRawMessage = false
        logglyLogger.logFormatter = formatter
        DDLog.add(logglyLogger)

        #if DEBUG
            DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
            DDLog.add(DDASLLogger.sharedInstance) // ASL = Apple System Logs
            DDLog.setLevel(DDLogLevel.all, for: DDTTYLogger.self)
            DDLog.setLevel(DDLogLevel.all, for: DDASLLogger.self)
        #else

        #endif
    }

    func configHelpShift() {
        HelpshiftCore.initialize(with: HelpshiftAll.sharedInstance())
        HelpshiftCore.install(forApiKey: HELPSHIFT_KEY, domainName: HELPSHIFT_DOMAIN, appID: HELPSHIFT_ID)
    }
    
}
