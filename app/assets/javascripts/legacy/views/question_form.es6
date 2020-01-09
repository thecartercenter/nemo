// THIS VIEW IS DEPRECATED, PREFER THE NEWER ONE QuestionFormView
//
// ELMO.Views.QuestionForm
//
// View model for Question form
(function (ns, klass) {
  // constructor
  ns.QuestionForm = klass = function (params) {
    const self = this;
    self.params = params;

    // hookup type change event and trigger immediately
    const type_box = $('div.question_fields .form-field#qtype_name .control select');
    type_box.on('change', (e) => { self.question_type_changed(); });

    // run the type box changed event immediately
    // this might be the only time it runs since the form might be in show mode
    self.question_type_changed({ initial: true });

    // hookup add option set link
    $('div.question_fields a.create_option_set').on('click', () => { self.show_option_set_form(); return false; });

    // hookup form submit for modal
    $('#create-option-set .btn-primary').on('click', () => { $('form.option_set_form').submit(); });

    // register a callback for when option set form submission is done
    $(document).on('option_set_form_submit_success', 'form.option_set_form', (e, option_set) => {
      self.option_set_created(option_set);
    });
  };

  // gets the current value of the field with the given name
  // still works if field is read_only
  klass.prototype.field_value = function (field_name) {
    const self = this;
    const field_div = $(`.question_fields .form-field[data-field-name=${field_name}] .control`);

    // if read only
    if (field_div.is('.read-only')) {
      // first get the wrapper
      const wrapper = field_div.find('.ro-val');

      // now try to get the wrapper's data-val value, or just the wrapper's contents failing that
      return wrapper.data('val') || wrapper.text();

    // otherwise (not read only) just get the field value
    } return field_div.find('input, select, textarea').val();
  };

  klass.prototype.question_type_changed = function (options) {
    const self = this;
    const selected_type = self.field_value('qtype_name');

    // Show/hide option set field and hint
    options = options || {};
    options.multilevel = selected_type == 'select_one';
    self.show_option_set_select(selected_type == 'select_one' || selected_type == 'select_multiple', options);

    // show/hide max/min
    const show_max_min = (selected_type == 'decimal' || selected_type == 'integer');
    $('.question_fields .minmax .form-field').css('display', show_max_min ? 'flex' : 'none');

    // reset boxes if hiding
    if (!show_max_min) {
      $(".form-field#minimum input[id$='_minimum']").val('');
      $(".form-field#minimum input[id$='_minstrictly']").prop('checked', false);
      $(".form-field#maximum input[id$='_maximum']").val('');
      $(".form-field#maximum input[id$='_maxstrictly']").prop('checked', false);
    }

    // show/hide key question
    const hide_key_q = (
      selected_type == 'image'
      || selected_type == 'annotated_image'
      || selected_type == 'signature'
      || selected_type == 'sketch'
      || selected_type == 'audio'
      || selected_type == 'video'
    );
    $('.question_fields .question_key').css('display', hide_key_q ? 'none' : 'flex');

    // reset boxes if hiding
    if (hide_key_q) {
      $(".form-field#key input[id$='_key']").val('');
      $(".form-field#key input[id$='_key']").prop('checked', false);
    }
  };

  klass.prototype.show_option_set_select = function (show, options) {
    const self = this;
    const select = $('div.question_fields .form-field[data-field-name=option_set_id]');
    select.css('display', show ? 'flex' : 'none');

    // If showing, disable the multilevel options based on options.multilevel.
    if (show) {
      const mult_options = select.find('.control select option[data-multilevel=true]');
      options.multilevel ? mult_options.removeAttr('disabled') : mult_options.attr('disabled', 'disabled');
    }

    // Reset value.
    if (!options.initial) select.find('.control select').val('');
  };

  // shows the create option set form and sets up a callback to receive the result
  klass.prototype.show_option_set_form = function () {
    const self = this;
    ELMO.app.loading(true);

    const question_type_param = `?adding_to_question_type=${self.field_value('qtype_name')}`;
    const loadUrl = self.params.new_option_set_path + question_type_param;

    const attribute_for_question_identifier = 'code'; // can be updated to 'name_{locale}' for title
    let modal_header = 'option_set.create_for_question';
    let question_identifier = $(`#question_${attribute_for_question_identifier}`).val();
    if (question_identifier == undefined) {
      question_identifier = $(`#questioning_question_attributes_${attribute_for_question_identifier}`).val();
    }
    let trimmed_question_identifier;
    if (question_identifier != undefined) {
      trimmed_question_identifier = question_identifier.trim();
    }
    if (trimmed_question_identifier == undefined || trimmed_question_identifier === '') {
      modal_header = 'option_set.create_for_new_question';
    }
    $('#create-option-set .modal-title').text(I18n.t(modal_header, { identifier: trimmed_question_identifier }));

    // populate and show the modal
    $('#create-option-set .modal-body.option-set').load(loadUrl, () => {
      $('#create-option-set').modal('show');
      ELMO.app.loading(false);
    });
  };

  // called when the option set is created so we can add it to the dropdown
  klass.prototype.option_set_created = function (option_set) {
    const self = this;
    // close the dialog
    $('#create-option-set').modal('hide');

    // add the new option set to the list and select it
    const option = $('<option>', { value: option_set.id, 'data-multilevel': option_set.multilevel }).text(option_set.name);
    $('div.question_fields .form-field#option_set_id select').append(option).val(option_set.id);

    // flash the option set row
    $('div.question_fields .form-field#option_set_id').effect('highlight', {}, 1000);
  };
}(ELMO.Views));
