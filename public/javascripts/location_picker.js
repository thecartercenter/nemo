// ELMO.LocationPicker 
(function(ns) {
  
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
      draggableCursor: 'pointer'
    });
    
    // put a mark at the present location
    this.mark_location(this.location);
    
    // center the map
    this.center_map(this.location || [0,0]);

    // use currying to hook up events
    (function(_this) {
      // map click event      
      google.maps.event.addListener(_this.map, 'click', function(event) {_this.map_click(event)});

      // hook up the accept and cancel links
      _this.container.find("a.accept_link").click(function() {_this.close(true); return false;})
      _this.container.find("a.cancel_link").click(function() {_this.close(false); return false;})
    })(this);
  }
  
  // get float values for lat ang lng from a string
  klass.prototype.parse_lat_lng = function(str) {
    var m = str.match(ELMO.LAT_LNG_REGEXP);
    return m && m[1] && m[3] ? [parseFloat(m[1]), parseFloat(m[3])] : null;
  }
  
  // handles a click event on the map
  klass.prototype.map_click = function(event) {
    this.location = [event.latLng.lat().toFixed(6), event.latLng.lng().toFixed(6)];
    this.mark_location(this.location);
  }
  
  // updates the map to indicate that the given location has been chosen
  klass.prototype.mark_location = function(lat_lng) {
    // if the location is set
    if (lat_lng) {

      // create the marker if necessary
      if (!this.marker)
        this.marker = new google.maps.Marker({
          map: this.map
        });
        
      // move the marker
      this.marker.setPosition(new google.maps.LatLng(lat_lng[0], lat_lng[1]));
    }
    
    // show the chosen location
    this.container.find("span.cur_lat_lng").html("Current Location: " + 
      (lat_lng ? lat_lng[0] + " " + lat_lng[1] : "None"));
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
  klass.is_showing = false;
  
}(ELMO));