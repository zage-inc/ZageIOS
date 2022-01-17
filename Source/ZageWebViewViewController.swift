//
//  ZageWebViewViewController.swift
//  ZageIOS
//
//  Created by Michael Sun on 10/28/21.
//

import Foundation
//
//  ZageIOSPkg.swift
//  ZageIOSPkg
//
//  Created by Michael Sun on 10/27/21.
//
import Foundation
import WebKit
import UIKit

public class ZageWebViewViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    // The actual webView that is being used to display the Apollo iframe 
    var webView: WKWebView!

    private let zageApp = "https://sandbox.zage.dev/checkout"
    
    // On success call back for when the payment flow successfully completion
    private var onSuccess: ((Any) -> Void)!
    // On exit call back for when the payment flow is exited before completion
    private var onExit: (() -> Void)!
    // The merchant's public key
    private var publicKey: String
    
    init(publicKey: String) {
        self.publicKey = publicKey
        super.init(nibName: nil, bundle: nil)

        let webConfiguration = WKWebViewConfiguration()
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.load(URLRequest(url: URL(string: zageApp)!))
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        view = webView
        
        modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        let contentController = webView.configuration.userContentController
        
        // The javascript being injected into the webView
        let js: String = """
            removeIFrame = () => {
                const frameToRemove = document.getElementById('zg-iframe');
                if (frameToRemove && frameToRemove.parentNode) {
                    frameToRemove.parentNode.removeChild(frameToRemove);
                    document.body.style.overflow = 'inherit';
                }
            }
            openPayment = (token) => {
                if (!token) return;
                const iframe = document.createElement('iframe');
                iframe.src = '\(zageApp)';
                iframe.id = 'zg-iframe';
                iframe.style.position = 'absolute';
                iframe.style.bottom = '0';
                iframe.style.top = '0';
                iframe.style.left = '0';
                iframe.style.right = '0';
                iframe.style.width = '100%';
                iframe.style.height = '100%';

                iframe.style.border = 'none';
                document.body.append(iframe);
                let publicKey = '\(publicKey)'
                messageListener = (event) => {
                    const message = event.data;
                    if (message.start && iframe.contentWindow) {
                        iframe.contentWindow.postMessage({ publicKey, token }, '\(zageApp)');
                    } else if (message.close) {
                        removeIFrame();
                        window.removeEventListener('message', messageListener);
                        if (message.completed) {
                            window.webkit.messageHandlers.paymentCompleted.postMessage(JSON.stringify(message.response || {}));
                        } else {
                            window.webkit.messageHandlers.paymentExited.postMessage("Exited Payment");
                        }
                    }
                }
                window.addEventListener('message', messageListener);
            }
        """
        
        // Add the bridges between the viewController and the iFrame
        contentController.add(self, name: "paymentCompleted")
        contentController.add(self, name: "paymentExited")
        
        let script = WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(script)
    }
    
    public func openPayment(paymentToken: String, onSuccess: @escaping (Any) -> Void, onExit: @escaping () -> Void) -> Void  {
        // If the iframe is still being loaded, do not open the payment as it will throw an error
        if (webView.isLoading) {
            self.dismiss(animated: true, completion: nil)
            return
        }
        self.onSuccess = onSuccess;
        self.onExit = onExit; 

        self.webView.evaluateJavaScript("openPayment('\(paymentToken)')", completionHandler: { (result, err) in
            guard err == nil else {
                print("ERROR: \(err!)")
                return
            }
        })
                   
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch (message.name) {
            case ("paymentCompleted"):
                self.onSuccess(message.body)
                self.dismiss(animated: true, completion: nil)
            case("paymentExited"):
                self.onExit()
                self.dismiss(animated: true, completion: nil)
            default:
                return
        }
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
}

