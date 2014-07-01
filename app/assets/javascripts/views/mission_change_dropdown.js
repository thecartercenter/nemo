// ELMO.Views.MissionChangeDropdown
(function(ns, klass) {

  // constructor
  ns.MissionChangeDropdown = klass = function(params) {
    $(params.el).on('change', function(e){
      var new_mission_name = $(e.target).find('option:selected').val();
      if (new_mission_name == '')
        window.location.href = ELMO.app.url_builder.build('/', {mode: 'basic'});
      else
        window.location.href = ELMO.app.url_builder.build(window.location.pathname, {mode: 'mission', mission_name: new_mission_name});
    });
  };

})(ELMO.Views);