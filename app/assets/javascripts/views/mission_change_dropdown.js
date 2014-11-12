// ELMO.Views.MissionChangeDropdown
(function(ns, klass) {

  // constructor
  ns.MissionChangeDropdown = klass = function(params) {
    $(params.el).on('change', function(e){
      var new_mission_name = $(e.currentTarget).find('option:selected').val();
      if (new_mission_name == '') {
        // Redirect straight to root if chose 'None' from dropdown.
        window.location.href = ELMO.app.url_builder.build('/', {mode: 'basic'}) + '?missionchange=1';
      } else {
        // If currently in basic mode, we automatically redirect to mission root.
        // This is because it doesn't currently make sense to use a path from basic mode in mission mode,
        // whereas sharing paths between missions or mission<->admin can make sense.
        var path = ELMO.app.params.mode == 'basic' ? '' : window.location.pathname;

        // Preserve query string and add missionchange param to it.
        var qs = window.location.search;
        qs += (qs == '' ? '?' : '&') + 'missionchange=1';

        window.location.href = ELMO.app.url_builder.build(path, {mode: 'mission', mission_name: new_mission_name}) + qs;
      }
    });
  };

})(ELMO.Views);
