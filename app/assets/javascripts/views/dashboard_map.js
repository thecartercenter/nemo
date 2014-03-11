// ELMO.Views.DashboardMap
//
// View model for the dashboard map
(function(ns, klass) {

  // constructor
  ns.DashboardMap = klass = function(params) { var self = this;
    self.params = params;

    // create the map
    self.map = new google.maps.Map($('div.response_locations')[0], {
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      zoom: 1,
      streetViewControl: false,
      draggableCursor: 'pointer'
    });

    // add the markers and keep expanding the bounding rectangle
    var bounds = new google.maps.LatLngBounds();
    self.markers = [];
    self.params.locations.forEach(function(l){
      // get float values from string
      var split = l.loc.split(' ');
      var lat = parseFloat(split[0]);
      var lng = parseFloat(split[1]);

      // create marker and add to map
      var p = new google.maps.LatLng(lat, lng);
      var m = new google.maps.Marker({
        map: self.map,
        position: p,
        title: I18n.t('activerecord.models.response.one') + ' #' + l.r_id,
        r_id: l.r_id
      });

      // expand the bounding rectangle
      bounds.extend(p);

      // setup event listener to show info window
      google.maps.event.addListener(m, 'click', function() { self.show_info_window(this); });
    });

    // if there are stored bounds, use those to center map
    if (self.load_bounds(self.params.serialization_key))
      ; // do nothing since the method call does it all

    // else if there are no responses, just center at 0 0
    else if (self.params.locations.length == 0)
      self.map.setCenter(new google.maps.LatLng(0, 0));

    // else use bounds determined above
    else
      // center/zoom the map
      self.map.fitBounds(bounds);

    // save map bounds each time they change
    google.maps.event.addListener(self.map, 'bounds_changed', function() { self.save_bounds(self.params.serialization_key); });
  };

  klass.prototype.show_info_window = function(marker) { var self = this;
    // close any existing window
    if (self.info_window) self.info_window.close();

    // open the window and show the loading message
    self.info_window = new google.maps.InfoWindow({content: '<div class="info_window"><h3>' + I18n.t('response.loading') + '</h3></div>'});
    self.info_window.open(self.map, marker);

    // do the ajax call after the info window is loaded
    google.maps.event.addListener(self.info_window, 'domready', function() {
      // load the response
      $.ajax({
        url: self.params.info_window_url,
        method: 'get',
        data: {response_id: marker.r_id},
        success: function(data){ $('div.info_window').replaceWith(data); },
        error: function(){ $('div.info_window').html(I18n.t('layout.server_contact_error')); }
      });
    });
  };

  // stores the current map bounds in localStorage using the given key
  klass.prototype.save_bounds = function(key) { var self = this;
    // load and parse
    var saved_bounds = JSON.parse(window.localStorage.dashboardMapBounds || '{}');

    // add hash with center and zoom
    saved_bounds[key] = {
      center: [self.map.getCenter().lat(), self.map.getCenter().lng()],
      zoom: self.map.zoom
    };

    // write out again
    window.localStorage.dashboardMapBounds = JSON.stringify(saved_bounds);
  };

  // checks if there are bounds stored in localStorage for the given key
  klass.prototype.peek_bounds = function(key) { var self = this;
    return window.localStorage.dashboardMapBounds && JSON.parse(window.localStorage.dashboardMapBounds)[key];
  };

  // attempts to load the map bounds from localStorage using the given key
  // if successful, returns true
  // if not found, does nothing and returns false
  klass.prototype.load_bounds = function(key) { var self = this;
    var bounds;
    if (bounds = self.peek_bounds(key)) {
      self.map.setCenter(new google.maps.LatLng(bounds.center[0], bounds.center[1]));
      self.map.setZoom(bounds.zoom);
      return true;
    }
    return false;
  };

}(ELMO.Views));