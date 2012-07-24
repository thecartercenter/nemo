function show_hide_option_set(question_type) {
  show = question_type.match(/^Select/)
  $('#option_set')[show ? 'show' : 'hide']()
  $('#option_set_not_applicable')[!show ? 'show' : 'hide']()
  if (!show) $('#option_set')[0].selectedIndex = 0
}

function condition_update_choices() {
  // get the op dropdown and clear it out
  var op_field = $('#questioning_condition_op')[0]
  clear_select(op_field);
  
  // get the chosen question id and type
  var question_field = $('#questioning_condition_ref_qing_id')[0];
  var chosen_id = question_field.options[question_field.selectedIndex].value;
  if (chosen_id == "") return;
  var chosen_type = condition_q_types[chosen_id];
  
  // for each op in the ops list, if the question type is in its 'types' list, add it to the op dropdown
  for (var op_name in condition_ops)
    if (condition_ops[op_name]["types"].indexOf(chosen_type) != -1)
      add_option(op_field, op_name, op_name);

  var value_field = $('#questioning_condition_value')[0];
  var option_id_field = $('#questioning_condition_option_id')[0];
  // clear the dropdown
  clear_select(option_id_field);
  // show the appropriate value field, depepnding on if the chosen question has options
  var opts = condition_q_options[chosen_id];

  if (opts) {
    // populate the dropdown
    for (var i = 0; i < opts.length; i++)
      add_option(option_id_field, opts[i][0], opts[i][1]);
    // show the dropdown
    condition_show_hide_value_fields(option_id_field, value_field);
  } else {
    // clear and show the box
    value_field.value = "";
    condition_show_hide_value_fields(value_field, option_id_field);
  }
}

function condition_show_hide_value_fields(show, hide) {
  $(show).show();
  $(hide).hide();
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

(function (Questioning, undefined) {
  Questioning.show_or_hide_max_min = function() {
    var sel = $('tr#type_row option:selected, tr#type_row td.value div.dummy').text(); 
    if(sel == "Decimal" || sel == "Integer")
      $('tr#max, tr#min').show();
    else
      $('tr#max, tr#min').hide();
  }
  Questioning.init = function() {
    // hookup type change event
    $('tr#type_row select').change(Questioning.show_or_hide_max_min);
    Questioning.show_or_hide_max_min();
  }
}(Questioning = {}));

$(document).ready(Questioning.init);