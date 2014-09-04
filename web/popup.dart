import 'dart:html' as dom;
import 'dart:js' as js;
import 'package:chrome/chrome_ext.dart' as chrome;
import 'dart:convert' as convert;

import 'analytics.dart' as analytics;

class Popup {
  dom.Element message;
  dom.Element status;
  chrome.Port port;
  Popup() {
    message = dom.querySelector('#message');
    status = dom.querySelector('#status');
    //bug in next line, id, null nefunguje
    port = chrome.runtime.connect(chrome.runtime.id, new chrome.RuntimeConnectParams());
  
    port.onMessage.jsProxy.callMethod('addListener', [onMessage]);
  }
  
  sendJob(int id, String url) {
    var message = convert.JSON.encode(
        {"id": id, "url": url}
    );
    //print(message);
    postMessage(message);
  }
  onMessage(message, s) {
    //print('onMessage');
    //var msg = new js.JsObject(message);
    //print('message.thread_: ${message["thread_"]}');
    updateStatus(message);
    updateMessage(message['errorMsg']);
  }
  postMessage(msg) {
    js.JsFunction postMessage = port.postMessage;
    return postMessage.apply([msg], thisArg: port.jsProxy);
  }
  updateStatus(/*Progress*/ p) {
    var msg = 'Threads visited: ${p['thread']}<br>Posts processed: ${p['post']}<br>Ungraded: ${p['markedPost']}';
    //print('status: $msg');
    status.innerHtml = msg;
  }
  updateMessage(String errorMsg) {
    //print('errorMsg: $errorMsg');
    if (errorMsg == null) {
      return;
    } else if (errorMsg == '') {
      message.innerHtml = 'SUCCESS!';
    } else {
      message.innerHtml = errorMsg;
    }
  }
}

pageView() {
  analytics.sendPageview();
}

pageEvent() {
  analytics.sendEvent(action: 'x', category: 'y');
}

main() {
  analytics.initialize();
  //var context = js.context;
  //context['event'] = pageEvent;
  //context['view'] = pageView;
  analytics.setLocation("popup.html");
  dom.window.onLoad.listen((_){
    analytics.sendPageview();
    run();
  });
}

run() {
  var popup = new Popup();
  chrome.tabs.query(new chrome.TabsQueryParams(active: true)).then((tabs){
    //print(tabs);
    //print(tabs.map((t)=>t.url));
    //HACK: no other idea how to get activeTab
    var tab = tabs.where((t) => t.url != null).first;
    if (tab.url == null) {
      var err = 'Cannot get URL';
      analytics.sendEvent(
          category: 'popup'
         ,action: 'processingFailed'
         ,label: convert.JSON.encode(
          {"error": err}
         ));
      popup.updateMessage(err);
      return;
    }
    var url = tab.url;
    var id = tab.id;
    popup.sendJob(id, url);
  });
}