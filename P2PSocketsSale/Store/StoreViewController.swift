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
    
    var timer: Timer?
    
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
        
        self.titleLabel.text = self.store.name
        
        self.tableView.register(UINib(nibName: StoreProductCell.identifier, bundle: nil), forCellReuseIdentifier: StoreProductCell.identifier)
        self.tableView.register(UINib(nibName: StoreCell.identifier, bundle: nil), forCellReuseIdentifier: StoreCell.identifier)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsSelection = false
        
        timer = Timer.scheduledTimer(timeInterval: Constants.timeInterval, target: self, selector: #selector(self.onTick), userInfo: nil, repeats: true)
    }
    
    func onTick() {
        self.store.onTick()
    }

    @IBAction func emojiPickerAction(_ sender: UIButton) {
        let picker = CustomPickerCollectionViewController.fromStoryboard(withStyle: .emoji, sourceView: sender)
        self.present(picker, animated: true, completion: nil)
        
        picker.didPickEmoji = {emoji in
            sender.setTitle(emoji, for: .normal)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func pickQuantityAction(_ sender: UIButton) {
        
        let picker = CustomPickerCollectionViewController.fromStoryboard(withStyle: .number, sourceView: sender)
        self.present(picker, animated: true, completion: nil)
        
        picker.didPickNumber = {number in
            sender.setTitle("\(number)", for: .normal)
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func disconnectStore(_ sender: Any) {
        
        let alert = UIAlertController(title: self.store.name, message: "Are you sure you want to disconnect?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
            print("disconnect")
            self.store.disconnect()
            self.view.removeFromSuperview()
            self.timer?.invalidate()
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
            //return store.bossManager!.allStores.count
            return 0
        } else {
            return store.products.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if store.isBoss {
            let cell = tableView.dequeueReusableCell(withIdentifier: StoreCell.identifier, for: indexPath) as! StoreCell
            if (!self.store.bossManager!.allStores.isEmpty) {
                let item = self.store.bossManager!.allStores[indexPath.row]
                cell.setStore(item)
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
