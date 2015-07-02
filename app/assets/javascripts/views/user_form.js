// ELMO.Views.QuestionForm
//
// View model for User form
(function(ns, klass) {

  // constructor
  ns.UserForm = klass = function(params) { var self = this;
    self.params = params || {};

    // hookup suggest login button
    $('form.user_form .form_field[data-field-name=login] .control button').on('click', function(e) {
      e.preventDefault();
      self.suggest_login();
    });

    // build assignment form if params provided
    if (self.params.assignable_missions)
      self.build_assignment_form();

    // hookup add assignment link
    $('.form_field[data-field-name=assignments] .add_assignment').on('click', function(e){
      self.add_assignment();
      e.preventDefault();
    })

    // hookup delete assignment links
    $('.form_field[data-field-name=assignments]').on('click', '.delete_assignment', function(e){
      self.delete_assignment($(e.target).closest('.assignment'));
      e.preventDefault();
    })

  }

  klass.prototype.suggest_login = function() { var self = this;
    // get user name
    var name = $('#user_name').val();

    var m, login;

    // if it looks like a person's name, suggest f. initial + l. name
    if (m = name.match(/^([a-z][a-z']+) ([a-z'\- ]+)$/i))
      login = m[1].substr(0,1) + m[2].replace(/[^a-z]/ig, "");
    // otherwise just use the whole thing and strip out weird chars
    else
      login = name.replace(/[^a-z0-9\.]/ig, "");

    // truncate to 10 chars and set as field value
    $('#user_login').val(login.substr(0,10).toLowerCase());
  }

  klass.prototype.build_assignment_form = function() { var self = this;
    var template = JST['templates/assignment_miniform'];

    // loop over assignments, adding rows
    self.params.assignments.forEach(function(assignment, idx) {
      $('.form_field[data-field-name=assignments] .assignments').append(template({
        params: self.params,
        assignment: assignment,
        can_update: self.params.form_mode != 'show' && self.params.assignment_permissions[idx],
        new_record: assignment['new_record?'],
        idx: idx
      }));
    });
  }

  klass.prototype.add_assignment = function() { var self = this;
    var template = JST['templates/assignment_miniform'];

    $('.form_field[data-field-name=assignments] .assignments').append(template({
      params: self.params,
      assignment: {},
      can_update: true,
      new_record: true,
      idx: $('.form_field[data-field-name=assignments] .assignments .assignment').length
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