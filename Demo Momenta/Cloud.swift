//
//  Google.swift
//  Demo Momenta
//
//  Created by JonF on 9/22/21.
//

import Firebase
import GoogleSignIn

class Cloud {
    static let sharedInstance = Cloud()
    private init() {}
    
    private let googleSignInConfig = GIDConfiguration.init(clientID: "617799002572-ks7v86v6gkv73os6qq3j43u8bbbmg2d4.apps.googleusercontent.com")
    
    func initFirebase(){
        FirebaseApp.configure()
    }
    
    func googleSignIn(presentingViewController: UIViewController, completion: @escaping ([String: AnyObject]) -> (), err: @escaping (Error)->()) {
        GIDSignIn.sharedInstance.signIn(with: googleSignInConfig, presenting: presentingViewController) { user, error in
            if let error = error {
                print("sign in error: ", error.localizedDescription)
                err(error)
            } else {
                guard let user = user else { return }
                let googleUserId = user.userID
                let email = user.profile?.email ?? ""
                let givenName = user.profile?.givenName ?? ""
                let familyName = user.profile?.familyName ?? ""
                let profileImageUrl = user.profile?.imageURL(withDimension: 50)
                let authentication = user.authentication
                let idToken = authentication.idToken!
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
                let values: [String: AnyObject] = ["googleUserId": googleUserId as AnyObject, "email": email as AnyObject, "firstName": givenName as AnyObject, "lastName": familyName as AnyObject, "profileImageUrl": profileImageUrl as AnyObject, "credential": credential as AnyObject]
                completion(values)
            }
        }
    }
    
    func googleSignOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    func googleCurrentUser() -> [String: String] {
        let currentUser = GIDSignIn.sharedInstance.currentUser
        let isCurrentUser: String
        if currentUser != nil {
            isCurrentUser = "true"
            let googleUserId = currentUser!.userID!
            let email = currentUser!.profile?.email ?? ""
            let givenName = currentUser!.profile?.givenName ?? ""
            let familyName = currentUser!.profile?.familyName ?? ""
            let profileImageUrl = currentUser!.profile?.imageURL(withDimension: 50)?.absoluteString ?? ""
            let values: [String: String] = ["isCurrentUser": isCurrentUser, "googleUserId": googleUserId, "email": email, "firstName": givenName, "lastName": familyName, "profileImageUrl": profileImageUrl]
            return values
        } else {
            isCurrentUser = "false"
            let values: [String: String] = ["isCurrentUser": isCurrentUser]
            return values
        }
    }
    
    func googleRestorePreviousSignIn(completion: @escaping (String, String, String, String) -> (), err: @escaping (Error)->()) {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("restore sign in error: ", error.localizedDescription)
                //err(error)
            }
            if user == nil {
                // Show the app's signed-out state.
                print("user is nil")
            } else {
                // Show the app's signed-in state.
                let email = user!.profile!.email
                let first_name  = user!.profile?.givenName ?? ""
                let last_name = user!.profile?.familyName ?? ""
                let googleUserId = user!.userID!
                completion(email, first_name, last_name, googleUserId)
            }
        }
    }
    
    func firebaseSignIn(credential: AuthCredential, completion: @escaping (String) -> (), err: @escaping (Error)->()) {
        Auth.auth().signIn(with: credential, completion: {( authResult, error) in
            if let error = error {
                print("restore sign in error: ", error.localizedDescription)
                err(error)
                return
            }
            if authResult != nil {
                let uid = authResult!.user.uid
                completion(uid)
            } else {
                return
            }
        })
    }
    
    func getFirebaseUserId(completion:@escaping (String?) -> ()) {
        if let user = Auth.auth().currentUser {
            let userId = user.uid
            completion(userId)
        }
    }
    
    func firebaseSignOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("signout failed: ", signOutError)
            return
        }
        print("signout firebase success")
    }
    
    func createOrUpdateHubSpotUser(email: String, external_user_id: String, firstName: String, lastName: String) {
        guard let url = URL(string: "https://api.hubapi.com/contacts/v1/contact/createOrUpdate/email/\(email)/?hapikey=f5c78303-3528-4d21-820e-f856435c4bff") else { return }
            
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
            
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let timestamp = Int(NSDate().timeIntervalSince1970).toString()
                    
        let body: [String: Any] = [
            "properties": [
                [
                    "property": "email",
                    "value": email
                ],
                [
                    "property": "external_user_id",
                    "value": external_user_id
                ],
                [
                    "property": "firstname",
                    "value": firstName
                ],
                [
                    "property": "lastname",
                    "value": lastName
                ],
                [
                    "property": "lifecyclestage",
                    "value": "customer"
                ],
                [
                    "property": "annualrevenue",
                    "value": timestamp
                ]
                
            ]
                
        ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch let error {
                print("An error occurred while parsing the body into JSON.", error)
            }
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("An error occurred", error)
                    return
                }
                
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("json: ", json)
                        }
                    } catch let error {
                        print("Error parsing the data into JSON: ", error)
                    }
                }
            }.resume()
        }
//    }
//    func createOrUpdateHubSpotUser(email: String){
//        let url = URL(string: "https://api.hubapi.com/contacts/v1/contact/createOrUpdate/email/\(email)/?hapikey=f5c78303-3528-4d21-820e-f856435c4bff")!
//        let task = URLSessionTask
//    }
    
    
    
        
}
