// selects/deselcts all boxes
function batch_select_all() {
  // get checkboxes
  var cbs = batch_get_checkboxes();
  
  // test if all are checked
  var all_checked = batch_all_checked(cbs);

  // check/uncheck boxes
  for (var i = 0; i < cbs.length; i++)
    cbs[i].checked = !all_checked;
    
  // update link
  batch_update_select_all_link(all_checked);
}

// gets all checkboxes in batch_form
function batch_get_checkboxes() {
  var cb = [];
  var els = $('batch_form').elements;
  for (var i = 0; i < els.length; i++)
    if (els[i].type == "checkbox") cb.push(els[i]);
  return cb;
}

// tests if all boxes are checked
function batch_all_checked(cbs) {
  if (typeof(cbs) == "undefined")
    cbs = batch_get_checkboxes();
 
  var all_checked = true;
  for (var i = 0; i < cbs.length; i++)
    if (!cbs[i].checked) {
      all_checked = false;
      break;
    }
  return all_checked;
}

// tests if any boxes are checked
function batch_any_checked(cbs) {
  if (typeof(cbs) == "undefined")
    cbs = batch_get_checkboxes();
 
  var any_checked = false;
  for (var i = 0; i < cbs.length; i++)
    if (cbs[i].checked) {
      any_checked = true;
      break;
    }
  return any_checked;
}

// updates the select all link to reflect current state of boxes
function batch_update_select_all_link(yn) {
  if (typeof(yn) == "undefined") yn = !batch_all_checked();
  $('select_all_link').innerHTML = (yn ? "S" : "Des") + "elect all";
}

// event handler for when a checkbox is clicked
function batch_cb_changed(cb) {
  // change text of link if all checked
  batch_update_select_all_link(!batch_all_checked());
}

// submits the batch form to the given path
function batch_submit(path) {
  // ensure there is at least one box checked
  if (!batch_any_checked())
    alert("You haven't selected anything.");
  else {
    // get the form
    var f = $('batch_form');
    // set the action attrib
    f.action = path;
    // submit
    f.submit();
  }
}

// shows/hides a table row and fixes the row bg class for all the rows beneath it.
function toggle_table_row(id, yn) {
  var tr = $(id);
  if (yn == tr.visible()) return;
  // show/hide
  yn ? tr.show() : tr.hide();
  // loop over each row beneath, toggling classNames
  while (tr = tr.nextSibling)
    if (tr.tagName == "TR") {
      tr.toggleClassName("rowbg0");
      tr.toggleClassName("rowbg1");
    }
}