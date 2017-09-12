//
//  StoreCell.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import UIKit

class StoreCell: UITableViewCell {
    
    static let identifier = "StoreCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setStore(_ store: StoreBase) {
        let icons = store.products!
            .map( {$0.emoji!} )
            .joined()
        self.titleLabel.text = "\(store.name ?? "")\(icons)"
        self.scoreLabel.text = "\(store.score!)"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    
}
