import Foundation

// Zage object that wraps the Zage WebView ViewController
public class Zage {
    // The actual view controller that manages the connection between the Swift webview and the iframe that is injected
    private var vc: ZageWKWebViewController
    
    private var infoViewController: ZageWKInfoModalViewController
    
    // The view controller that the payment flow will sit on top of
    private var context: UIViewController
    
    // Zage object constructor
    public init(context: UIViewController, publicKey: String) {
        self.vc = ZageWKWebViewController(publicKey: publicKey)
        self.infoViewController = ZageWKInfoModalViewController(publicKey: publicKey)
        self.context = context
        
        // Load the view controller to context, but do not start the payment flow
        context.view.addSubview(vc.webView)
        context.view.addSubview(infoViewController.webView)
    }
    
    public func openPayment(paymentToken: String, onComplete: @escaping (Any) -> Void, onExit: @escaping () -> Void) {
        // Present/display the view controller in context
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .overFullScreen
        navController.navigationBar.isHidden = true
        context.present(navController, animated: true, completion: nil)
        // Commence the payment flow
        vc.openPayment(paymentToken: paymentToken, onComplete: onComplete, onExit: onExit)
      }
    
    public func openModal() {
        context.modalPresentationStyle = .formSheet
        context.present(infoViewController, animated: true, completion: nil)
        infoViewController.openModal()
    }
}


