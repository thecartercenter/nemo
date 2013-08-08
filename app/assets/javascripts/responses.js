var responses_old_ids;

function responses_setup_periodic_update() {
  setInterval(responses_fetch, 30000);
}

function responses_fetch() {
  // get current list of IDs
  responses_old_ids = responses_get_ids();
  
  // run the ajax request
  Utils.ajax_with_session_timeout_check({
    url: Utils.add_url_param(window.location.href, "auto=1"),
    method: "get",
    success: responses_update
  });
}

// gets IDs of each row in index table
function responses_get_ids() {
  var ids = [];
  if ($('#index_table_body')) {
    var rows = $('#index_table_body tr');
    for (var i = 0; i < rows.length; i++) ids.push(rows[i].id);
  }
  return ids;
}

function responses_update(data) {
  $('#index_table').html(data);
  var new_ids = responses_get_ids();
  for (var i = 0; i < new_ids.length; i++) {
    if (responses_old_ids.indexOf(new_ids[i]) == -1)
      $("#" + new_ids[i]).effect("highlight", {}, 1000);
  }
}

$(document).ready(function(){
  $("a.create_response").on("click", function(){
    $('#form_chooser').show(); 
    return false;
  });
  
  $(".icon-exclamation-sign").tooltip({
	  content: function() {
		  var id = $(this).attr("data");
          return "Possible duplicate of <br> <a href='/responses/" + id + "'> response #" + id + "</a>.<br> <b> Click icon if not duplicate. <br> <i class=\"icon-arrow-down\"></i> </b>";
	  },
	  hide: {
	    delay: 1000	  
	  },
	  track: true,
      position: {
         my: "center bottom-5",
         at: "center top",
       }
  });
});