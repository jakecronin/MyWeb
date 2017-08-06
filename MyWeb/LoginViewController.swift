//
//  ViewController.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/8/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore
import FBSDKLoginKit


var themeMainColor = UIColor.white

class LoginViewController: UIViewController {
	
	
	var loginButton: FBSDKLoginButton!
	@IBOutlet weak var container: UIView!
	var activityIndicator = UIActivityIndicatorView()
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//Setup Facebook Login
		loginButton = FBSDKLoginButton()
		loginButton.readPermissions = [ "public_profile", "email", "user_friends", "user_photos", "user_likes", "user_posts"]
		loginButton.delegate = self
		view.addSubview(loginButton)
		loginButton.center = view.center
		
		//if already logged in, skip
		if let accessToken = AccessToken.current {
			print("autologin")
			segueLogin()
		}
	}
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func beginActivityIndicator(){
		activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
		activityIndicator.center = self.container.center
		activityIndicator.hidesWhenStopped = true
		activityIndicator.color = themeMainColor
		self.container.addSubview(activityIndicator)
		activityIndicator.startAnimating()
		UIApplication.shared.beginIgnoringInteractionEvents()
		
	}
	func stopActivityIndicator(){
		self.activityIndicator.stopAnimating()
		UIApplication.shared.endIgnoringInteractionEvents()
	}

	func segueLogin(){
		print("segue login")
		DispatchQueue.main.async{
			self.performSegue(withIdentifier: "segueLogin", sender: self)
		}
	}
	@IBAction func unwindToLogin(segue: UIStoryboardSegue){
		
	}
}

extension LoginViewController: FBSDKLoginButtonDelegate{
	func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
		if let accessToken = AccessToken.current{
			segueLogin()
		}else{
			print("error loggin in with facebook")
		}
	}
	func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
		print("logged out")
	}
	func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
		print("will login")
		return true
	}
	
}
