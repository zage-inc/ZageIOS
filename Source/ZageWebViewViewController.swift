//
//  ZageWebViewViewController.swift
//  ZageIOS
//
//  Created by Michael Sun on 10/28/21. TODO: Change this
//

import Foundation
//
//  ZageIOSPkg.swift
//  ZageIOSPkg
//
//  Created by Michael Sun on 10/27/21. TODO: Change this
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
        fetchJavascript(completionHandler: { (result) in
            switch (result) {
            case .success(let response):
                // This line forces the encapsulated code to run on the main thread
                DispatchQueue.main.async {
                    // Inject script
                    let script = WKUserScript(
                        source: String(data: response, encoding: .utf8)!,
                        injectionTime: WKUserScriptInjectionTime.atDocumentStart,
                        forMainFrameOnly: false)
                    contentController.addUserScript(script)
                }
            case .failure(let error):
                print("Error: Payment flow failed with error: \(error)")
                return
            }
        } )
        
        
    
        
        // Add the bridges between the viewController and the iFrame
        contentController.add(self, name: "paymentCompleted")
        contentController.add(self, name: "paymentExited")
        
        
    }
    
    public func openPayment(paymentToken: String, onSuccess: @escaping (Any) -> Void, onExit: @escaping () -> Void) -> Void  {
        // If the iframe is still being loaded, do not open the payment as it will throw an error
        if (webView.isLoading) {
            self.dismiss(animated: true, completion: nil)
            return
        }
        self.onSuccess = onSuccess;
        self.onExit = onExit; 

        self.webView.evaluateJavaScript("openPayment('\(paymentToken)', '\(publicKey)')", completionHandler: { (result, err) in
            guard err == nil else {
                print("ERROR: \(err!)")
                return
            }
        })
                   
    }
    private func fetchJavascript(completionHandler: @escaping (Result<Data, Error>) -> Void) {
        let javascriptEndpoint = "http://localhost:3000/v0-iOS.js";
        let url = URL(string: javascriptEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request, completionHandler: {data, response, error -> Void in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data {
                do {
                    completionHandler(.success(data))
                }
            } else {
                print("ERROR: Invalid data from Zage endpoint")
                return
            }
        }).resume()
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch (message.name) {
            case ("paymentCompleted"):
                // Handle completed payment callback and dismiss the view
                self.onSuccess(message.body)
                self.dismiss(animated: true, completion: nil)
            case("paymentExited"):
                // Handle exited payment callback and dismiss the view
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

