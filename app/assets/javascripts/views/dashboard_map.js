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
    
    // if there are no responses, just center at 0 0
    if (self.params.locations.length == 0)
      self.map.setCenter(new google.maps.LatLng(0, 0));

    else {
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
      })
    
      // center/zoom the map
      self.map.setCenter(bounds.getCenter());
      self.map.fitBounds(bounds);
    }
  };
  
  klass.prototype.show_info_window = function(marker) { var self = this;
    // close any existing window
    if (self.info_window) self.info_window.close();
    
    // open the window and show the loading message
    self.info_window = new google.maps.InfoWindow({content: '<div class="info_window"><h3>' + I18n.t('response.loading') + '</h3></div>'});
    self.info_window.open(self.map, marker);
    
    // load the response
    $.ajax({
      url: self.params.info_window_url,
      method: 'get',
      data: {response_id: marker.r_id},
      success: function(data){ $('div.info_window').replaceWith(data); }
    })
  };

}(ELMO.Views));