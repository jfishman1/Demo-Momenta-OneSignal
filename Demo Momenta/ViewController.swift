//
//  ViewController.swift
//  Demo Momenta
//
//  Created by JonF on 9/22/21.
//

import UIKit
import GoogleSignIn
import OneSignal
import Firebase
import Mixpanel
import Segment
import Amplitude


class ViewController: UIViewController {
        
    @IBOutlet var textView: UITextView!
    
    var osPlayerId = ""
    var externalUserId = ""
    var externalUserIdResultsPush = ""
    var externalUserIdResultsEmail = ""
    var externalUserIdResultsSMS = ""
    var email = ""
    var first_name = ""
    var last_name = ""
    var name = ""
    var googleUserId = ""
    var firebaseUserId = ""
    var mixpanelDistinctId = ""
    var osTags = ""
    
    let mixpanel = Mixpanel.mainInstance()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        OneSignal.disablePush(false)
        self.osPlayerId = OneSignal.getDeviceState().userId ?? "playerId not available yet"
        self.email = OneSignal.getDeviceState().emailAddress ?? "email not set"
        Cloud.sharedInstance.googleRestorePreviousSignIn(completion: {email, first_name, last_name, googleUserId in
            self.email = email
            self.first_name = first_name
            self.last_name = last_name
            self.googleUserId = googleUserId
            self.updateTextView()
        }, err: { error in
            if error.localizedDescription.contains("-4"){
                self.textView.text = "Please make sure you have a network connection."
            }
        })
    }
    
    func updateTextView(){
        let textViewText = "osPlayerId: \(self.osPlayerId)\nexternalUserId: \(self.externalUserId) push: \(self.externalUserIdResultsPush), email: \(self.externalUserIdResultsEmail), sms:\(self.externalUserIdResultsSMS)\nemailAddress: \(self.email)\nname: \(self.name)\ngoogleUserId: \(self.googleUserId)\nfirebaseUserId: \(self.firebaseUserId)\nmixpanelDistinctId: \(self.mixpanelDistinctId)\nosTags: \(self.osTags)"
        self.textView.text = textViewText
        print(textViewText)
    }
    
    func osSetExternalUserId(userId: String) {
        self.externalUserId = ""
        self.externalUserIdResultsPush = ""
        self.externalUserIdResultsEmail = ""
        self.externalUserIdResultsSMS = ""
        
        OneSignal.setExternalUserId(userId, withSuccess: { results in
            print("External user id update complete with results: ", results!.description)
            if let pushResults = results!["push"] {
                print("Set external user id push status: ", pushResults)
                self.externalUserIdResultsPush = "t"
                self.externalUserId = userId
            } else {
                print("NO PUSH RESULTS, TRY AGAIN")
                // push id not set, try again after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    OneSignal.setExternalUserId(userId)
                }
            }
            if let emailResults = results!["email"] {
                print("Set external user id email status: ", emailResults)
                self.externalUserIdResultsEmail = "t"
            } else {
                // email id not set, try again after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    OneSignal.setExternalUserId(userId)
                }
            }
            if let smsResults = results!["sms"] {
                print("Set external user id sms status: ", smsResults)
                self.externalUserIdResultsSMS = "t"
            } else {
                // email id not set, try again after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    OneSignal.setExternalUserId(userId)
                }
            }
           
        }, withFailure: { error in
            print("Set external user id done with error: " + error.debugDescription)
            self.textView.text = "osSetExternalUserId error: \(error.debugDescription)"
            // no euid set, try again after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                OneSignal.setExternalUserId(userId)
            }
        })
    }
    
    
    @IBAction func signIn(sender: Any) {
                
        Cloud.sharedInstance.googleSignIn(presentingViewController: self, completion: { values in
            let credential = values["credential"] as! AuthCredential
            if let email = values["email"] as? String {
                OneSignal.setEmail(email, withSuccess: {
                    self.email = email
                }, withFailure: {error in
                    self.textView.text = "os setEmail error: \(error!.localizedDescription)"
                })
            }
            if let googleUserId = values["googleUserId"] as? String {
                self.googleUserId = googleUserId
                self.osSetExternalUserId(userId: googleUserId)
            }
            
            let firstName = values["firstName"] as? String ?? ""
            self.first_name = firstName
            let lastName = values["lastName"] as? String ?? ""
            self.last_name = lastName
            self.name = firstName + " " + lastName
            
            //MARK: Mixpanel
            //self.updateMixpanelUserData(userId: self.googleUserId, email: self.email, firstName: firstName, lastName: lastName)
//            //MARK: Segment.com
//            let segmentConfig = Configuration(writeKey: "3pmjiIQ5DAHCTx0uXRBT8YllGRy6Kp1v")
//                // Automatically track Lifecycle events
//                .trackApplicationLifecycleEvents(true)
//                .flushAt(3)
//                .flushInterval(10)
//            //MARK: Segment.com
//            let segmentAnalytics = Analytics(configuration: segmentConfig)
//            segmentAnalytics.identify(userId: self.googleUserId, traits: ["first_name": firstName, "last_name": lastName])
//            let timestamp = Int(NSDate().timeIntervalSince1970).toString()
//            segmentAnalytics.track(name: "iOS App Last Opened", properties: ["last opened": timestamp])
//            //MARK: HubSpot Networking
//            Cloud.sharedInstance.createOrUpdateHubSpotUser(email: self.email, external_user_id: self.googleUserId, firstName: firstName, lastName: lastName)
//            //MARK: Firebase
//            Cloud.sharedInstance.firebaseSignIn(credential: credential, completion: {uid in
//                self.firebaseUserId = uid
//
//            }, err: {error in
//                self.textView.text = "firebaseSignIn error: \(error.localizedDescription)"
//            })
//            //MARK: Amplitude
            Amplitude.instance().setUserId(self.googleUserId)

            
            self.updateTextView()
            
        }, err: {error in
            self.textView.text = "googleSignIn error: \(error.localizedDescription)"
        })
    }
    
    func updateMixpanelUserData(userId: String, email: String, firstName: String, lastName: String){
        //Use Mixpanel Distinct ID if no other External User Id available
        mixpanel.identify(distinctId: userId, usePeople: true, completion: {
            let distinctId = self.mixpanel.distinctId
            self.mixpanelDistinctId = distinctId
        })
        
        mixpanel.people.set(properties: ["$onesignal_user_id":userId, "$email":email, "$first_name": firstName, "$last_name": lastName])
                
        mixpanel.track(event: "SignIn", properties: [
            "source": "Demo Momenta App",
            "Subscribed to Push": OneSignal.getDeviceState().isSubscribed,
            "Subscribed to Email": OneSignal.getDeviceState().isEmailSubscribed
        ])
    }
    
    @IBAction func signOut(sender: Any) {
        self.textView.text = "Signed Out of all platforms and removed External User Id"
        Cloud.sharedInstance.googleSignOut()
        Cloud.sharedInstance.firebaseSignOut()
        OneSignal.removeExternalUserId()
        OneSignal.logoutEmail()
        OneSignal.logoutSMSNumber()
        OneSignal.getTags({tagsReceived in
            print("tagsReceived: ", tagsReceived.debugDescription)
            var tagsArray = [String]()
            if let tagsHashableDictionary = tagsReceived {
              tagsHashableDictionary.forEach({
                if let asString = $0.key as? String {
                  tagsArray += [asString]
                }
              })
            }
            print("tagsArray: ", tagsArray)
            OneSignal.deleteTags(tagsArray, onSuccess: { tagsDeleted in
                print("tags deleted success: ", tagsDeleted.debugDescription)
                self.osTags = "tags deleted: \(tagsDeleted!.count)"
                self.updateTextView()
            }, onFailure: { error in
                print("deleting tags error: ", error.debugDescription)
                self.osTags = error.debugDescription
                self.updateTextView()
            })
        })
    }
    
    
    @IBAction func triggerIAMCarouselFun(sender: Any) {
        print("clicked triggerIAMCarouselFun button")
        OneSignal.addTrigger("carousel_fun", withValue: "true")
    }
    
    @IBAction func sendTagsButton(sender: Any) {
        OneSignal.sendOutcome(withValue: "sendTags", value: 10.10, onSuccess: {outcomesSent in
            print("outcomes successfully sent: ", outcomesSent!.debugDescription)
        })
        let userValues = Cloud.sharedInstance.googleCurrentUser()
        var tagsToSend: [String: String] = ["ios": "true"]
        if let isCurrentUser = userValues["isCurrentUser"] {
            tagsToSend["isCurrentUser"] = isCurrentUser
        }
        if let profileImageUrl = userValues["profileImageUrl"] {
            tagsToSend["profileImageUrl"] = profileImageUrl
        }
        OneSignal.sendTags(tagsToSend, onSuccess: {tagsSent in
            self.osTags = tagsToSend.toString()
            self.updateTextView()
        }, onFailure: {tagsFailed in
            self.osTags = tagsFailed!.localizedDescription
            self.updateTextView()
            print("tagsFailed: ", tagsFailed!.localizedDescription)
        })
    }
    
    @IBAction func deleteTagsButton(sender: Any) {
        OneSignal.getTags({tagsReceived in
            print("tagsReceived: ", tagsReceived.debugDescription)
            var tagsArray = [String]()
            if let tagsHashableDictionary = tagsReceived {
              tagsHashableDictionary.forEach({
                if let asString = $0.key as? String {
                  tagsArray += [asString]
                }
              })
            }
            print("tagsArray: ", tagsArray)
            OneSignal.deleteTags(tagsArray, onSuccess: { tagsDeleted in
                print("tags deleted success: ", tagsDeleted.debugDescription)
                self.osTags = "tags deleted: \(tagsDeleted!.count)"
                self.updateTextView()
            }, onFailure: { error in
                print("deleting tags error: ", error.debugDescription)
                self.osTags = error.debugDescription
                self.updateTextView()
            })
        })
    }
    
    @IBAction func promptLocation(sender: Any) {
        OneSignal.promptLocation()
    
    }
    
    @IBAction func sendOutcome(sender: Any) {
        let number = Int.random(in: 0..<1000)
        let value:Float = Float(number) + 0.49
        OneSignal.sendOutcome(withValue: "Purchase", value: NSNumber(value:value), onSuccess: {outcomeSent in
            print("outcome sent: \(outcomeSent!.name) with random value: \(value)" )
        })
    }
    
    @IBAction func postNotification(sender: Any) {
        
        let content: [String : Any] = [
            //"content_available" : true,
            //"send_after" : "2021-10-20 14:58:49 GMT+3",
            "contents": ["en": "Contents Example"],
            "headings": ["en": "Headings Example"],
            "include_player_ids": [osPlayerId],
            "data" : ["action" : "custom_action"]
        ]
        
        OneSignal.postNotification(content)
    }
    
    
    @IBAction func getDeviceStateButton(sender: Any) {
        if let deviceState = OneSignal.getDeviceState() {
            let emailAddress = deviceState.emailAddress
            print("Email Address tied to this device with setEmail: ", emailAddress ?? "called too early or not set yet" )
            let emailUserId = deviceState.emailUserId
            print("OneSignal Email player ID: ", emailUserId ?? "called too early or not set yet")
            let hasNotificationPermission = deviceState.hasNotificationPermission
            print("Has device allowed push permission at some point: ", hasNotificationPermission)
            let isEmailSubscribed = deviceState.isEmailSubscribed
            print("is the email address tied to this record subscribed to receive email: ", isEmailSubscribed)
            let isPushDisabled = deviceState.isPushDisabled
            print("Push notifications are disabled with disablePush method: ", isPushDisabled)
            let isSMSSubscribed = deviceState.isSMSSubscribed
            print("is the phone number tied to this record subscribed to receive sms: ", isSMSSubscribed)
            let isSubscribed = deviceState.isSubscribed
            print("Device is subscribed to push notifications: ", isSubscribed)
            let notificationPermissionStatus = deviceState.notificationPermissionStatus.rawValue
            print("Device's notification permission status: ", notificationPermissionStatus)
            let pushToken = deviceState.pushToken
            print("Device's push token: ", pushToken ?? "called too early or not set yet" )
            let smsNumber = deviceState.smsNumber
            print("Phone Number tied to this device with setSMSNumber: ", smsNumber ?? "called too early or not set yet" )
            let smsUserId = deviceState.smsUserId
            print("OneSignal SMS player ID: ", smsUserId ?? "called too early or not set yet")
            let userId = deviceState.userId
            print("OneSignal Push Player ID: ", userId ?? "called too early, not set yet")
            self.osPlayerId = userId!
        }
    }
    


}

