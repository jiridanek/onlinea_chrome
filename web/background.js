var myJsHelpers = {  
  "isForumRule": {
    conditions: [
      new chrome.declarativeContent.PageStateMatcher({
        pageUrl: {
          schemes: ['https']
         ,pathSuffix: 'auth/diskuse/diskusni_forum_indiv.pl'
         ,queryContains: 'guz'
        }
       ,css: ['div.df_vl,div.df_vl_nect']
      })
     ,new chrome.declarativeContent.PageStateMatcher({
        pageUrl: {
          schemes: ['https']
         ,pathPrefix: '/auth/df/'
        }
       ,css: ['div.df_vl,div.df_vl_nect']
      })
    ]
    ,actions: [ new chrome.declarativeContent.ShowPageAction() ]
  },
  
  "installContentRules": function() {
  	var that = this;
    chrome.declarativeContent.onPageChanged.removeRules(undefined, function() {
      chrome.declarativeContent.onPageChanged.addRules([that.isForumRule]);
      //window.alert('baf');
    });
  }
};