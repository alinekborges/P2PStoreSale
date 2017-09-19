//
//  NewStoreViewController.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import UIKit

protocol CreateNewStore {
    func didCreateStore(withName name: String, products: [Product])
}

class NewStoreViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emojiButton: UIButton!
    
    
    var products: [Product] = []
    
    var delegate: CreateNewStore?
    
    var currentEmoji: String = "💩"
    var currentQuantity: Int = 1
    var currentPrice: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func emojiButtonAction(_ sender: UIButton) {
        let picker = CustomPickerCollectionViewController.fromStoryboard(withStyle: .emoji, sourceView: sender)
        self.present(picker, animated: true, completion: nil)
        
        picker.didPickEmoji = {emoji in
            sender.setTitle(emoji, for: .normal)
            self.currentEmoji = emoji
            self.dismiss(animated: true, completion: nil)
        }

    }
    
    @IBAction func quantityButton(_ sender: UIButton) {
        
        let picker = CustomPickerCollectionViewController.fromStoryboard(withStyle: .number, sourceView: sender)
        self.present(picker, animated: true, completion: nil)
        
        picker.didPickNumber = {number in
            sender.setTitle("\(number)", for: .normal)
            self.currentQuantity = number
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func priceButtonAction(_ sender: UIButton) {
        
        let picker = CustomPickerCollectionViewController.fromStoryboard(withStyle: .number, sourceView: sender)
        self.present(picker, animated: true, completion: nil)
        
        picker.didPickNumber = {number in
            sender.setTitle("\(number)", for: .normal)
            self.currentPrice = number
            self.dismiss(animated: true, completion: nil)
            
        }
        
        
    }
    
    @IBAction func newProductAction(_ sender: Any) {
        let product = Product(emoji: self.currentEmoji, quantity: self.currentQuantity, price: self.currentPrice)
        
        self.products.append(product)
        self.tableView.reloadData()
    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        guard let name = self.nameTextField.text else {
            return
        }
        self.delegate?.didCreateStore(withName: name, products: self.products)
        
    }
    

}

extension NewStoreViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.identifier, for: indexPath) as! ProductCell
        
        let item = products[indexPath.row]
        cell.printProduct(item)
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.products.count
    }
}

class ProductCell: UITableViewCell {

    static let identifier = "productCell"
    
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    func printProduct(_ product: Product) {
        self.emojiLabel.text = product.emoji
        self.quantityLabel.text = "quantity: \(product.quantity!)"
        self.priceLabel.text = "\(product.price!)"
    }
    
}
