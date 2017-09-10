//
//  CustomPickerCollectionViewController.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import UIKit

private let reuseIdentifier = "PickerCell"

class CustomPickerCollectionViewController: UICollectionViewController {
    
    let emojis = ["❤️", "💩", "😈", "👻", "🐶", "💸", "🎃", "😍", "😸"]
    let numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    var didPickEmoji: ((String)->())?
    var didPickNumber: ((Int)->())?
    
    enum Style {
        case emoji, number
    }
    
    var items:[String] = []
    var style: Style = .emoji {
        didSet {
            switch style {
            case .emoji:
                self.items = emojis
            case .number:
                self.items = numbers
            }
            self.collectionView?.reloadData()
        }
    }
    
    class func fromStoryboard(withStyle style: Style, sourceView: UIView) -> CustomPickerCollectionViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CustomPickerViewController") as!
        CustomPickerCollectionViewController
        vc.style = style
        vc.modalPresentationStyle = .popover
        let popover = vc.popoverPresentationController
        popover?.sourceView = sourceView
        popover?.sourceRect = sourceView.frame
        vc.preferredContentSize = CGSize(width: 240, height: 240)
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PickerCollectionViewCell
    
        let item = self.items[indexPath.row]
        cell.titleLabel.text = item
        
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        
        switch style {
        case .emoji:
            self.didPickEmoji?(item)
        case .number:
            if let number = Int(item) {
                self.didPickNumber?(number)
            }
        }
        
        
    }
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

class PickerCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
}
