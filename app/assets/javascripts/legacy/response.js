(function (ns, klass) {

  ns.Response = klass = {}

  klass.init = function(options) {
    // hookup edit location links
    $("a.edit_location_link").click(function(e){ klass.show_location_picker(e); return false; });

    // enable select2 for user selector
    $('#response_user_id').select2({
      ajax: {
        url: options.submitter_url,
        dataType: 'json',
        delay: 250,
        data: function (params) {
          return {
            search: params.term,
            page: params.page
          };
        },
        processResults: function (data, page) {
          return {
            results: data.possible_users,
            pagination: { more: data.more }
          };
        },
        cache: true
      }
    });

    $('#response_reviewer_id').select2({
      ajax: {
        url: options.reviewer_url,
        dataType: 'json',
        delay: 250,
        data: function (params) {
          return {
            search: params.term,
            page: params.page
          };
        },
        processResults: function (data, page) {
          return {
            results: data.possible_users,
            pagination: { more: data.more }
          };
        },
        cache: true
      }
    });
  }

  klass.build_select2_params = function(url) {
    /*TODO refactor to share between reviewer and submitter*/
  }

  // shows the map and location search box
  klass.show_location_picker = function(event) {
    // store existing gps if any
    var location_box = $(event.target).parents("div.control").find("input.qtype_location")[0];
    // create and intialize location picker dialog
    new ELMO.LocationPicker(location_box);
    $('#location-picker-modal').modal('show');

  }

}(ELMO));
