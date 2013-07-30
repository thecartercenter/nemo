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
    if (self.params.responses.length == 0)
      self.map.setCenter(new google.maps.LatLng(0, 0));

    else {
      
      // add the markers and keep expanding the bounding rectangle
      var bounds = new google.maps.LatLngBounds();
      self.markers = [];
      self.params.responses.forEach(function(r){
        if (r.location) {
          var p = new google.maps.LatLng(r.location[0], r.location[1]);
          var m = new google.maps.Marker({
            map: self.map,
            position: p,
            title: I18n.t('activerecord.models.response.one') + ' #' + r.id,
            _response: r
          });
          
          // expand the bounding rectangle
          bounds.extend(p);

          // setup event listener to show info window
          google.maps.event.addListener(m, 'click', function() { self.show_info_window(this); });
        }
      })
    
      // center/zoom the map
      self.map.setCenter(bounds.getCenter());
      self.map.fitBounds(bounds);
    }
  };
  
  klass.prototype.show_info_window = function(marker) { var self = this;
    var r = marker._response;
    
    // add basic stuff
    var content = '<div class="info_window"><h3>' + I18n.t('activerecord.models.response.one') + ' #' + r.id + '</h3><table>' +
      '<tr><td>' + I18n.t('activerecord.models.form.one') + '</td><td>' + r.form.name + '</td></tr>' +
      '<tr><td>' + I18n.t('activerecord.attributes.response.user_id') + '</td><td>' + r.user.name + '</td></tr>' +
      '<tr><td>' + I18n.t('activerecord.attributes.response.created_at') + '</td><td>' + r.created_at + '</td></tr>';
    
    // close table and add link
    content += '</table><a href="' + Utils.build_url('responses', r.id) + '">' + I18n.t('response.view_response') + '</a></div>';
    
    // open the window
    (new google.maps.InfoWindow({content: content})).open(self.map, marker);
  };

}(ELMO.Views));