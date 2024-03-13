# WEContentExtension


## Installation

WEContentExtension is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following below :

## Notification Content Extension Setup
### Create Notification Content Extension
#### Step 1:
In Xcode, navigate to `File` > `New` > `Target` and select `Notification Content Extension`.

#### Step 2:
Click Next, fill out the Product Name as `NotificationViewController`, and click Finish.

#### Step 3:
Click Activate on the prompt shown to activate the content extension. Xcode will now create a new top-level folder in your project with the name `NotificationViewController`.

### Add WebEngage Extensions to the respective Targets
Navigate to `Project` > `Package Dependencies` and click on the Add `(+)` button.

Steps to add WebEngage Content Service
#### Step 1:
Search for https://github.com/WebEngage/WEContentExtension.git in the search bar.
#### Step 2:
Under `Add to Target` select  `NotificationViewController` (Your Content Extension Target).
#### Step 3:
Click `Add Package`.


## License

WEContentExtension is available under the MIT license. See the LICENSE file for more info.
