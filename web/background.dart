import 'dart:async' as async;
import 'dart:js' as js;
import 'package:chrome/chrome_ext.dart' as chrome;
import 'online_a_discussion_points.dart' as df;
import 'dart:convert' as convert;

import 'analytics.dart' as analytics;

final convert_HtmlEscape = new convert.HtmlEscape();

class Progress {
  String _url;
  num _thread = 0;
  num _post = 0;
  num _markedPost = 0;
  String _errorMsg;
  get thread_ => _thread;
  get post_ => _post;
  get markedPost_ => _markedPost;
  get errorMsg => _errorMsg;
  thread() => _thread++;
  post() => _post++;
  markedPost() => _markedPost++;
  failed(msg) {
    _errorMsg = msg;
    analytics.sendEvent(
       category: 'background'
      ,action: 'processingFailed'
      ,label: convert.JSON.encode(
        {"page": _url, "error": _errorMsg}
       )
    );
  }
  succeeded() {
    _errorMsg = '';
    analytics.sendEvent(
              category: 'background'
            , action: 'processingSuccesfull'
            , label: convert.JSON.encode({"page": _url})
            );
  }
  get progress {
    return {'thread': thread_
      , 'post': post_
      , 'markedPost': markedPost_
      , 'errorMsg': _errorMsg};
  }
  Progress(this._url);
}

class Test {
  String a;
}

class Request { 
  chrome.Port port;
  async.Timer timer;
  String url;
  String id;
  var progress;
  Request(this.id, this.url) {
    
  }
  
  
}

class App {
  Map requests = new Map<String, dynamic>();
  chrome.Port lastPort;
  async.Timer lastTimer;
  onMessage(message, s) {
    try { // otherwise chrome.dart eats exceptions
    //print('message: $message');
    //print('message.runtimeType: ${message.runtimeType}');
    //print('s: $s');
    //print('s.runtimeType: ${s.runtimeType}');
    Map messageMap = convert.JSON.decode(message);
    var id = messageMap['id'];
    var url = messageMap['url'];
    
    var progress = requestProcessing(id, url);
    cancelLastTimer();
    lastTimer = new async.Timer.periodic(new Duration(milliseconds: 120), (_) {
      postMessage(new js.JsObject.jsify(progress.progress));
      if (progress.errorMsg != null) {
        lastTimer.cancel();
        if (lastPort != null) {
          disconnect();
          lastPort = null;
        }
      }
    
    });
    } catch(e) {
            print(e);
            throw('halt');
            }
  }
  cancelLastTimer() {
    if (lastTimer != null && lastTimer.isActive) {
          lastTimer.cancel();
        }
  }
  disconnect() {
    cancelLastTimer();
    lastPort.disconnect.apply([], thisArg: lastPort.jsProxy);
  }
  onDisconnect(s) {
    cancelLastTimer();
    lastPort = null;
  }
  postMessage(msg) {
    if (lastPort == null) {
      return null;
    }
    js.JsFunction postMessage = lastPort.postMessage;
    return postMessage.apply([msg], thisArg: lastPort.jsProxy);
  }
  requestProcessing(num id, String url) {
    if(requests.containsKey(url)) {
      if(requests[url].errorMsg != null) {
        var progress = requests[url];
        requests.remove(url);
        return progress;
      }
      reportResuming(url);
    } else {
      reportProcessing(url);
      requests[url] = startProcessing(url);
    }
    return requests[url];
  }
  reportProcessing(url) {
    analytics.sendEvent(
      category: 'background'
    , action: 'process'
    , label: convert.JSON.encode({"page": url})
    );
  }
  reportResuming(url) {
      analytics.sendEvent(
        category: 'background'
      , action: 'resume'
      , label: convert.JSON.encode({"page": url})
      );
    }
  startProcessing(url) {
    var progress = new Progress(url);
    df.markAllUngraded(url, progress);
    return progress;
  }
  sendProgress(url) {
    
  }
  cancelProcessing() {
    
  }
  
  initialize() {
    chrome.runtime.onConnect.listen((p) {
      //print('p: $p');
      //print('p.runtimeType: ${p.runtimeType}');
      //print('p.sender: ${p.sender}');
      lastPort = p;
      p.onMessage.jsProxy.callMethod('addListener', [onMessage]);
      p.onDisconnect.jsProxy.callMethod('addListener', [onDisconnect]);
    });
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
  
  var app = new App();
  app.initialize();
}