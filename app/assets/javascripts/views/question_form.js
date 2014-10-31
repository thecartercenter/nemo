// ELMO.Views.QuestionForm
//
// View model for Question form
(function(ns, klass) {

  // constructor
  ns.QuestionForm = klass = function(params) { var self = this;
    self.params = params;

    // hookup type change event and trigger immediately
    var type_box = $('div.question_fields .form_field#qtype_name .control select');
    type_box.on('change', function(e){ self.question_type_changed(); });

    // run the type box changed event immediately
    // this might be the only time it runs since the form might be in show mode
    self.question_type_changed({initial: true});

    // hookup add option set link
    $('div.question_fields a.create_option_set').on('click', function(){ self.show_option_set_form(); return false; });

    // hookup form submit for modal
    $('#create-option-set .btn-primary').on('click', function() {$('form.option_set_form').submit();});

    // register a callback for when option set form submission is done
    $(document).on('option_set_form_submit_success', 'form.option_set_form', function(e, option_set){
      self.option_set_created(option_set);
    });
  };

  // gets the current value of the field with the given name
  // still works if field is read_only
  klass.prototype.field_value = function(field_name) { var self = this;
    var field_div = $('.question_fields .form_field[data-field-name=' + field_name + '] .control');

    // if read only
    if (field_div.is('.read_only')) {
      // first get the wrapper
      var wrapper = field_div.find('.ro-val');

      // now try to get the wrapper's data-val value, or just the wrapper's contents failing that
      return wrapper.data('val') || wrapper.text();

    // otherwise (not read only) just get the field value
    } else
      return field_div.find('input, select, textarea').val();
  }

  klass.prototype.question_type_changed = function(options) { var self = this;
    var selected_type = self.field_value('qtype_name');

    // Show/hide option set field and hint
    options = options || {}
    options.multilevel = selected_type == 'select_one'
    self.show_option_set_select(selected_type == 'select_one' || selected_type == 'select_multiple', options);

    // show/hide max/min
    var show_max_min = (selected_type == "decimal" || selected_type == "integer");
    $(".question_fields .minmax")[show_max_min ? 'show' : 'hide']();

    // reset boxes if hiding
    if (!show_max_min) {
      $(".form_field#minimum input[id$='_minimum']").val("");
      $(".form_field#minimum input[id$='_minstrictly']").prop("checked", false);
      $(".form_field#maximum input[id$='_maximum']").val("");
      $(".form_field#maximum input[id$='_maxstrictly']").prop("checked", false);
    }
  }

  klass.prototype.show_option_set_select = function(show, options) { var self = this;
    var select = $("div.question_fields .form_field[data-field-name=option_set_id]");
    select[show ? 'show' : 'hide']();

    // If showing, disable the multilevel options based on options.multilevel.
    if (show) {
      var mult_options = select.find('.control select option[data-multilevel=true]');
      options.multilevel ? mult_options.removeAttr('disabled') : mult_options.attr('disabled', 'disabled');
    }

    // Reset value.
    if (!options.initial)
      select.find('.control select').val('');
  };

  // shows the create option set form and sets up a callback to receive the result
  klass.prototype.show_option_set_form = function() { var self = this;
    // show the loading indicator
    $('div.question_fields #option_set_id .loading_indicator').show();

    // populate and show the modal
    $("#create-option-set .modal-body.option-set").load(self.params.new_option_set_path, function(){
      $("#create-option-set").modal('show');
    });
  }

  // called when the option set is created so we can add it to the dropdown
  klass.prototype.option_set_created = function(option_set) { var self = this;
    // close the dialog
    $("#create-option-set").modal('hide');

    // add the new option set to the list and select it
    var option = $('<option>', {value: option_set.id, 'data-multilevel': option_set.multi_level}).text(option_set.name);
    $('div.question_fields .form_field#option_set_id select').append(option).val(option_set.id);

    // flash the option set row
    $('div.question_fields .form_field#option_set_id').effect("highlight", {}, 1000);
  };

}(ELMO.Views));
