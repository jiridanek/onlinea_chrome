
/*
 * statistika
 * kumulativní graf získaných bodů na čase pro studenta
 * příspěvky v diskusi a ohodnocení příspěvků
 * shluknout průběhy
 */

import 'dart:html' as dom;
import 'dart:core';
import 'dart:async' as async;
import 'dart:js' as js;
import 'dart:math' as math;

xpathSelectorAllTest() {
  var query = '//p';
  var element = new dom.Element.html('<div><p>pes</p><p>les</p></div>');
  var ps = xpathSelectorAll(query, element);
  print(ps.length);
}
void main() {
  dom.querySelector("#text_id").onClick.listen(run);
  run(null);
  //evaluate('count(//p)', '<p>df</p>');
  //xpathSelectorAllTest();
}

const idPrefixPost = 'pr_ce_';
const allPostsXpath = "//*[starts-with(@id, '${idPrefixPost}')]";
const newPostClass = 'df_pr_nect';

var gradeClass = 'hodn_pri';

var baseUrl = 'https://is.muni.cz';

class ThreadPage {
  static const paginationDivQuery = '//*[@id="aplikace"]//div[@class="strankovani"]';
  
  dom.Element element;
  
  ThreadPage(this.element);
  static fromHtml(html) {
    return new ThreadPage(elementFromHtml(html));
  }
  
  List<Post> get posts {
    var re = new RegExp('^${idPrefixPost}[0-9]*\$');
    // pr_ce_$id and also pr_ce_ajax_$id (the favorite stars)
    var elements = xpathSelectorAll(allPostsXpath, element).where((e) => re.hasMatch(e.id));
      //print(elements.length);
      //print(elements.first);
      //print(elements.first.innerHtml);
      //throw('halt');
    var posts = elements.map((e) => new Post(e));
    return posts;
  }
  
  String next() {
    dom.Element paginationDiv = xpathSelector(paginationDivQuery, element);
    if (paginationDiv == null) {
      return '';
    }
    var last = paginationDiv.lastChild;
    //print(last.nodeName);
    //throw('halt');
    //adfasdfasd(paginationDiv.innerHtml);
    if(last is dom.AnchorElement && last.nodeName == 'A') {
      var url = last.attributes['href'];
      //print(url);
      //throw('halt');
      return baseUrl + url;
    }
    return '';
  }
}

class ForumPage {
  var paginationXpath = '//*[@id="aplikace"]/form/div[3]';
  static fromHtml(String html) {
    return new ForumPage(elementFromHtml(html));
  }
  dom.Element element;
  ForumPage(this.element);
  List<Thread> get threads {
    var query = xpathSelectorAll(allPostsXpath, element);
    //print(element.innerHtml);
    //print(query);
    //throw('halt');
    var threads = query.map((e) {
      var url = e.querySelector('h4 a').attributes['href'];
      return new Thread.fromUrl(baseUrl + url);
    });
    //print(threads.first.url);
    //throw('halt');
    return threads;
  }
  String next() {
    var pagination = xpathSelector(paginationXpath, element);
    if (pagination == null) {
      return '';
    }
    dom.Element last = pagination.lastChild;
    if (last is dom.AnchorElement && last.nodeName == 'A') {
      var link = baseUrl + last.attributes['href'];
      return link;
    }
    return '';
  }
}

class Post {
  dom.Element element;
  Post(this.element);
  num id() {
   //print(element);
   //print(element.innerHtml);
   //print(element.id);
    return num.parse(element.id.substring(idPrefixPost.length));
  }
  DateTime submitted() {
    
  }
  /// @returns null if never
  DateTime editted() {
    
  }
  async.Future<DateTime> graded() {
    
  }
  bool unread() {
    return element.classes.contains(newPostClass);
  }
  bool notGraded() {
    var gradeArea = element.querySelector('.${gradeClass}');
    if (gradeArea == null) {
      // - author is not a student in the course
      // - forum has grading disabled
      // - ...?
      return false;
    }
    //print(element.innerHtml);
    //print(gradeArea);
    return gradeArea.text.contains(StringsCs.hodnotitDoPoznamkovehoBloku);
  }
  markUnread() {
    ///auth/diskuse/diskuse_ajax.pl?fakulta=1433;obdobi=5984;predmet=721682;ts_0=20140326213043:46976735;guz=46976737;akce=vrat_neprec;cop=', 'vr_ne_46976737'
    return get('https://is.muni.cz/auth/diskuse/diskuse_ajax.pl?guz=${id()};akce=vrat_neprec', shouldNotDelay: true);
  }
  num points() {
    
  }
}

class StringsCs {
  static final hodnotitDoPoznamkovehoBloku = "Hodnotit do poznámkového bloku";
  final zmenitHodnoceni = "změnit hodnocení";
  final obsahBlokuNaposledyZmenen = "obsah bloku naposledy změněn: ";
  //Mgr. Radek Vogel, Ph.D., 20. 3. 2014 23:06
  //[a-zA-Z., ]*, [0-9]\. [0-9]\. [0-9]* [0-9]:[0-9]
}

evaluate(String query, html) {
  var element;
  if (html is String) {
    element = elementFromHtml(html);
  } else if (html is dom.Element){
    element = html;
  } else {
    throw 'error';
  }
  
  var context = js.context;
  var result = js.context.callMethod('evaluate', [query, element]);
  return result;
}

var jsPrefix = 'xpath';

List<dom.Element> xpathSelectorAll(query, element) {
  var context = js.context;
  var result = js.context[jsPrefix].callMethod('xpathSelectorAll', [query, element]);
  return result;
}

dom.Element xpathSelector(query, element) {
  var list = xpathSelectorAll(query, element);
  if(list.isNotEmpty) {
    return list.first;
  }
  return null;
}

// avoids the implicit sanitization? do I really want that?
// Uncaught Error: Bad state: More than one element
class NullHtmlValidator implements dom.NodeValidator {
  const NullHtmlValidator();
  @override
  bool allowsAttribute(dom.Element element, String attributeName, String value)
    => true;

  @override
  bool allowsElement(dom.Element element)
    => true;
}
final nullHtmlValidator = const NullHtmlValidator();
//final silentHtmlValidator = new dom.NodeValidatorBuilder.common().;
dom.Element elementFromHtml(String html) {
  //print(html);
  //dom.document.createExpression();
  return new dom.DivElement()..setInnerHtml(html, validator: nullHtmlValidator);
  //return new dom.Element.html(html);
  //return new dom.DocumentFragment.html(html, validator: nullHtmlValidator);
}

void run(dom.MouseEvent event) {
  var aDiscussionThreadUrl = 'https://is.muni.cz/auth/cd/1441/jaro2006/ONLINE_A/1237758';
  //var aDiscussionForumUrl = 'https://is.muni.cz/auth/diskuse/diskusni_forum_predmet.pl?guz=1041062';
  var aDiscussionForumUrl = 'https://is.muni.cz/auth/diskuse/diskusni_forum_indiv.pl?guz=46987554';
  //_run(aDiscussionThreadUrl, processThreadTest);
  //_run(aDiscussionForumUrl, processForumTest);
  _run(aDiscussionForumUrl, markAllUngradedTest);
  //_run(aDiscussionForumUrl, readAllInForum);
  //_run(aDiscussionThreadUrl, readAllInThread);
}

void _run(url, func) {
  LogInPage.logIn(USERNAME, PASSWORD)
    .then((r) => get(url))
    .then((r) {
      func(r);
    }
  );
}

markAllUngraded(String url, progress) {
  get(url).then((html) {
    var forum = new Forum(ForumPage.fromHtml(html));
    
    //throw('halt');
    var posts = new async.StreamController();
    
    var t = 0;
    var t_done = false;
    
    forum.streamThreads().forEach((Thread thread) {
      t++;
      progress.thread();
      thread.streamPosts().forEach(posts.add)
        .catchError(()=>progress.failed("Some posts were not processed"))
        .whenComplete(() {
          t--;
          if (t_done && t == 0) {
            posts.close();
          }
      }).whenComplete(()=>t_done = true);
    }).catchError(() {
      progress.failed("Some discussion threads were not processed");
    });
    
    posts.stream.forEach((post) {
      progress.post();
      if (post.notGraded() /*|| post.unread()*/) {
        progress.markedPost();
        post.markUnread(); //can fail as well
      }
    }).catchError((){
      progress.failed("Some posts were not processed");
    }).whenComplete(()=>progress.succeeded());
  });
}

markAllUngradedTest(String html) {
  var forum = new Forum(ForumPage.fromHtml(html));
  //throw('halt');
  forum.streamThreads().forEach((Thread thread) {
      thread.streamPosts()
        .where((post)=>post.notGraded())
        .forEach((post)=>post.markUnread());
  });
}

markAllTest(String html) {
  var forum = new Forum(ForumPage.fromHtml(html));
  forum.streamThreads().toList().then((threads) {
    print(threads);
  });
  
  forum.streamThreads().forEach((Thread thread) {
    thread.streamPosts()
      .forEach((e)=>null);
      //.forEach((post)=> post.markUnread());
  });
}

readAllInForum(String html) {
  var forum = new Forum(ForumPage.fromHtml(html));
  forum.streamPages()
    .forEach((p)=>p.threads.forEach((t)=>t.streamPosts().drain()));
}

readAllInThread(String html) {
  var thread = new Thread(new ThreadPage(elementFromHtml(html)));
  thread.streamPosts().forEach((e)=>null);
        //.forEach((post)=> post.markUnread());
}

processForumTest(String html) {
  var forum = new Forum(ForumPage.fromHtml(html));
  forum.streamPages().toList().then((pages) {
    print('got ${pages.length} pages');
  });
}

abstract class PageStreamer<T> {
  T firstPage;
  ForumPage pageFromHtml(String html);
  async.Stream<T> streamPages() {
    var _pages = new async.StreamController<T>();
    var pages = new async.StreamController<T>();
    _pages.stream.listen((page) {
      String link = page.next();
      if(link != '') {
        get(link).then((String html) {
            var page = pageFromHtml(html);
            _pages.add(page);
            pages.add(page);
        });
      } else {
        _pages.close();
        pages.close();
      }
    });
    
    _pages.add(firstPage);
    pages.add(firstPage);
    return pages.stream;
  }
}

class Thread {
  ThreadPage _firstPage;
  String url;
  
  Thread(this._firstPage);
  Thread.fromUrl(this.url);
  
  async.Future<ThreadPage> get firstPage {
    var completer = new async.Completer();
    if(_firstPage == null) {
      get(url).then((html) {
        //print(url);
        //throw('halt');
        _firstPage = ThreadPage.fromHtml(html);
        completer.complete(_firstPage);
      });
    } else {
      completer.complete(_firstPage);
    }
    return completer.future;
  }
  
  async.Stream<ThreadPage> streamThreadPages() {
    var _threadPages = new async.StreamController<ThreadPage>();
    var threadPages = new async.StreamController<ThreadPage>();
    _threadPages.stream.listen((page) {
      String link = page.next();
      //print(link);
      //safdasd(link);
      if(link != '') {
        get(link).then((String html) {
            var page = new ThreadPage(elementFromHtml(html));
            _threadPages.add(page);
            threadPages.add(page);
        });
      } else {
        _threadPages.close();
        threadPages.close();
      }
    });
    
    firstPage.then((p) {
      //print(p);
      //throw('halt');
      _threadPages.add(p);
      threadPages.add(p);
    });

    return threadPages.stream;
  }
  async.Stream<Post> streamPosts() {
    var posts = new async.StreamController<Post>();
    streamThreadPages().listen((ThreadPage tp) {
      for (var p in tp.posts) {
        posts.add(p);
      }
    }, onDone:(()=>posts.close()));
    return posts.stream;
  }
}

/// may (if multiple pages probably always will) give some duplicates
async.Stream<Post> streamAllPosts(String firstPageHtml) {
  var firstPage = new ThreadPage(elementFromHtml(firstPageHtml));
  var thread = new Thread(firstPage);
  return thread.streamPosts();
}

processThreadTest(String firstPage) {
  var posts = streamAllPosts(firstPage);
  posts.toList().then((l) {
    print('Have ${l.length} posts');
    var notGraded = l.where((p)=>p.notGraded());
    print('There is ${notGraded.length} ungraded posts');
  });
//        var threadPage = new ThreadPage(elementFromHtml(firstPage));
//        var html;
//        var link;
//        threadPages.add(threadPage);
        
        
        
//        while () {
          
//          html = get(link);
          
//          threadPages.add(threadPage);
//        }
//        print('#pages: ${threadPages.length}');
//        var posts = threadPages.first.posts;
//        print('posts: ${posts.map((Post p) => p.id())}');
//      posts.forEach((Post p) {
//        p.markUnread();
//      });
}

async.Future<String> get(String url, {bool shouldNotDelay: false}) {
  //skip that
  return _get(url, shouldNotDelay);
  // does ad-hoc caching in chrome.storage for faster testing
//  var completer = new async.Completer();
//  var found = false;
//  chrome.storage.local.get([url]).then((map) {
//    if (map.containsKey(url)) {
//      completer.complete(map[url]);
//    } else {
//      _get(url).then((v) {
//        chrome.storage.local.set({url: v});
//        completer.complete(v);
//      });
//    }
//  });
//  return completer.future;
}

var random = new math.Random();

async.Future<String> _get(String url, bool shouldNotDelay) {
  int maxDelay = 6;
  var completer = new async.Completer();
  var ajax = () {
    dom.HttpRequest.request(url).then((dom.HttpRequest r) {
        completer.complete(r.responseText);
      }, onError: (e) {
        dom.HttpRequest r = e.target;
        completer.complete(r);
      });
  };
  
  
  if(shouldNotDelay) {
    ajax();
  } else {
    new async.Timer(new Duration(milliseconds: 500, seconds: random.nextInt(maxDelay)), () {
      ajax();
    });
  }
  return completer.future;
}

class Forum extends PageStreamer<ForumPage> { //mixin
  ForumPage firstPage;
  Forum(this.firstPage);
  @override
  ForumPage pageFromHtml(String html) {
    return ForumPage.fromHtml(html);
  }
  async.Stream<Thread> streamThreads() {
    var threads = new async.StreamController();
    streamPages().listen((page) {
      for(var t in page.threads) {
        threads.add(t);
        //print('adding thread');
        //throw('halt');
      }
    }, onDone: ()=>threads.close());
    return threads.stream;
  }
}

//TODO: failed login
//logout
class LogInPage {
  static const url = 'https://is.muni.cz/system/login_form.pl';
  static const expiration = '345600'; //1 hodině    8 hodinách    1 dni    4 dnech
    
  static async.Future<String> logIn(String username, String password, {destination: '/auth'}) {
    var data = {'destination': destination,
                'credential_0': username,
                'credential_1': password,
                'credential_2': expiration};
    var completer = new async.Completer();
    dom.HttpRequest.postFormData(url, data).then((dom.HttpRequest r) {
      completer.complete(r.responseText);
    }, onError: (e) => completer.completeError(e));
    return completer.future;
  }
}
