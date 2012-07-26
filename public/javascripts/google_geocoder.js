// ELMO.GoogleGeocoder
(function(ns, klass) {

  // constructor
  ns.GoogleGeocoder = klass = function(query, callback) {
    this.query = query;
    this.callback = callback;
    
    // run the search (curry for callbacks)
    (function(_this){
      Utils.ajax_with_session_timeout_check({url: klass.geocoder_url, method: "get", data: {address: _this.query}, 
        success: function(data){_this.search_done(data)}, error: function(data){_this.search_error(data)}});
    })(this);
  };

  // search completed successfully
  klass.prototype.search_done = function(data) {
    // if bad status message, send to error function
    if (data.status != "OK" && data.status != "ZERO_RESULTS")
      this.search_error(data);
    else
      this.callback(data.results);
  }
  
  // search failed
  klass.prototype.search_error = function(data) {
    this.callback("Search Error")
  }

  // geocoder URL
  klass.geocoder_url = "/proxies/geocoder";

}(ELMO));