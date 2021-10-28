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

    var webView: WKWebView!

    private let zageApp = "https://web.zage.dev"
    private let validationEndpoint = "https://api.zage.dev/v0/fabric/validate"
    
    private var onComplete: ((Any) -> Void)!
    private var onExit: (() -> Void)!
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

                messageListener = (event) => {
                    const message = event.data;
                    if (message.start && iframe.contentWindow) {
                        iframe.contentWindow.postMessage({ token }, '\(zageApp)');
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
        
        contentController.add(self, name: "paymentCompleted")
        contentController.add(self, name: "paymentExited")
        
        let script = WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)
    }
    
    public func openPayment(token: String, onComplete: @escaping (Any) -> Void, onExit: @escaping () -> Void) -> Void  {
        if (webView.isLoading) {
            self.dismiss(animated: true, completion: nil)
            return
        }
        self.onComplete = onComplete;
        self.onExit = onExit; 
        fetchFabricResponse(key: self.publicKey, completionHandler: { (result) in
            switch(result) {
                case .success(let response):
                    if (response.continuePaymentFlow) {
                        DispatchQueue.main.async {
                            self.webView.evaluateJavaScript("openPayment('\(token)')", completionHandler: { (result, err) in
                                guard err == nil else {
                                    print("ERROR: \(err!)")
                                    return
                                }
                            })
                        }
                    } else {
                        print("ERROR: Invalid payment flow")
                        return
                    }
                    
                case .failure(let error):
                    print("ERROR: \(error)")
            }
        })
    }
    
    struct FabricValidationRes: Codable {
        var continuePaymentFlow: Bool
        var message: String
        var statusType: String
    }
    
    private func fetchFabricResponse(key: String, completionHandler: @escaping (Result<FabricValidationRes, Error>) -> Void) {
        let params = [ "publicKey" : key ]
        let url = URL(string: validationEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request, completionHandler: {data, response, error -> Void in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data {
                do {
                    let result = try JSONDecoder().decode(FabricValidationRes.self, from: data)
                    completionHandler(.success(result))
                } catch {
                    completionHandler(.failure(error))
                }
            } else {
                print("ERROR: Invalid data from Zage endpoint")
                return
            }
            
        } )
        task.resume()
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch (message.name) {
            case ("paymentCompleted"):
                self.onComplete(message.body)
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

