(function (Response, undefined) {
  
  Response.init = function() {
    // hookup edit location links
    $("a.edit_location_link").click(function(e){ show_location_picker(e); return false; })
  }
  
  // shows the map and location search box
  function show_location_picker(event) {
    var location_box = $(event.target).parents("td.value").find("input.qtype_location")[0];
    new ELMO.LocationPicker(location_box);
  }

}(Response = {}));

$(document).ready(Response.init);