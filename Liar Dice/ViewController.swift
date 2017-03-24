//
//  ViewController.swift
//  Liar Dice
//
//  Created by Josh Birnholz on 3/20/17.
//  Copyright © 2017 Joshua Birnholz. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, UIGestureRecognizerDelegate {
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Enable swipe back when no navigation bar
		navigationController?.interactivePopGestureRecognizer?.delegate = self
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		peerManager.foundPeers.removeAll()
	}
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if(navigationController!.viewControllers.count > 1){
			return true
		}
		return false
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		print(#function)
	}
	
	@IBAction func unwind(segue: UIStoryboardSegue) {
		
		peerManager.delegate = nil
		peerManager.browser.stopBrowsingForPeers()
		print("Stopped browsing")
		peerManager.advertiser.stopAdvertisingPeer()
		print("Stopped advertising")
		
		peerManager.session.disconnect()
		print("Disconnected")
		
	}
	
}
