//
//  ViewController.swift
//  ZageIOS
//
//  Created by Michael Sun on 10/28/2021.
//  Copyright (c) 2021 Michael Sun. All rights reserved.
//

import UIKit
import ZageIOS

class ViewController: UIViewController {
    let TEST_PUBLIC_KEY = "sandbox_key_60jp0v85tbpwev8p";
    let TEST_PAYMENT_TOKEN = "tk_4dde9564-22b1-42ec-b0e3-bc7526da7ac1";
    
    var zage: Zage?;
    
    let button: UIButton = {
        let button = UIButton()
        button.setTitle("Z-Pay", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    

    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil);
        self.view.backgroundColor = UIColor.white
        
        zage = Zage(context: self, publicKey: TEST_PUBLIC_KEY)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(button)
        
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 200, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.1)
        button.center = view.center
        button.layer.cornerRadius = 40
    }
    
    @objc private func didTapButton() {
        print("asdijfasdf")
        zage?.openPayment(paymentToken: TEST_PAYMENT_TOKEN, onSuccess: printSuccess, onExit: printExit)
    }
    
    private func printSuccess(idk: Any) -> Void {
        print("i completed a payment with response: \(idk)")
    }
    
    private func printExit() -> Void {
        print("i exited a payment")
    }
}
