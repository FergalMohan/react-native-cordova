# React Native Plugin for Cordova (REMobile + Dual Bridge)
Initiallly a RN plugin with defines/parameter handling for calling cordova plugin methods from a react native App on ios and android. Initially 10 files to allow native code in Cordova Plugins to be callable from the RN Bridge. 
Used a couple of Macros:
RCT_EXPORT_MODULE(pluginName)
RCT_EXPORT_CORDOVA_METHOD(methodName)
so that the plugin code would be accessible from React.
Supplemented and fleshed out accordingly with a secondary JS<->Native Bridge so that the minimalist CDVPlugin would also be accessible via the original cordova.exec(pluginName, methodName, passHandler, failHandler) method.
This involved taking the CDVCommandDelegateImpl from the existing Cordova App and adding it to REMobile codebase (along with some support files e.g. CDVCommandQueue and reinstated functionality of CDVInvokedUrlCommand from the slimmed down version).
Additional functionality to allow config parsing, plugin management, logging and debug was reintroduced with most of the files lifted with minimal changes from the current Cordova iOS App.
Changes were also required becase the UXP Server's HTML contents now need to be rendered in a React Native Web View, so all the functionality in the CDVWebViewEngine had to be migrated to BoiCustomWebView or CDVAwareViewController, which now manages the Cordova plugins. 
In tandem with Cordova dependencies in MainViewController (subclassed from CDVViewController) and Cordova's AppDelegate were divided up appropriately between the new RCTAppDelgate subclass and CDVAwareViewController.
The REMobile codebase file count increased to 37 from 10. 

## Installation
```sh
npm install @remobile/react-native-cordova --save
```
### Installation (iOS)
* Drag RCTCordova.xcodeproj to your project on Xcode.
* Click on your main project file (the one that represents the .xcodeproj) select Build Phases and drag libRCTCordova.a from the Products folder inside the RCTCordova.xcodeproj.
* Look for Header Search Paths and make sure it contains $(SRCROOT)/../../../react-native/React as recursive.

* In your project, Look for Header Search Paths and make sure it contains $(SRCROOT)/../../react-native-cordova/ios/RCTCordova.
* then you can #import "CDVPlugin.h"

### Installation (Android)
* In Main project `build.gradle`
```gradle
...
include ':react-native-cordova'
project(':react-native-cordova').projectDir = new File(settingsDir, '../node_modules/@remobile/react-native-cordova/android/RCTCordova')
```

* In you project `build.gradle`

```gradle
...
dependencies {
    ...
    compile project(':react-native-cordova')
}
```

* then you can import com.remobile.cordova.* ;


## Usage
### IOS
```java
#import "CDVPlugin.h"
...
@interface CustomClass : CDVPlugin
@end
...

@implementation CustomClass
RCT_EXPORT_MODULE(RCTCustomClass)
RCT_EXPORT_CORDOVA_METHOD(test);
...
- (void) test:(CDVInvokedUrlCommand *)command {
...
}
....
@end
```
### Android
```java
import com.remobile.cordova.*;
...
public class CustomClass extends CordovaPlugin {
...
    public CustomClass(ReactApplicationContext reactContext) {
            super(reactContext);
        }
...
    @Override
    public String getName() {
        return "Sqlite";
    }
    @ReactMethod
    public void test(ReadableArray args, Callback success, Callback error) {
        executeReactMethod("test", args, success, error);
    }
    ...
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("test")) {
            ....
            return true;
        }
        ....
        return false;
    }
}
```


# Project List
* [react-native-camera](https://github.com/remobile/react-native-camera)
* [react-native-contacts](https://github.com/remobile/react-native-contacts)
* [react-native-dialogs](https://github.com/remobile/react-native-dialogs)
* [react-native-file-transfer](https://github.com/remobile/react-native-file-transfer)
* [react-native-image-picker](https://github.com/remobile/react-native-image-picker)
* [react-native-sqlite](https://github.com/remobile/react-native-sqlite)
* [react-native-file](https://github.com/remobile/react-native-file)
* [react-native-zip](https://github.com/remobile/react-native-zip)
* [react-native-capture](https://github.com/remobile/react-native-capture)
* [react-native-capture](https://github.com/remobile/react-native-capture)
* [react-native-local-notifications](https://github.com/remobile/react-native-local-notifications)
