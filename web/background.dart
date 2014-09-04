import 'dart:async' as async;
import 'dart:js' as js;
import 'package:chrome/chrome_ext.dart' as chrome;
import 'dart:convert' as convert;
import 'dart:math' as math;

import 'analytics.dart' as analytics;

final convert_HtmlEscape = new convert.HtmlEscape();

class App {
  Map requests = new Map<int, String>();
  
  App.run() {
    chrome.windows.onRemoved.listen((int id) => requests.remove(id));
    
    chrome.pageAction.onClicked.listen((chrome.Tab tab) {
      var url = tab.url;
      var window;
      if (requests.containsValue(url)) {
        int id;
        requests.forEach((k, v) {
          if (v == url) {
            id = k;
          }
        });
        chrome.windows.update(id, new chrome.WindowsUpdateParams(focused: true));
        //TODO: ? window = chrome.windows.get(id);
      } else {
        int width = 300;
        int left = math.max(10, tab.width - width - 100);
        window = openNewWindow(url, left: left, width: width);
      }
      print("line 34");
      if (window != null) {
        window.then((chrome.Window window) {
          print("got window");
          // send the url to the popup
              new async.Timer(new Duration(seconds: 1), (){
          chrome.tabs.sendMessage(window.tabs.first.id, url);
              });
        });
      }
    });
    
  }
  
  async.Future<chrome.Window> openNewWindow(String url, {int left, int width}) {
    var completer = new async.Completer();
    //https://stackoverflow.com/questions/5186296/chrome-extension-open-new-popup-window
    chrome.windows.create(
        new chrome.WindowsCreateParams(url: 'popup.html', type: 'popup',
            top: 20, left: left, width: width, height: 200, focused: true)
    ).then((chrome.Window window) {
        requests[window.id] = url;
        completer.complete(window);
    });
    return completer.future;
  }
}

main() {
  analytics.initialize();
  analytics.setLocation('background.html');
  
  chrome.runtime.onInstalled.listen((_) {
    js.context['myJsHelpers'].callMethod('installContentRules', []);
    analytics.sendEvent(category: 'extension', action: 'installed');
  });
  
  analytics.sendPageview(nonInteraction: true);
  
  new App.run();
}