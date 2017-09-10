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
    
    init(store: Store) {
        self.store = store
        super.init(nibName: String(describing: StoreViewController.self), bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        
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
    

}
