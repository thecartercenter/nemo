// ELMO.Views.QuestionForm
//
// View model for User form
(function(ns, klass) {
  // constructor
  ns.UserForm = klass = function(params) { var self = this;
    self.params = params || {};

    const togglePasswordFields = function() {
      const option = $(this).val();
      $(".password-fields").toggleClass("hide", (option !== "enter" && option !== "enter_and_show"));
    };

    const passwordSelect = $("#user_reset_password_method");
    passwordSelect.on("change", togglePasswordFields);
    togglePasswordFields.call(passwordSelect);
  }

}(ELMO.Views));
