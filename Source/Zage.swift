//
//  Zage.swift
//  ZageIOS
//
//  Created by Michael Sun on 10/28/21.
//

import Foundation

// Zage object that wraps the Zage WebView ViewController
public class Zage {
    // The actual view controller that manages the connection between the Swift webview
    // and the Apollo iFrame that is injected
    private var vc: ZageWebViewViewController
    
    // The view controller that the payment flow will sit on top of
    private var context: UIViewController
    
    public init(context: UIViewController, publicKey: String) {
        self.vc = ZageWebViewViewController(publicKey: publicKey)
        self.context = context
        
        // Load the view controller to context, but do not start the payment flow
        context.view.addSubview(vc.webView)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    public func openPayment(paymentToken: String, onSuccess: @escaping (Any) -> Void, onExit: @escaping () -> Void) -> Void {
        // Present the view controller in context
        context.present(vc, animated: true)
        // Commence the payment flow
        vc.openPayment(paymentToken: paymentToken, onSuccess: onSuccess, onExit: onExit)
    }
    
}


