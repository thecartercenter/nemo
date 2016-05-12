// ELMO.Views.ApiUserList
//
// View model for ApiUserList form
(function(ns, klass) {

  // constructor
  ns.ApiUserListView = klass = function(params) { var self = this;
    self.params = params;
    // set up initial view
    self.showUserList();
    // setup change handler for dropdown
    $("#form_access_level").change(function(){
      self.showUserList();
    });

  }

  klass.prototype.showUserList = function() { var self = this;
    if ($("#form_access_level").val() == "protected") {
      $("#api-users").show();
    } else {
      $("#api-users").hide();
    }
  }

}(ELMO.Views));
