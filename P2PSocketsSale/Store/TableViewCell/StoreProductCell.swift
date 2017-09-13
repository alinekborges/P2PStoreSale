//
//  ProductCell.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import UIKit

class StoreProductCell: UITableViewCell {
    
    static let identifier = "StoreProductCell"

    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setProduct(_ product: Product) {
        emojiLabel.text = product.emoji!
        priceLabel.text = "R$\(product.price!),00"
        quantityLabel.text = "\(product.quantity!)"
    }
    
}
