# ELMO.Views.DashboardMapView
#
# View model for the dashboard map
class ELMO.Views.DashboardMapView extends ELMO.Views.ApplicationView

  # constructor
  initialize: (params) ->
    @params = params

    # create the map
    @map = new google.maps.Map($('div.response_locations')[0], {
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      zoom: 1,
      streetViewControl: false,
      draggableCursor: 'pointer'
    })

    # keep track of which response ids we've rendered
    @distinct_answers = {}

    # add the markers and keep expanding the bounding rectangle
    bounds = new google.maps.LatLngBounds()
    for l in @params.locations
      m = this.add_answer(l)
      bounds.extend(m.position) if m

    # if there are stored bounds, use those to center map
    if this.load_bounds(@params.serialization_key)
      ; # do nothing since the method call does it all

    # else if there are no responses, just center at 0 0
    else if @params.locations.length == 0
      @map.setCenter(new google.maps.LatLng(0, 0))

    # else use bounds determined above
    else
      # center/zoom the map
      @map.fitBounds(bounds)

    # save map bounds each time they change
    google.maps.event.addListener(@map, 'bounds_changed', => this.save_bounds(@params.serialization_key))

  add_answer: (answer) ->
    [response_id, latitude, longitude] = answer

    # only add each response_id/lat/long once
    return if @distinct_answers[answer]

    # get float values from string
    lat = parseFloat(latitude)
    lng = parseFloat(longitude)

    # create marker
    p = new google.maps.LatLng(lat, lng)
    m = new google.maps.Marker({
      map: @map,
      position: p,
      title: I18n.t('activerecord.models.response.one') + ' #' + response_id,
      icon: @params.small_marker_url,
      r_id: response_id
    })

    # setup event listener to show info window
    google.maps.event.addListener(m, 'click', => this.show_info_window(m))

    # keep track of the response_id/lat/long
    @distinct_answers[answer] = true

    return m

  show_info_window: (marker) ->
    # close any existing window
    if @info_window
      @info_window.close()

    # open the window and show the loading message
    @info_window = new google.maps.InfoWindow({content: '<div class="info_window"><h3>' + I18n.t('response.loading') + '</h3></div>'})
    @info_window.open(@map, marker)

    # do the ajax call after the info window is loaded
    google.maps.event.addListener(@info_window, 'domready', =>
      # load the response
      $.ajax({
        url: @params.info_window_url,
        method: 'get',
        data: {response_id: marker.r_id},
        success: (data) -> $('div.info_window').replaceWith(data),
        error: -> $('div.info_window').html(I18n.t('layout.server_contact_error'))
      })
    )

  # stores the current map bounds in localStorage using the given key
  save_bounds: (key) ->
    # load and parse
    saved_bounds = JSON.parse(window.localStorage.dashboardMapBounds || '{}')

    # add hash with center and zoom
    saved_bounds[key] = {
      center: [@map.getCenter().lat(), @map.getCenter().lng()],
      zoom: @map.zoom
    }

    # write out again
    window.localStorage.dashboardMapBounds = JSON.stringify(saved_bounds)

  # checks if there are bounds stored in localStorage for the given key
  peek_bounds: (key) ->
    return window.localStorage.dashboardMapBounds && JSON.parse(window.localStorage.dashboardMapBounds)[key]

  # attempts to load the map bounds from localStorage using the given key
  # if successful, returns true
  # if not found, does nothing and returns false
  load_bounds: (key) ->
    if bounds = this.peek_bounds(key)
      @map.setCenter(new google.maps.LatLng(bounds.center[0], bounds.center[1]))
      @map.setZoom(bounds.zoom)
      return true

    return false

  update_map: (data) ->
    this.add_answer(answer) for answer in data.answers
    # TODO: Deal with data.count
