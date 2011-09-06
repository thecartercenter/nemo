function show_hide_option_set(question_type) {
  show = question_type.match(/^Select/)
  $('option_set')[show ? 'show' : 'hide']()
  $('option_set_not_applicable')[!show ? 'show' : 'hide']()
  if (!show) $('option_set').selectedIndex = 0
}

function condition_update_choices() {
  // get the op dropdown and clear it out
  var op_field = $('questioning_condition_op')
  clear_select(op_field);
  
  // get the chosen question id and type
  var question_field = $('questioning_condition_ref_qing_id');
  var chosen_id = question_field.options[question_field.selectedIndex].value;
  if (chosen_id == "") return;
  var chosen_type = condition_q_types[chosen_id];
  
  // for each op in the ops list, if the question type is in its 'types' list, add it to the op dropdown
  for (var op_name in condition_ops)
    if (condition_ops[op_name]["types"].indexOf(chosen_type) != -1)
      add_option(op_field, op_name, op_name);
  
  var value_select = $('questioning_condition_value_select');
  var value_box = $('questioning_condition_value_box');
  // clear the dropdown
  clear_select(value_select);
  // show the appropriate value field, depepnding on if the chosen question has options
  var opts = condition_q_options[chosen_id];

  if (opts) {
    // populate the dropdown
    for (var i = 0; i < opts.length; i++)
      add_option(value_select, opts[i][0], opts[i][1]);
    // show the dropdown
    condition_show_hide_value_fields(value_select, value_box);
  } else {
    // clear and show the box
    value_box.value = "";
    condition_show_hide_value_fields(value_box, value_select);
  }
}

function condition_show_hide_value_fields(show, hide) {
  show.show();
  hide.hide();
  show.name = "questioning[condition][value]";
  hide.name = "";
}

function clear_select(select) {
  while (select.length > 1) select.remove(1);
}

function add_option(select, text, value, selected) {
  var opt = document.createElement('option');
  opt.text = text;
  opt.value = value;
  opt.selected = selected || false;
  try {select.add(opt, null);} // standards compliant; doesn't work in IE
  catch(ex) {select.add(opt);} // IE only
}