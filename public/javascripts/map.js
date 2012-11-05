var map;
var map_marker_info = {};
var icons = {}
function draw_map(markers, bounds) {

  var map = new google.maps.Map($("#map_canvas")[0], {
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    streetViewControl: false,
    zoom: 3
  });
  
  for (var i = 0; i < markers.length; i++) {
    var marker = markers[i];
    marker.ui = new google.maps.Marker({
          position: new google.maps.LatLng(marker.latitude, marker.longitude), 
          map: map
      });
    var infowindow = null;
    // curry!
    (function(m) {
      google.maps.event.addListener(m.ui, 'click', function() { 
        // close any previous infowindow
        if (infowindow) infowindow.close();
        infowindow = new google.maps.InfoWindow({content: m.info});
        infowindow.open(map, m.ui); 
      });
    }(marker));
  }  
  
  // if bounds argument is given, translate it to google maps speak
  if (bounds) {
    map.setCenter(new google.maps.LatLng(
      ((bounds.lat_max + bounds.lat_min) / 2.0),
      ((bounds.lng_max + bounds.lng_min) / 2.0)
    ));
    map.fitBounds(new google.maps.LatLngBounds(
      //bottom left
      new google.maps.LatLng(bounds.lat_min, bounds.lng_min),
      //top right
      new google.maps.LatLng(bounds.lat_max, bounds.lng_max)
    ));
  }
}