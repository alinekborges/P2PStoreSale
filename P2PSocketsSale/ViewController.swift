//
//  ViewController.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 08/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var stores: [Store] = []
    var viewControllers: [StoreViewController] = []
    
    @IBOutlet var containerViews: [UIView]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        //store1 = Store(port: 6790)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func newStoreAction(_ sender: Any) {
        
        let product1 = Product()
        var product2 = Product()
        while product2.emoji == product1.emoji {
            product2 = Product()
        }

        self.didCreateStore(withName: "\(random())", products: [product1, product2])
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        
        //let store = Store(name: "hey")
        //port += 1
        
        //self.stores.append(store)
    }

    func random() -> Int {
        let diceRoll = Int(arc4random_uniform(2000))
        return diceRoll
    }

    @IBAction func sendMessageAction(_ sender: Any) {
        //self.stores.first!.send(message: "heeeeeey\n")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewStore" {
            let vc = segue.destination as! NewStoreViewController
            vc.delegate = self
        }
    }
}

extension ViewController: CreateNewStore {
    func didCreateStore(withName name: String, products: [Product]) {
        let store = Store(name: name, products: products)
        self.stores.append(store)
        
        let vc = StoreViewController(store: store)
        addNewStoreController(vc)
        
    }
    
    func addNewStoreController(_ controller: StoreViewController) {
        if let emptyContainer = self.containerViews.filter( {$0.subviews.isEmpty} ).first {
            emptyContainer.addSubview(controller.view)
            controller.view.frame = emptyContainer.bounds
            controller.view.bounds = emptyContainer.bounds
            
            self.addChildViewController(controller)
        } else {
            print("Você chegou ao máximo de lojas!")
        }
    }
}

