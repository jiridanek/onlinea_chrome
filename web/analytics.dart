library analytics;

import 'dart:js' as js;

var _context;
js.JsFunction _context_ga;

initialize() {
  _context = js.context;
  _context_ga = _context['ga'];
}

_ga(List args) {
  _context_ga.apply(args);
}

sendEvent({String category, String action, String label: null, num value: null}) {
  _ga(['send', 'event', category, action, label, value]);
}

setLocation(String value) {
  _ga(['set', 'location', value]);
}

sendPageview({bool nonInteraction:false}) {
  _ga(['send', 'pageview']);
  if(nonInteraction) {
    _ga(['send', 'pageview', new js.JsObject.jsify({"nonInteraction": true})]);
  }
}