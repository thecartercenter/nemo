(function (ApiUserList, undefined) {

  ApiUserList.hookup_protected_change_event = function() {

   $("#form_access_level").change(function(){
    if ($(this).val() == "3") {
      $("#api-users").show();
    } else {
      $("#api-users").hide();
    }
   });
  }
}(ApiUserList = {}));