//
//  HostViewController.swift
//  Liar Dice
//
//  Created by Josh Birnholz on 3/21/17.
//  Copyright © 2017 Joshua Birnholz. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import MBProgressHUD
import MarqueeLabel

class HostViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	
	var otherPlayerPeerID: MCPeerID!
	
	var invitations: [(peer: MCPeerID, invitationHandler: (Bool, MCSession?) -> Void)] = []
	
	@IBOutlet weak var detailLabel: MarqueeLabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
			self.detailLabel.holdScrolling = false
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		peerManager.delegate = self
		peerManager.advertiser.startAdvertisingPeer()
		print("Started advertising")
		
		peerManager.browser.stopBrowsingForPeers()
		print("Stopped browsing")
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		peerManager.advertiser.stopAdvertisingPeer()
		print("Stopped advertising")
		
		for invitation in invitations {
			invitation.invitationHandler(false, nil)
		}
		
		invitations.removeAll()
		
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? MainGameViewController {
		
			destination.player = .two
			destination.otherPlayerPeerID = otherPlayerPeerID
		}
	}
	
}

extension HostViewController: MCManagerDelegate {
	
	func didReceiveMessage(_ message: [String : Any]) {
		
	}
	
	func foundPeer(_ peer: MCPeerID) {
		
	}
	
	func lostPeer(_ peer: MCPeerID, at index: Int?) {
		
	}
	
	func invitationReceived(from peer: MCPeerID, invitationHandler: @escaping ((Bool, MCSession?) -> Void)) {
		
		invitations.append(peer: peer, invitationHandler: invitationHandler)
		
		tableView.insertRows(at: [IndexPath(row: invitations.count - 1, section: 0)], with: .automatic)
		
	}
	
	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		DispatchQueue.main.async {
			MBProgressHUD.hide(for: self.view, animated: true)
			
			switch state {
			case .connected:
				peerManager.advertiser.stopAdvertisingPeer()
				
				self.otherPlayerPeerID = peerID
				
				self.performSegue(withIdentifier: "readyPlayerTwo", sender: self)
			case .connecting:
				let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
				hud.label.text = "Connecting to \"\(peerID.displayName)\""
			case .notConnected:
				let alert = UIAlertController(title: "You have been disconnected from the other player.", message: nil, preferredStyle: .alert)
				
				let okAction = UIAlertAction(title: "OK", style: .default) { _ in
					self.navigationController?.popToRootViewController(animated: true)
				}
				
				alert.addAction(okAction)
				
				self.present(alert, animated: true, completion: nil)
			}
		}
	}
	
}

extension HostViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		tableView.deselectRow(at: indexPath, animated: false)
		
		let invitation = invitations.remove(at: indexPath.row)
		
		invitation.invitationHandler(true, peerManager.session)
		
		// Deny all other invitations
		DispatchQueue.global(qos: .background).async {
			for invitation in self.invitations {
				invitation.invitationHandler(false, nil)
			}
			
			self.invitations.removeAll()
		}
		
	}
	
}

extension HostViewController: UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return invitations.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "hostCell", for: indexPath) as! PeerCell
		
		let peer = invitations[indexPath.row].peer
		
		cell.label.text = peer.displayName
		
		return cell
		
	}
	
}

