//
//  Zage.swift
//  ZageIOS
//
//  Created by Michael Sun on 10/28/21.
//

import Foundation

public class Zage {
    private var vc: ZageWebViewViewController
    
    public init(publicKey: String) {
        self.vc = ZageWebViewViewController(publicKey: publicKey)
    }
    
    public func openPayment(token: String, onComplete: @escaping (Any) -> Void, onExit: @escaping () -> Void) -> Void {
        vc.openPayment(token: token, onComplete: onComplete, onExit: onExit)
    }
    
    public func getViewController() -> UIViewController {
        return vc
    }
}


