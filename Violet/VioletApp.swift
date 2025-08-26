//
//  VioletApp.swift
//  Violet
//
//  Created by Mihail Gjoni on 6/30/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
//for fire base________________________________________________________________________
class AppDelegate: NSObject, UIApplicationDelegate{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool{
        FirebaseApp.configure()
        return true
    }
    
    @available(iOS 9.0, *)
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    
    
}
//for fire base________________________________________________________________________
@main
struct VioletApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
          NavigationView {
            ContentView()
          }
        }
      }
    }
