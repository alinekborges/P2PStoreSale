//
//  StoreViewController.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import UIKit

class StoreViewController: UIViewController {
    
    var store: Store
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var buyView: UIView!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var keepAliveView: UIView!
    
    var timer: Timer?
    var secondTimer: Timer?
    
    var currentEmoji: String = "💩"
    var currentQuantity: Int = 2
    
    init(store: Store) {
        self.store = store
        super.init(nibName: String(describing: StoreViewController.self), bundle: nil)
        store.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.keepAliveView.alpha = 0.0
        
        self.titleLabel.text = self.store.name
        
        self.tableView.register(UINib(nibName: StoreProductCell.identifier, bundle: nil), forCellReuseIdentifier: StoreProductCell.identifier)
        self.tableView.register(UINib(nibName: StoreCell.identifier, bundle: nil), forCellReuseIdentifier: StoreCell.identifier)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsSelection = false
        
        timer = Timer.scheduledTimer(timeInterval: Constants.timeInterval, target: self, selector: #selector(self.onTick), userInfo: nil, repeats: true)
        
        //secondTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.announceStoreAgain), userInfo: nil, repeats: true)
        
        self.registerNotification(notificationName: "update_UI", withSelector: #selector(self.updateUI))
        
        self.registerNotification(notificationName: "keep_alive", withSelector: #selector(self.keepAlive))
        
        self.registerNotification(notificationName: "start_election.\(self.store.name)", withSelector: #selector(self.startElection))
        
        self.registerNotification(notificationName: "end_election.\(self.store.name)", withSelector: #selector(self.endElection))
    }
    
    func onTick() {
        self.store.onTick()
    }
    
    func announceStoreAgain() {
        self.store.announceStore()
    }

    @IBAction func emojiPickerAction(_ sender: UIButton) {
        let picker = CustomPickerCollectionViewController.fromStoryboard(withStyle: .emoji, sourceView: sender)
        self.present(picker, animated: true, completion: nil)
        
        picker.didPickEmoji = {emoji in
            sender.setTitle(emoji, for: .normal)
            self.currentEmoji = emoji
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func pickQuantityAction(_ sender: UIButton) {
        
        let picker = CustomPickerCollectionViewController.fromStoryboard(withStyle: .number, sourceView: sender)
        self.present(picker, animated: true, completion: nil)
        
        picker.didPickNumber = {number in
            sender.setTitle("\(number)", for: .normal)
            self.currentQuantity = number
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func buyAction(_ sender: Any) {
        let order = BuyOrder(emoji: self.currentEmoji, quantity: self.currentQuantity)
        self.store.sendBuyOrder(order)
        
    }
    
    @IBAction func disconnectStore(_ sender: Any) {
        
        let alert = UIAlertController(title: self.store.name, message: "Are you sure you want to disconnect?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
            print("disconnect")
            self.store.disconnect()
            self.view.removeFromSuperview()
            self.timer?.invalidate()
            self.secondTimer?.invalidate()
        }))
        
        alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func updateBossUI() {
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.backgroundView.backgroundColor = .teal
                self.titleLabel.textColor = .white
                self.buyView.isHidden = true
                self.buyButton.isHidden = true
            }
            
            print("I \(self.store.name) am selected as boss!")
            self.tableView.reloadData()
        }
    }
    
    func startElection() {
        self.view.backgroundColor = #colorLiteral(red: 0.02608692087, green: 0.7744804025, blue: 0.6751230955, alpha: 1).withAlphaComponent(0.2)
        
    }
    
    func endElection() {
        self.view.backgroundColor = #colorLiteral(red: 0.9373332858, green: 0.9379555583, blue: 0.9563199878, alpha: 1)
    }
    
    func updateUI() {
        self.tableView.reloadData()
    }
    
    func keepAlive() {
        UIView.animate(withDuration: 0.4, animations: {
            self.keepAliveView.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.4, animations: { 
                self.keepAliveView.alpha = 0.0
            })
            
        }
    }
}

extension StoreViewController: StoreDelegate {
    func isSelectedAsBoss() {
        updateBossUI()
    }

}

extension StoreViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if store.isBoss {
            return store.bossManager!.allStores.count
        } else {
            return store.products.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if store.isBoss {
            let cell = tableView.dequeueReusableCell(withIdentifier: StoreCell.identifier, for: indexPath) as! StoreCell
            if let allStores = self.store.bossManager?.allStores {
                if allStores.count > indexPath.row {
                    let item = allStores[indexPath.row]
                    cell.setStore(item)
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: StoreProductCell.identifier, for: indexPath) as! StoreProductCell
            let item = self.store.products[indexPath.row]
            cell.setProduct(item)
            return cell
        }
        
    }
    
}
