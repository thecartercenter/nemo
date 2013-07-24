// ELMO.Question
(function(ns, klass) {
  
  // constructor
  ns.Question = klass = function() { var self = this;
    // hookup type change event and trigger immediately
    var type_box = $('div.question_fields .form_field#qtype_name .control select');
    type_box.on('change', function(e){ self.question_type_changed(e) });
    type_box.trigger("change");
  }
  
  klass.prototype.question_type_changed = function(event) { var self = this;
    var selected_type = $(event.target).find("option:selected").val();
    
    // show/hide option set
    var show_opt_set = (selected_type == "select_one" || selected_type == "select_multiple");
    $("div.question_fields .form_field#option_set_id")[show_opt_set ? 'show' : 'hide']();

    // reset select if hiding
    if (!show_opt_set) 
      $("div.question_fields .form_field#option_set_id .control select")[0].selectedIndex = 0;
    
    // show/hide max/min
    var show_max_min = (selected_type == "decimal" || selected_type == "integer");
    $("div.question_fields .form_field#minimum")[show_max_min ? 'show' : 'hide']();
    $("div.question_fields .form_field#maximum")[show_max_min ? 'show' : 'hide']();
    
    // reset boxes if hiding
    if (!show_max_min) {
      $(".form_field#minimum input[id$='_minimum']").val("");
      $(".form_field#minimum input[id$='_minstrictly']").prop("checked", false);
      $(".form_field#maximum input[id$='_maximum']").val("");
      $(".form_field#maximum input[id$='_maxstrictly']").prop("checked", false);
    }
  }
}(ELMO));