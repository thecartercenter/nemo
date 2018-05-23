class ELMO.Views.AnswerMapView extends ELMO.Views.ApplicationView

  initialize: (params) ->
    return if typeof(google) == 'undefined'

    this.$el.show()

    # create the map
    @map = new google.maps.Map(this.$el[0], {
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      disableDefaultUI: true,
      maxZoom: 11,
      zoomControl: true,
      zoomControlOptions: {
        position: google.maps.ControlPosition.TOP_RIGHT,
        style: google.maps.ZoomControlStyle.SMALL
      }
    })

    # add a marker for each option and calculate bounds - Question: is this affected by removing markers from server?
    bounds = new google.maps.LatLngBounds()
    for o in params.options
      p = new google.maps.LatLng(o.latitude, o.longitude)
      m = new google.maps.Marker({
        map: @map,
        position: p,
        icon: params.small_marker_url
      })
      bounds.extend(p)

    # set the bounds
    @map.fitBounds(bounds)
