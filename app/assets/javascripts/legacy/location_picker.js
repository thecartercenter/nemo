// ELMO.LocationPicker
(function(ns, klass) {

  // constructor
  ns.LocationPicker = klass = function(location_field) { var self = this;

    // don't show if it's already up
    if (klass.showing) return;

    // save ref to location field
    self.location_field = $(location_field);

    // save ref to modal
    self.container = $("#location-picker-modal");

    // set the flag
    klass.showing = true;

    // get the current lat/lng if available
    self.location = self.parse_lat_lng(self.location_field.val());

    // load the map after the window is displayed
    self.container.on('shown.bs.modal', function (e) { self.initialize_map(); });

  }

  klass.prototype.initialize_map = function() { var self = this;

    // save a default centering location if null
    var latlng = new google.maps.LatLng(-34.397, 150.644);

    // create map
    self.map = new google.maps.Map($("#map-canvas")[0], {
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      zoom: self.location ? 7 : 2,
      streetViewControl: false,
      draggableCursor: 'pointer',
      center: self.location ? new google.maps.LatLng(self.location[0], self.location[1]) : latlng,
    });

    // put a mark at the present location
    self.mark_location();

    // setup the search box
    self.search_focus(false);

    // map click event
    google.maps.event.addListener(self.map, 'click', function(event) {self.map_click(event)});

    // hook up the accept link
    self.container.find("button.accept_link").click(function() {self.close(true); return false;});

    // hook up focus and blur events for search box
    self.container.find("form.location_search input.query").focus(function() {self.search_focus(true);});
    self.container.find("form.location_search input.query").blur(function() {self.search_focus(false);});

    // hook up form submit
    self.container.find("form.location_search").submit(function() {self.search_submit(); return false;});
  }

  // get float values for lat ang lng from a string
  klass.prototype.parse_lat_lng = function(str) {
    var m = str.match(ELMO.LAT_LNG_REGEXP);
    return m && m[1] && m[3] ? [parseFloat(m[1]), parseFloat(m[3])] : null;
  }

  // handles a click event on the map
  klass.prototype.map_click = function(event) { var self = this;
    self.set_location([event.latLng.lat(), event.latLng.lng()])
  }

  klass.prototype.search_focus = function(is_focus) { var self = this;
    // get ref.
    var box = self.container.find("form.location_search input.query");
    var init_str = I18n.t("location_picker.search_locations");

    // if focused, blank the box and set the color and font style
    if (is_focus && box.val() == init_str)
      box.css("color", "#222").css("font-style", "normal").val("");

    // otherwise (blur), reset the box to the blank style using the boilerplate code
    else if (box.val().trim() == "")
      box.css("color", "#888").css("font-style", "italic").val(init_str);
  }

  // submits the search to the google geocoder class
  klass.prototype.search_submit = function() { var self = this;

    // get query
    var query = self.container.find("form.location_search input.query").val().trim();

    // do nothing if empty
    if (query == "") return;

    // show loading indicator
    self.container.find("div.loading_indicator img").show();

    // submit, giving callback method
    new ELMO.GoogleGeocoder(query, function(r){self.show_search_results(r)});
  }

  // displays the search results and hooks up the links
  klass.prototype.show_search_results = function(results) { var self = this;
    // hide loading indicator
    self.container.find("div.loading_indicator img").hide();

    // get ref to div and empty it
    var results_div = self.container.find("form.location_search div.results").empty();

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

      self.container.find("a.result_link").click(function(e){
        self.set_location(self.parse_lat_lng(e.target.title), {pan: true});
      });
    }

  }

  klass.prototype.set_location = function(lat_lng, options) { var self = this;
    self.location = [lat_lng[0].toFixed(6), lat_lng[1].toFixed(6)];
    self.mark_location();

    // pan if requested
    if (options && options.pan)
      self.map.panTo(self.marker.getPosition());
  }

  // updates the map to indicate that the given location has been chosen
  klass.prototype.mark_location = function() { var self = this;
    // hide loading indicator
    self.container.find("div.loading_indicator img").hide();

    // if the location is set
    if (self.location) {

      // create the marker if necessary
      if (!self.marker)
        self.marker = new google.maps.Marker({ map: self.map });

      // move the marker
      self.marker.setPosition(new google.maps.LatLng(self.location[0], self.location[1]));
    }

    // show the chosen location
    self.container.find("span.cur_lat_lng").html(I18n.t("location_picker.current_location") + ": " +
      (self.location ? self.location[0] + " " + self.location[1] : "None"));
  }

  // closes the window, optionally saving the chosen location in the location field
  klass.prototype.close = function(save) { var self = this;
    // copy the value if requested
    if (save) self.location_field.val(self.location[0] + " " + self.location[1]);

    // close the dialog and lower flag
    klass.showing = false;
    $('#location-picker-modal').modal('hide');
  }

  // class variables
  klass.showing = false;

}(ELMO));
