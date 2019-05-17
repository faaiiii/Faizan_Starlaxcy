

import UIKit
import Firebase
import FirebaseUI




class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func login(_ sender: Any) {
        performSegue(withIdentifier: "Login_Segue", sender: self)
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        
        
        // Create default Auth UI
        let authUI = FUIAuth.defaultAuthUI()
        
        // Check that it isn't nil
        guard authUI != nil else {
            return
        }
        
        // Set delegate and specify sign in options
        authUI?.delegate = self as? FUIAuthDelegate
        authUI?.providers = [FUIEmailAuth()]
        
        // Get the auth view controller and present it
        let authViewController = authUI!.authViewController()
        present(authViewController, animated: true, completion: nil)
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    extension LoginViewController: FUIAuthDelegate {
        
        
        
        func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
            
            // Check for error
            guard error == nil else {
                return
            }
            
            // Transition to home
            performSegue(withIdentifier: "Login_Segue", sender: self)
        }
        
    }
    
    

