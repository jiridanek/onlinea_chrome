import 'dart:async' as async;
import 'dart:html' as dom;
import 'dart:convert' as convert;
import 'package:chrome/chrome_ext.dart' as chrome;

import 'package:is/discussion.dart' as df;

import 'analytics.dart' as analytics;

class Popup {
  dom.Element message;
  dom.Element status;
  
  Popup() {
    message = dom.querySelector('#message');
    status = dom.querySelector('#status');
  }
  
  updateStatus(/*Progress.progress*/ p) {
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

main() {
  analytics.initialize();
  analytics.setLocation("popup.html");
  dom.window.onLoad.listen((_){
    analytics.sendPageview();
    chrome.runtime.onMessage.listen((chrome.OnMessageEvent e) {
      try {
//        print(e);
        String url = e.message;
        processUrl(url);
      } catch (e) {
        print (e);
        throw('halt');
      }
    });
  });
}

processUrl(url) {
  var popup = new Popup();
  if (url == null) {
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
    
  var progress = new Progress(url);
  df.markAllUngraded(url, progress);
    
  new async.Timer.periodic(new Duration(milliseconds: 120), (_) {
    popup.updateStatus(progress.progress);
    popup.updateMessage(progress.errorMsg);
  });
}