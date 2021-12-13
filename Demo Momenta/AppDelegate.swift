//
//  AppDelegate.swift
//  Demo Momenta
//
//  Created by JonF on 9/22/21.
//

import UIKit
import Firebase
import GoogleSignIn
import OneSignal
import Mixpanel
import Segment
import Amplitude




@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Cloud.sharedInstance.initFirebase()
        //MARK: Mixpanel Setup
        Mixpanel.initialize(token: "d810d40cdbc7dead2ff901838c696ccb")
        //MARK: Amplitude Setup
        Amplitude.instance().trackingSessionEvents = true
        // Initialize Amplitude SDK
        Amplitude.instance().initializeApiKey("b39d29f0706cc572d5ee81d35824c312")
        //Segment.com Setup
//        let segmentConfig = Configuration(writeKey: "3pmjiIQ5DAHCTx0uXRBT8YllGRy6Kp1v")
//            // Automatically track Lifecycle events
//            .trackApplicationLifecycleEvents(true)
//            .flushAt(3)
//            .flushInterval(10)
//        let segmentAnalytics = Analytics(configuration: segmentConfig)
//        let timeInterval = Int(NSDate().timeIntervalSince1970)
//        segmentAnalytics.track(name: "iOS App Last Opened", properties: ["last opened": timeInterval])
        
        //OneSignal Init
        // Remove this method to stop OneSignal Debugging
        OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)

        // OneSignal initialization
        OneSignal.initWithLaunchOptions(launchOptions)
        OneSignal.setAppId("5e605fcd-de88-4b0a-a5eb-5c18b84d52f3")

        // promptForPushNotifications will show the native iOS notification permission prompt.
        // We recommend removing the following code and instead using an In-App Message to prompt for notification permission (See step 8)
//        OneSignal.promptForPushNotifications(userResponse: { accepted in
//            print("User accepted notifications: \(accepted)")
//        })
        
        let notificationWillShowInForegroundBlock: OSNotificationWillShowInForegroundBlock = { notification, completion in
            print("Received Notification: ", notification.description)
            print("Collapse_id: ", notification.rawPayload)
          print("launchURL: ", notification.launchURL ?? "no launch url")
          print("content_available = \(notification.contentAvailable)")

          if notification.notificationId == "example_silent_notif" {
            // Complete with null means don't show a notification
            completion(nil)
          } else {
            // Complete with a notification means it will show
            completion(notification)
          }
        }
        OneSignal.setNotificationWillShowInForegroundHandler(notificationWillShowInForegroundBlock)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
      var handled: Bool

      handled = GIDSignIn.sharedInstance.handle(url)
      if handled {
        return true
      }
      // Handle other custom URL types.
      // If not handled by this app, return false.
      return false
    }

}

