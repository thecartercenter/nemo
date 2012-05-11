function lookup_places(class_name) {
  // show loading indicator
  $('#place_lookup_results').html("<div class=\"loader\">Loading suggestions...</div>");

  // send ajax request
  // run the ajax request
  Utils.ajax_with_session_timeout_check({
    url: "/places/lookup",
    data: {query: $('#place_lookup_query').val(), class_name: class_name },
    method: "get",
    success: function(data) { $('#place_lookup_results').html(data); }
  });
}

function show_place_lookup_form() {
  $('#place_lookup_form').show();
  try {$('#place_lookup_instructions').show();} catch (e) {}
}