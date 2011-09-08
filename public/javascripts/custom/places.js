function lookup_places(class_name) {
  var div_id = 'place_lookup_results';
  
  // show loading indicator
  $(div_id).innerHTML = '<div class="loader">Loading suggestions...</div>';

  // send updater request
  new Ajax.Updater(div_id, '/places/lookup', {
    parameters: { query: $('place_lookup_query').value, class_name: class_name }, 
    method: "get"
  });
}

function show_place_lookup_form() {
  $('place_lookup_form').show();
  try {$('place_lookup_instructions').show();} catch (e) {}
}