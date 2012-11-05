// Sassafras.Utils
(function(ns, klass) {
  
  // constructor
  ns.Utils = klass = function() {
  }
  
  // class functions
  
  // matches two listays against each other
  // passes matching elements to callback, or passes null if no match is found
  klass.match_lists = function(a, b, callback) {
    
    var build_hash = function(spec) {
      var h = {};
      for (var i = 0; i < spec.list.length; i++)
        if (spec.comparator == null)
          h[spec.list[i]] = spec.list[i];
        else
          h[spec.comparator(spec.list[i])] = spec.list[i];
      return h;
    }
    
    ah = build_hash(a);
    bh = build_hash(b);
    
    // matches: loop over a's elements, find them in b, yield, remove from both hashes
    for (var i = 0; i < a.list.length; i++) {
      var key = a.comparator == null ? a.list[i] : a.comparator(a.list[i]);
      var hit = bh[key];
      if (typeof(hit) != "undefined") {
        callback(a.list[i], hit);
        delete ah[key];
        delete bh[key];
      }
    }
    
    // a-only's: loop over ah's remaining elements. these had no match in b.
    for (var key in ah)
      callback(ah[key], null);

    // b-only's: loop over bh's remaining elements. these had no match in a.
    for (var key in bh)
      callback(null, bh[key]);
  }

}(Sassafras));