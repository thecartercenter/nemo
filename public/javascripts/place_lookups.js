function lookup_places() {
  var div_id = 'place_lookup_results';
  
  // show loading indicator
  $(div_id).innerHTML = '<div class="loader">Loading suggestions...</div>';

  // send updater request
  new Ajax.Updater(div_id, '/place_lookups/suggest', {
    parameters: { query: $('place_lookup_query').value }, 
    method: "get"
  });
}