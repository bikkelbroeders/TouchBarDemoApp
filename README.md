# Touch Bar Demo App

<img src="Resources/Screenshot.png" width="100%">

Touch Bar Demo App allows you to use your macOS Touch Bar from an iPad (through USB connection) or on-screen by pressing the Fn-key. It shows the original Apple Touch Bar, which changes dynamically based on the app you're currently using. With this demo app, you can try out the Touch Bar on any Mac that does not have a physical Touch Bar.

Check out [this video](https://www.youtube.com/watch?v=RZLx03OPpUU) to see it in action.

## How to install

1. Make sure you have macOS Sierra 10.12.1 **build 16B2657** installed, which adds support for the Touch Bar to macOS. 

  [You can download it from this link](https://support.apple.com/kb/dl1897).

  :warning: **Just having 10.12.1 is not enough, you need the right build number. 10.12.1 build 16B2555 does not have Touch Bar support, so it WILL NOT WORK!**
  
  You can check which build you have by clicking the version number in About This Mac:
  
  ![how to check macOS build number](http://g.recordit.co/9mz6r6t9rA.gif)

2. [Fetch the ZIP from Releases](https://github.com/bikkelbroeders/TouchBarDemoApp/releases/latest).

  - TouchBarServer.zip to run the Touch Bar on your Mac
  - Source code (zip) to build the iOS app

3. To run the Touch Bar on your Mac, put the app into your Applications folder and open it. Press the Fn-key to toggle the Touch Bar on and off.

4. To build the iOS app, open `TouchBar.xcodeproj`, connect your iOS device and select the TouchBarClient target and your device, like show here:

  <img src="Resources/Xcode.png">

  To get the app installed on your iOS device, it needs to be properly signed. See [these sideloading instructions](https://www.reddit.com/r/sideloaded/wiki/how-to-sideload) to set this up.

## Authors

* Andreas Verhoeven, <ave@aveapps.com>
* Robbert Klarenbeek, <robbertkl@renbeek.nl>

## Credits

* Thanks to [Alex Zielenski](https://twitter.com/#!/alexzielenski) for [StartAtLoginController](https://github.com/alexzielenski/StartAtLoginController), which ties together the ServiceManagement stuff without even a single line of code (gotta love KVO).

* Thanks to [Aleksei Mazelyuk](https://dribbble.com/mazelyuk) for his [Touch bar for VK Messenger](https://dribbble.com/shots/3057522-Touch-bar-for-VK-Messenger), which was an inspiration for the app icon.

* Thanks to [Rasmus Andersson](https://rsms.me/) for [peertalk](https://github.com/rsms/peertalk), which is used to communicate between the macOS and iOS apps through USB connection.

* Thanks to [Bas van der Ploeg](http://basvanderploeg.nl) for testing and shooting a sample video.

## License

Touch Bar Demo App is published under the [MIT License](http://www.opensource.org/licenses/mit-license.php).
