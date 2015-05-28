// gets all checkboxes in batch_form
function batch_get_checkboxes() {
  return $('form input[type=checkbox].batch_op');
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

    var token = $('meta[name="csrf-token"]').attr('content');
    $('<input>').attr({type: 'hidden', name: 'authenticity_token', value: token}).appendTo(form);

    // need to append form to body before submitting
    form.appendTo($('body'));

    // submit the form
    form.submit();
  }
}
