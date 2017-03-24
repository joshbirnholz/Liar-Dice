//
//  JoinGameViewController.swift
//  Liar Dice
//
//  Created by Josh Birnholz on 3/21/17.
//  Copyright © 2017 Joshua Birnholz. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import MBProgressHUD
import MarqueeLabel

class PeerCell: UITableViewCell {
	
	@IBOutlet weak var label: UILabel!
	
}

class JoinGameViewController: UIViewController {

	var otherPlayerPeerID: MCPeerID!
	
	@IBOutlet weak var detailLabel: MarqueeLabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
			self.detailLabel.holdScrolling = false
		}
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		peerManager.delegate = self
		peerManager.browser.startBrowsingForPeers()
		print("Started browsing")
		
		peerManager.advertiser.stopAdvertisingPeer()
		print("Stopped advertising")
		
		tableView.reloadData()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		peerManager.browser.stopBrowsingForPeers()
		print("Stopped browsing")
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBOutlet weak var tableView: UITableView!
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? MainGameViewController {
		
			destination.player = .one
			destination.otherPlayerPeerID = otherPlayerPeerID
		}
	}

}

extension JoinGameViewController: MCManagerDelegate {
	
	func didReceiveMessage(_ message: [String : Any]) {
		
	}
	
	func foundPeer(_ peer: MCPeerID) {
		print(#function)
		guard let index = peerManager.foundPeers.index(of: peer) else {
			tableView.reloadData()
			return
		}
		
		tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
	}
	
	func lostPeer(_ peer: MCPeerID, at index: Int?) {
		guard let index = index else {
			tableView.reloadData()
			return
		}
		
		tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
	}
	
	func invitationReceived(from peer: MCPeerID, invitationHandler: @escaping ((Bool, MCSession?) -> Void)) {
		invitationHandler(false, nil)
	}
	
	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		DispatchQueue.main.async {
			MBProgressHUD.hide(for: self.view, animated: true)
			
			switch state {
			case .connected:
				peerManager.browser.stopBrowsingForPeers()
				
				self.otherPlayerPeerID = peerID
				
				self.performSegue(withIdentifier: "readyPlayerOne", sender: self)
				
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

extension JoinGameViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		print(#function)
		
		tableView.deselectRow(at: indexPath, animated: false)
		
		let peer = peerManager.foundPeers[indexPath.row]
		
		peerManager.browser.invitePeer(peer, to: peerManager.session, withContext: nil, timeout: 60)
		
		MBProgressHUD.showAdded(to: self.view, animated: true)
		
	}
	
}

extension JoinGameViewController: UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return peerManager.foundPeers.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "peerCell", for: indexPath) as! PeerCell
		
		let peer = peerManager.foundPeers[indexPath.row]
		
		cell.label.text = peer.displayName
		
		return cell
		
	}
	
}
