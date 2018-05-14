// ELMO.Views.QuestionForm
//
// View model for User form
(function(ns, klass) {

  // constructor
  ns.UserForm = klass = function(params) { var self = this;
    self.params = params || {};

    // build assignment form if params provided
    if (self.params.assignable_missions)
      self.build_assignment_form();

    // hookup add assignment link
    $('.form-field[data-field-name=assignments] .add_assignment').on('click', function(e){
      self.add_assignment();
      e.preventDefault();
    })

    // hookup delete assignment links
    $('.form-field[data-field-name=assignments]').on('click', '.delete_assignment', function(e){
      self.delete_assignment($(e.target).closest('.assignment'));
      e.preventDefault();
    })

    function togglePasswordFields() {
      var option = $(this).val()
      $('.password-fields').toggleClass('hide', option !== 'enter')
    }

    var passwordSelect = $('#user_reset_password_method')
    passwordSelect.on('change', togglePasswordFields)
    togglePasswordFields.call(passwordSelect)
  }

  klass.prototype.build_assignment_form = function() { var self = this;
    var template = JST['legacy/templates/assignment_miniform'];

    // loop over assignments, adding rows
    self.params.assignments.forEach(function(assignment, idx) {
      $('.form-field[data-field-name=assignments] .assignments').append(template({
        params: self.params,
        assignment: assignment,
        can_update: self.params.form_mode != 'show' && self.params.assignment_permissions[idx],
        new_record: assignment['new_record?'],
        idx: idx
      }));
    });
  }

  klass.prototype.add_assignment = function() { var self = this;
    var template = JST['legacy/templates/assignment_miniform'];

    $('.form-field[data-field-name=assignments] .assignments').append(template({
      params: self.params,
      assignment: {},
      can_update: true,
      new_record: true,
      idx: $('.form-field[data-field-name=assignments] .assignments .assignment').length
    }));
  }

  klass.prototype.delete_assignment = function(row) { var self = this;
    // if row is a new record, delete it entirely
    if (row.is('.new_record'))
      row.remove();

    // else hide it and set destroy flag
    else {
      row.hide();
      row.find('.destroy_flag').val('1');
    }
  }

}(ELMO.Views));
