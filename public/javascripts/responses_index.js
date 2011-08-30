var responses_old_ids;

function responses_setup_periodic_update() {
  setInterval(responses_update, 30000);
}

function responses_update() {
  console.log("updating")
  // get current list of IDs
  responses_old_ids = responses_get_ids();
  
  // run the ajax request, passing the latest_id
  new Ajax.Updater($('index_table'), "/responses?table_only=1", {
    method: 'get',
    onComplete: responses_flash_new
  });
}

// gets IDs of each row in index table
function responses_get_ids() {
  var ids = [];
  if ($('index_table_body')) {
    var rows = $('index_table_body').getElementsByTagName('tr');
    for (var i = 0; i < rows.length; i++) ids.push(rows[i].id);
  }
  return ids;
}

function responses_flash_new(transport) {
  var new_ids = responses_get_ids();
  for (var i = 0; i < new_ids.length; i++) {
    if (responses_old_ids.indexOf(new_ids[i]) == -1)
      setTimeout(function(id){new Effect.Highlight(id);}.curry(new_ids[i]), 100);}
}