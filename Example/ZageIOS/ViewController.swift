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
    let TEST_PUBLIC_KEY = "sandbox_public_key"
    let TEST_PAYMENT_TOKEN = ""
    
    var zage: Zage?;
    
    let button: UIButton = {
        let button = UIButton()
        button.setTitle("Pay with Zage", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    
    let infoModalButton: UIButton = {
        let button = UIButton()
        button.setTitle("Learn about Zage", for: .normal)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    

    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = UIColor.white
        
        zage = Zage(context: self, publicKey: TEST_PUBLIC_KEY)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(button)
        
        button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 200, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.1)
        button.center = view.center
        button.layer.cornerRadius = 40
        
        view.addSubview(infoModalButton)
        infoModalButton.addTarget(self, action: #selector(didTapInfoButton(_:)), for: .touchUpInside)
        infoModalButton.frame = CGRect(x: 0, y: 200, width: self.view.frame.width * 0.5, height:
                                self.view.frame.height * 0.1)
        
    }
    
    @objc private func didTapButton(_ sender: UIButton) {
        zage?.openPayment(paymentToken: TEST_PAYMENT_TOKEN, onComplete: printComplete, onExit: printExit)
    }
    
    @objc private func didTapInfoButton(_ sender: UIButton) {
        zage?.openModal()
    }
    
    private func printComplete(response: Any) -> Void {
        print("i completed a payment with response: \(response)")
    }
    
    private func printExit() -> Void {
        print("i exited a payment")
    }
}
