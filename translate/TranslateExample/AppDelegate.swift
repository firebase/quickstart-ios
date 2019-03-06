import UIKit
import third_party_firebase_ios_Releases_FirebaseCore_FIRCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

#if !swift(>=4.2)
extension UIApplication {
  typealias LaunchOptionsKey = UIApplicationLaunchOptionsKey
}
#endif  // !swift(>=4.2)
