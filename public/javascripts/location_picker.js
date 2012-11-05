// ELMO.LocationPicker 
(function(ns, klass) {
  
  // constructor
  ns.LocationPicker = klass = function(location_field) {
    
    // don't show if it's already up
    if (klass.showing) return;
    
    // save ref to location field
    this.location_field = $(location_field);
    
    // copy boilerplate
    this.container = $("div.boilerplate div.location_picker").clone();

    // create and save the div and show the dialog
    this.dialog = new ELMO.Dialog(this.container);

    // set the flag
    klass.showing = true;
    
    // get the current lat/lng if available 
    this.location = this.parse_lat_lng(this.location_field.val())
    
    // create the map
    var canvas_dom = this.container.find("div.map_canvas")[0];
    this.map = new google.maps.Map(canvas_dom, {
      mapTypeId: google.maps.MapTypeId.ROADMAP, 
      zoom: this.location ? 7 : 1,
      streetViewControl: false,
      draggableCursor: 'pointer'
    });
    
    // put a mark at the present location
    this.mark_location();
    
    // center the map
    this.center_map(this.location || [0,0]);
    
    // setup the search box
    this.search_focus(false);

    // use currying to hook up events
    (function(_this) {
      // map click event      
      google.maps.event.addListener(_this.map, 'click', function(event) {_this.map_click(event)});

      // hook up the accept and cancel links
      _this.container.find("a.accept_link").click(function() {_this.close(true); return false;})
      _this.container.find("a.cancel_link").click(function() {_this.close(false); return false;})
      
      // hook up focus and blur events for search box
      _this.container.find("form.location_search input.query").focus(function() {_this.search_focus(true);})
      _this.container.find("form.location_search input.query").blur(function() {_this.search_focus(false);})
      
      // hook up form submit
      _this.container.find("form.location_search").submit(function() {_this.search_submit(); return false;});
    })(this);
  }
  
  // get float values for lat ang lng from a string
  klass.prototype.parse_lat_lng = function(str) {
    var m = str.match(ELMO.LAT_LNG_REGEXP);
    return m && m[1] && m[3] ? [parseFloat(m[1]), parseFloat(m[3])] : null;
  }
  
  // handles a click event on the map
  klass.prototype.map_click = function(event) {
    this.set_location([event.latLng.lat(), event.latLng.lng()])
  }
  
  klass.prototype.search_focus = function(is_focus) {
    // get ref.
    var box = this.container.find("form.location_search input.query");
    var init_str = "Search Locations ...";
    
    // if focused, blank the box and set the color and font style
    if (is_focus && box.val() == init_str)
      box.css("color", "#222").css("font-style", "normal").val("");
  
    // otherwise (blur), reset the box to the blank style using the boilerplate code
    else if (box.val().trim() == "")
      box.css("color", "#888").css("font-style", "italic").val(init_str);
  }
  
  // submits the search to the google geocoder class
  klass.prototype.search_submit = function() {

    // get query
    var query = this.container.find("form.location_search input.query").val().trim();
    
    // do nothing if empty
    if (query == "") return;
    
    // show loading indicator
    this.container.find("div.loading_indicator img").show();
    
    // submit, giving callback method
    (function(_this){ new ELMO.GoogleGeocoder(query, function(r){_this.show_search_results(r)}); })(this);
  }
  
  // displays the search results and hooks up the links
  klass.prototype.show_search_results = function(results) {
    // hide loading indicator
    this.container.find("div.loading_indicator img").hide();

    // get ref to div and empty it
    var results_div = this.container.find("form.location_search div.results").empty();
    
    // show error if there is one
    if (typeof(results) == "string")
      results_div.text(results);
    else {
      // create links
      for (var i = 0; i < results.length; i++)
        results_div.append($("<a>").
          attr("href", "#").addClass("result_link").
          attr("title", results[i].geometry.location.lat + "," + results[i].geometry.location.lng).
          text(results[i].formatted_address));
          
      // hook up links
      (function(_this){
        _this.container.find("a.result_link").click(function(e){
          _this.set_location(_this.parse_lat_lng(e.target.title), {pan: true});
        });
      })(this);
    }
    
  }
  
  klass.prototype.set_location = function(lat_lng, options) {
    this.location = [lat_lng[0].toFixed(6), lat_lng[1].toFixed(6)];
    this.mark_location();
    
    // pan if requested
    if (options.pan)
      this.map.panTo(this.marker.getPosition());
  }
  
  // updates the map to indicate that the given location has been chosen
  klass.prototype.mark_location = function() {
    // hide loading indicator
    this.container.find("div.loading_indicator img").hide();

    // if the location is set
    if (this.location) {

      // create the marker if necessary
      if (!this.marker)
        this.marker = new google.maps.Marker({
          map: this.map
        });
        
      // move the marker
      this.marker.setPosition(new google.maps.LatLng(this.location[0], this.location[1]));
    }
    
    // show the chosen location
    this.container.find("span.cur_lat_lng").html("Current Location: " + 
      (this.location ? this.location[0] + " " + this.location[1] : "None"));
  }
  
  // centersthe map on the given lat_lng
  klass.prototype.center_map = function(lat_lng) {
    // get the point
    this.map.setCenter(new google.maps.LatLng(lat_lng[0], lat_lng[1]));
  }
  
  // closes the window, optionally saving the chosen location in the location field
  klass.prototype.close = function(save) {
    // copy the value if requested
    if (save) this.location_field.val(this.location[0] + " " + this.location[1]);
    
    // close the dialog and lower flag
    klass.showing = false;
    this.dialog.close();
  }
  
  // class variables
  klass.showing = false;
  
}(ELMO));