//
//  SettingsViewController.swift
//  MyWeb
//
//  Created by Jake Cronin on 8/5/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation
import UIKit
import FBSDKLoginKit

class SettingsViewController: UITableViewController{
	
	var networkVizController: NetworkViewController!
	
	@IBOutlet weak var nameLabelSwitch: UISwitch!
	@IBOutlet weak var loggedInAsLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		print("\(networkVizController.description)")
		nameLabelSwitch.isOn = networkVizController.showNameLabels
		if let name = networkVizController.myProfile["name"] as? String{
			loggedInAsLabel.text = "Logged in as \(name)"
		}else{
			loggedInAsLabel.text = "Error getting username"
		}
	}
	@IBAction func laggoutPressed(sender: AnyObject){
		FBSDKLoginManager().logOut()
		performSegue(withIdentifier: "unwindToSettings", sender: nil)
	}
	@IBAction func nameLabelsChanged(mySwitch: UISwitch){
		networkVizController.showNameLabels = nameLabelSwitch.isOn
	}
	
	override func willMove(toParentViewController parent: UIViewController?) {
		networkVizController.redrawGraph()
	}
	
}
