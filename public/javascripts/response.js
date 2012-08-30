(function (ns, klass) {
  
  ns.Response = klass = {}
  
  // conditions array
  klass.conditions = [];
  
  klass.init = function() {
    // hookup edit location links
    $("a.edit_location_link").click(function(e){ klass.show_location_picker(e); return false; }) 
    
    // initialize conditions
    $.each(klass.conditions, function(i, cond){ cond.init(); })
  }
  
  // shows the map and location search box
  klass.show_location_picker = function(event) {
    var location_box = $(event.target).parents("div.form_field_control").find("input.qtype_location")[0];
    new ELMO.LocationPicker(location_box);
  }
  

}(ELMO));

$(document).ready(ELMO.Response.init);