import Foundation
import WebKit
import UIKit

public class ZageWebViewViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    // The actual webView that is being used to display the Apollo iframe 
    var webView: WKWebView!

    private let PROD_APP_URL = "https://production.zage.dev/checkout";
    private let SB_APP_URL = "https://sandbox.zage.dev/checkout";
    
    // On success call back for when the payment flow successfully completion
    private var onComplete: ((Any) -> Void)!
    // On exit call back for when the payment flow is exited before completion
    private var onExit: (() -> Void)!
    // The merchant's public key
    private var publicKey: String
    
    init(publicKey: String) {
        self.publicKey = publicKey
        super.init(nibName: nil, bundle: nil)

        let webConfiguration = WKWebViewConfiguration()
        
        let zageApp = publicKey.starts(with: "sandbox_") ? SB_APP_URL : PROD_APP_URL;
        
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.load(URLRequest(url: URL(string: zageApp)!))
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        view = webView
        
        modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        let contentController = webView.configuration.userContentController
        
        // Fetch injected javascript from Zage backend
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
                print("Error: Fetching javascript failed with error: \(error)")
                self.dismiss(animated: true, completion: nil)
                self.onExit()
                return
            }
        } )
        
        // Add the bridges between the viewController and the iFrame
        contentController.add(self, name: "paymentCompleted")
        contentController.add(self, name: "paymentExited")
    }
    
    public func openPayment(paymentToken: String, onComplete: @escaping (Any) -> Void, onExit: @escaping () -> Void) -> Void  {
        // If the iframe is still being loaded, do not open the payment as it will throw an error
        if (webView.isLoading) {
            self.dismiss(animated: true, completion: nil)
            return
        }
        self.onComplete = onComplete;
        self.onExit = onExit; 

        self.webView.evaluateJavaScript("openPayment('\(paymentToken)', '\(publicKey)')", completionHandler: { (result, err) in
            guard err == nil else {
                print("ERROR: \(err!)")
                self.dismiss(animated: true, completion: nil)
                self.onExit()
                return
            }
        })
    }
    
    
    private func fetchJavascript(completionHandler: @escaping (Result<Data, Error>) -> Void) {
        let javascriptEndpoint = "https://qt88c29c0e.execute-api.us-west-1.amazonaws.com/live-test/v0-ios.js";
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
                self.dismiss(animated: true, completion: nil)
                self.onExit()
                return
            }
        }).resume()
    }
    
    // This method acts as the bridge between the javscript in the iFrame and the native Swift code
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch (message.name) {
            case ("paymentCompleted"):
                // Handle completed payment callback and dismiss the view
                self.onComplete(message.body)
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

