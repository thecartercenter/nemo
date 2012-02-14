function lookup_places(class_name) {
  // show loading indicator
  $('#place_lookup_results').html("<div class=\"loader\">Loading suggestions...</div>");

  // send ajax request
  $.get('/places/lookup', {query: $('#place_lookup_query').val(), class_name: class_name }, function(data) {
    $('#place_lookup_results').html(data);
  });
}

function show_place_lookup_form() {
  $('#place_lookup_form').show();
  try {$('#place_lookup_instructions').show();} catch (e) {}
}