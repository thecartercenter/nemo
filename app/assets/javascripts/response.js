(function (ns, klass) {

  ns.Response = klass = {}

  // conditions array
  klass.conditions = [];

  klass.init = function() {
    // hookup edit location links
    $("a.edit_location_link").click(function(e){ klass.show_location_picker(e); return false; });

    // initialize conditions
    $.each(klass.conditions, function(i, cond){ cond.init(); });
  }

  // shows the map and location search box
  klass.show_location_picker = function(event) {
    // store existing gps if any
    var location_box = $(event.target).parents("div.control").find("input.qtype_location")[0];
    // create and intialize location picker dialog
    new ELMO.LocationPicker(location_box);
    $('#location-picker-modal').modal('show');

  }

}(ELMO));