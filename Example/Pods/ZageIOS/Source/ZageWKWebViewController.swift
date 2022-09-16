import Foundation
import WebKit
import UIKit

public class ZageWKWebViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    // The actual webView that is being used to display the Apollo iframe 
    var webView: WKWebView!

    private let PROD_APP_URL = "https://production.zage.dev/checkout"
    private let SB_APP_URL = "https://sandbox.zage.dev/checkout"
    
    /// fOn success completion block for when the payment flow successfully completed
    private var onComplete: ((Any) -> Void)!
    /// On exit completion block for when the payment flow is exited before payment is processed
    private var onExit: (() -> Void)!
    /// The merchant's public key
    private var publicKey: String
    
    enum PaymentStatus: String, CustomStringConvertible {
        case paymentCompleted
        case paymentExited
        
        var description: String {
            rawValue
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    init(publicKey: String) {
        self.publicKey = publicKey
        super.init(nibName: nil, bundle: nil)

        let webConfiguration = WKWebViewConfiguration()
        
        let zageApp = publicKey.starts(with: "sandbox_") ? SB_APP_URL : PROD_APP_URL
        guard let url = URL(string: zageApp) else {
            self.popupAlert(title: "Error", message: "Unable to retrieve url")
            return
        }
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.load(URLRequest(url: url))
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        
        view = webView
        
        modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        let contentController = webView.configuration.userContentController
        
        // Fetch injected javascript from Zage backend
        fetchJavascript(completionHandler: { result in
            switch result {
            case .success(let response):
                // This line forces the encapsulated code to run on the main thread
                DispatchQueue.main.async {
                    // Inject script
                    let script = WKUserScript(source: String(data: response, encoding: .utf8)!,
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
        contentController.add(self, name: PaymentStatus.paymentCompleted.description)
        contentController.add(self, name: PaymentStatus.paymentExited.description)
    }

    
    public func openPayment(paymentToken: String, onComplete: @escaping (Any) -> Void, onExit: @escaping () -> Void) {
        // If the iframe is still being loaded, do not open the payment as it will throw an error
        if (webView.isLoading) {
            self.dismiss(animated: true, completion: nil)
            return
        }
        self.onComplete = onComplete
        self.onExit = onExit

        self.webView.evaluateJavaScript("openPayment('\(paymentToken)', '\(publicKey)')", completionHandler: { _, err in
            guard err == nil else {
                print("ERROR: \(err!)")
                self.dismiss(animated: true, completion: nil)
                self.onExit()
                return
            }
        })
    }
    
    
    private func fetchJavascript(completionHandler: @escaping (Result<Data, Error>) -> Void) {
        let javascriptEndpoint = "https://api.zage.dev/v0/v0-ios.js"
        guard let url = URL(string: javascriptEndpoint) else {
            self.popupAlert(title: "Error", message: "Unable to retrieve javascript url")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request, completionHandler: { data, _, error in
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
    
    func popupAlert(title: String, message: String) {
        let alert = UIAlertController(title: NSLocalizedString(title, comment: ""), message: NSLocalizedString(message, comment: ""), preferredStyle: .alert)
        let OKAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
        alert.addAction(OKAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // This method acts as the bridge between the javscript in the iFrame and the native Swift code
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch PaymentStatus(rawValue: message.name) {
        case .paymentCompleted:
            // Handle completed payment callback and dismiss the view
            self.onComplete(message.body)
            self.dismiss(animated: true, completion: nil)
        case .paymentExited:
            // Handle exited payment callback and dismiss the view
            self.onExit()
            self.dismiss(animated: true, completion: nil)
        default:
            return
        }
    }
}

