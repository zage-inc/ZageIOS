
# ZageIOS



[![Version](https://img.shields.io/cocoapods/v/ZageIOS.svg?style=flat)](https://cocoapods.org/pods/ZageIOS)

[![License](https://img.shields.io/cocoapods/l/ZageIOS.svg?style=flat)](https://cocoapods.org/pods/ZageIOS)

[![Platform](https://img.shields.io/cocoapods/p/ZageIOS.svg?style=flat)](https://cocoapods.org/pods/ZageIOS)

  

## Example

  

To run the example project, clone the repo, and run `pod install` from the Example directory first.

  

## Requirements


  

## Installation

  

ZageIOS is available through [CocoaPods](https://cocoapods.org). To install

it, simply add the following line to your Podfile:

  

```ruby

pod 'ZageIOS'

```

  

## Author

  
Zage Inc

  

## License

  

ZageIOS is available under the MIT license. See the LICENSE file for more info.


## Integration

#### Setup 
To install the Zage Swift package, make sure you have cocoa pods installed and type in the following command into your application's directory:

`pod install Zage`

Next, import the Zage package in your checkout screen's view controller:

`import Zage`

#### Implementation 
In your view controller's init method, instantiate an instance of the Zage object as a class variable with your context and public key:

```
class ViewController: UIViewController { 
    var zage: Zage? 
    
    required init?(coder: NSCoder) { 
        super.init(nibName: nil, bundle: nil) 
        zage = Zage(context: self, publicKey: "<PUBLIC_KEY>") 
    } 
}
```

Next, in the handler you'll use to open the Zage payment process, call the openPayment method in the Zage object you created and pass in your payment token, onSuccess callback, and onExit callback, along with any other functionality you wish to include. Be aware that the onSuccess function will return a serialized version of the JSON object returned by the web hook you used to create the payment token.

```
@objc private func didTapButton() { 
    zage?.openPayment(paymentToken: "<PAYMENT_TOKEN>", 
        onSuccess: {(res: Any) -> Void in 
            // Insert onSuccess functionality here 
        }, 
        onExit: {() -> Void in 
            // Insert onExit functionality here 
        } 
    ) 
    // Insert any other functionality you wish to include here 
}
```

And that's it! With just the Zage object and one method, you can integrate Zage into your Swift application. Here is an example with all of the pieces in one place:

#### Full Implementation Example

```
import UIKit 
import Zage // Import ZageIOS package 

class ViewController: UIViewController { 
    var zage: Zage? required init?(coder: NSCoder) { 
        super.init(nibName: nil, bundle: nil) 
        
        // Instantiate Zage object with context and publicKey 
        zage = Zage(context: self, publicKey: "<PUBLIC_KEY>") 
    } 

    override func viewDidLoad() { 
        super.viewDidLoad() 
        // Example "Pay with Zage" Button 
        let button = UIButton() button.setTitle("Pay with Zage", for: .normal) 
        button.backgroundColor = .systemGreen 
        button.setTitleColor(.black, for: .normal) 
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside) 
        button.frame = CGRect(x: 0, y: 200, 
            width: self.view.frame.width * 0.5, 
            height: self.view.frame.height * 0.1) 
        // Add button to view 
        view.addSubview(button) 
    } 
    
    @objc private func didTapButton() { 
    zage?.openPayment(paymentToken: "<PAYMENT_TOKEN>", 
            onSuccess: {(res: Any) -> Void in 
                // Insert onSuccess functionality here 
            }, 
            onExit: {() -> Void in 
                // Insert onExit functionality here 
            } 
        ) 
        // Insert any other functionality you wish to include here 
    }
}
```
