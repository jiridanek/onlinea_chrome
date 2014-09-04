(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','https://ssl.google-analytics.com/analytics.js','ga');

ga('create', 'UA-49758119-3', 'auto');

//https://stackoverflow.com/questions/16135000/how-do-you-integrate-universal-analytics-in-to-chrome-extensions/22152353#22152353
ga('set', 'checkProtocolTask', function(){/* just do not throw sth. here */});

ga('set', 'appName', '[ONLINE_A] Not Graded Posts');
ga('set', 'appVersion', chrome.app.getDetails().version);

//http://stackoverflow.com/questions/21033205/how-to-extend-google-analytics-to-track-ajax-etc-as-per-h5bp-docs
(function(window){
	window.onerror = function (message, file, line, column) {
	    ga(
	    	'send',
	        'event',
	        message,
	        'FILE: ' + file + ' LINE: ' + line + (column ? ' COLUMN: ' + column : '')
	    );
	};
}(window));
