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
  return $('form input[type=checkbox].batch_op');
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

// counts how many boxes are checked
function batch_count_checked(cbs) {
  if (typeof(cbs) == "undefined")
    cbs = batch_get_checkboxes();

  var count = 0;
  for (var i = 0; i < cbs.length; i++)
    if (cbs[i].checked)
      count++;
  return count;
}

// updates the select all link to reflect current state of boxes
function batch_update_select_all_link(yn) {
  if (typeof(yn) == "undefined") yn = !batch_all_checked();
  $('#select_all_link').html(I18n.t("layout." + (yn ? "select_all" : "deselect_all")));
}

// event handler for when a checkbox is clicked
function batch_cb_changed(cb) {
  // change text of link if all checked
  batch_update_select_all_link(!batch_all_checked());
}

// submits the batch form to the given path
function batch_submit(options) {
  // ensure there is at least one box checked, and error if not
  var count = batch_count_checked();
  if (count == 0)
    alert(I18n.t("layout.no_selection"));

  // else, show confirm dialog (if requested), and proceed if 'yes' clicked
  else if (options.confirm == "" || confirm(options.confirm.replace(/###/, count))) {

    // construct a temporary form
    var form = $('<form>').attr('action', options.path).attr('method', 'post');

    // copy the checked checkboxes to it
    // (we do it this way in case the main form has other stuff in it that we don't want to submit)
    form.append($('input.batch_op:checked').clone());

    // need to append form to body before submitting
    form.appendTo($('body'));

    // submit the form
    form.submit();
  }
}
