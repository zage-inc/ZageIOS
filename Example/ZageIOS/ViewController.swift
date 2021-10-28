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
    let TEST_PUBLIC_KEY = "sakdjhkj-test-key";
    let TEST_PAYMENT_TOKEN = "test-sakdjhkj-6104";
    
    var zage: Zage;
    var paymentViewController: UIViewController;
    
    let button: UIButton = {
        let button = UIButton()
        button.setTitle("Z-Pay", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    

    required init?(coder: NSCoder) {
        zage = Zage(publicKey: TEST_PUBLIC_KEY)
        paymentViewController = zage.getViewController()
        
        super.init(nibName: nil, bundle: nil);
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(button)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 200, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.1)
        button.center = view.center
        button.layer.cornerRadius = 40
    }
    
    @objc private func didTapButton() {
        view.addSubview(paymentViewController.view)
        present(paymentViewController, animated: true)
        zage.openPayment(token: TEST_PAYMENT_TOKEN, onComplete: printComplete, onExit: printExit)
    }
    
    private func printComplete(idk: Any) -> Void {
        print("i completed a payment with response: \(idk)")
    }
    
    private func printExit() -> Void {
        print("i exited a payment")
    }


}
