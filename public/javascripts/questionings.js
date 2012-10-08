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

// ELMO.Questioning
(function(ns, klass) {
  
  // constructor
  ns.Questioning = klass = function() {
    // hookup type change event and trigger immediately
    var type_box = $('form.questioning_form .form_field#question_type_id .form_field_control select');
    (function(_this){ type_box.change(function(e){_this.question_type_changed(e)}); })(this);
    type_box.trigger("change");
  }
  
  klass.prototype.question_type_changed = function(event) {
    var selected_type = $(event.target).find("option:selected").text();
    
    // show/hide option set
    var show_opt_set = (selected_type == "Select One" || selected_type == "Select Multiple");
    $("form.questioning_form .form_field#option_set_id")[show_opt_set ? 'show' : 'hide']();

    // reset select if hiding
    if (!show_opt_set) 
      $("form.questioning_form .form_field#option_set_id .form_field_control select")[0].selectedIndex = 0;
    
    // show/hide max/min
    var show_max_min = (selected_type == "Decimal" || selected_type == "Integer");
    $("form.questioning_form .form_field#minimum")[show_max_min ? 'show' : 'hide']();
    $("form.questioning_form .form_field#maximum")[show_max_min ? 'show' : 'hide']();
    
    // reset boxes if hiding
    if (!show_max_min) {
      $(".form_field#minimum input[id$='_minimum']").val("");
      $(".form_field#minimum input[id$='_minstrictly']").prop("checked", false);
      $(".form_field#maximum input[id$='_maximum']").val("");
      $(".form_field#maximum input[id$='_maxstrictly']").prop("checked", false);
    }
  }
}(ELMO));

$(document).ready(function() { new ELMO.Questioning(); });