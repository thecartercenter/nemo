class ELMO.Views.ResponseFormView extends ELMO.Views.ApplicationView

  initialize: (params) ->
    # Select2's for user and reviewer
    @$('#response_user_id').select2(@select2Params(params.submitter_url))
    @$('#response_reviewer_id').select2(@select2Params(params.reviewer_url))

    @locationPicker = new ELMO.LocationPicker(@$('#location-picker-modal'));

  events:
    'click a.edit_location_link': 'showLocationPicker'

  select2Params: (url) ->
    ajax:
      url: url
      dataType: 'json'
      delay: 250,
      data: (p) ->
        search: p.term
        page: p.page
      processResults: (data, page) ->
        results: data.possible_users
        pagination: { more: data.more }
      cache: true

  showLocationPicker: (e) ->
    field = @$(e.target).parents('div.control').find('input.qtype_location')
    @locationPicker.show(field)
