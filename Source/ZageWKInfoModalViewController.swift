import Foundation
import SafariServices
import UIKit
import WebKit

public class ZageWKInfoModalViewController: UIViewController, WKUIDelegate, SFSafariViewControllerDelegate, WKScriptMessageHandler {
    
    // webView that is being used to display the info modal
    var webView: WKWebView!
    
    private let PROD_INFO_URL = "https://info.zage.dev"
    private let SB_INFO_URL = "https://info.sandbox.zage.dev"

    /// The merchant's public key
    private var publicKey: String
    
    enum ModalEvent: String, CustomStringConvertible {
        case dismissed
        
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
        
        let infoModalUrl = publicKey.starts(with: "sandbox_") ? SB_INFO_URL : PROD_INFO_URL
        guard let webViewUrl = URL(string: infoModalUrl) else {
            self.popupAlert(title: "Error", message: "Unable to retrieve url")
            return
        }
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.load(URLRequest(url: webViewUrl))
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        view = webView
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
                return
            }
        } )
        
        contentController.add(self, name: ModalEvent.dismissed.description)
    }
    
    public func openModal() {
        if (webView.isLoading) {
            self.dismiss(animated: true, completion: nil)
            return
        }
        webView.evaluateJavaScript("openModal('\(publicKey)')",
            completionHandler: { msg, err in
            guard err == nil else {
                print("ERROR: \(err!)")
                self.dismiss(animated: true, completion: nil)
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
        switch ModalEvent(rawValue: message.name) {
        case .dismissed:
            self.dismiss(animated: true, completion: nil)
        default:
            return
        }
    }

    public func webView(_ webView: WKWebView,
                        createWebViewWith configuration: WKWebViewConfiguration,
                        for navigationAction: WKNavigationAction,
                        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url else {
            return nil
        }
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.delegate = self
        self.present(safariViewController, animated: true)
        return nil
    }
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true)
    }
}

