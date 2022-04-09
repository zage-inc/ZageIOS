
# ZageIOS



[![Version](https://img.shields.io/cocoapods/v/ZageIOS.svg?style=flat)](https://cocoapods.org/pods/ZageIOS)

[![License](https://img.shields.io/cocoapods/l/ZageIOS.svg?style=flat)](https://cocoapods.org/pods/ZageIOS)

[![Platform](https://img.shields.io/cocoapods/p/ZageIOS.svg?style=flat)](https://cocoapods.org/pods/ZageIOS)

  

## Example

  

To run the example project:
- Clone the repo
- Run `pod install` from inside the Example directory
- Open `Example/ZageIOS.xcworkspace` in XCode
- Run the App

  

## Requirements
- iOS 9

  

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

#### Intro

The ZageIOS package provides an easy and lightweight way to implement Zage as a payment method into your iOS application. To use it, you must have a public and private key pair from Zage, so please ensure that you have received one. 

#### Setup 
To install the ZageIOS Package, first make sure that you have Cocoapods installed and you are using it in your application. Then, include the ZageIOS pacakge in your application’s Podfile. It should look something like the following:

```
target 'MyApp' do
    use_frameworks!
    pod 'ZageIOS'
end
```

Next, import the Zage package in your checkout screen's view controller:

```swift
import ZageIOS
```

#### Implementation 
In your view controller's init method, instantiate an instance of the Zage object as a class variable with your context and public key:

```swift
class ViewController: UIViewController { 
    var zage: Zage? 
    
    required init?(coder: NSCoder) { 
        super.init(nibName: nil, bundle: nil) 
        zage = Zage(context: self, publicKey: "<PUBLIC_KEY>") 
    } 
}
```

Next, in the handler you'll use to open the Zage payment process, call the openPayment method in the Zage object you created and pass in your payment token, onComplete callback, and onExit callback, along with any other functionality you wish to include. Be aware that the onComplete callback will return a serialized version of the JSON object returned by the web hook you used to create the payment token. 

```swift
@objc private func didTapButton() { 
    zage?.openPayment(paymentToken: "<PAYMENT_TOKEN>", 
        onComplete: {(res: Any) -> Void in 
            // Insert onComplete functionality here 
        }, 
        onExit: {() -> Void in 
            // Insert onExit functionality here 
        } 
    ) 
    // Insert any other functionality you wish to include here 
}
```

And that's it! With just the Zage object and one method, you can integrate Zage into your Swift application. Here is an example with all of the pieces in one place:


#### Additional Features

Zage offers an informational modal to explain what Zage is and how it works to your customers. By simply calling `zage.openModal()`, you can present this modal to your customers. They'll never leave your application

```swift
@objc private func didTapButton() {
  zage?.openModal()
}
```

#### Full Implementation Example

```swift
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
            onComplete: {(res: Any) -> Void in 
                // Insert onComplete functionality here 
            }, 
            onExit: {() -> Void in 
                // Insert onExit functionality here 
            } 
        ) 
        // Insert any other functionality you wish to include here 
    }
}
```
