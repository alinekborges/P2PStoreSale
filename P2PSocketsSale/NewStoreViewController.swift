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
    @IBOutlet weak var emojiTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    
    var products: [Product] = []
    
    var delegate: CreateNewStore?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func newProductAction(_ sender: Any) {
        guard let emoji = self.emojiTextField.text else {
            return
        }
        
        guard let price = Double(self.priceTextField.text!) else {
            return
        }
        
        guard let quantity = Int(self.quantityTextField.text!) else {
            return
        }
        
        let product = Product(emoji: emoji, quantity: quantity, price: Int(price))
        
        self.products.append(product)
        self.tableView.reloadData()
    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        guard let name = self.nameTextField.text else {
            return
        }
        self.delegate?.didCreateStore(withName: name, products: self.products)
        self.navigationController?.popViewController(animated: true)
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
        self.quantityLabel.text = "quantity: \(product.quantity)"
        self.priceLabel.text = "\(product.price)"
    }
    
}
