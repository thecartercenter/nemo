/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// ELMO.Views.DashboardMapView
//
// View model for the dashboard map
ELMO.Views.DashboardMapView = class DashboardMapView extends ELMO.Views.ApplicationView {
  // constructor
  initialize(params) {
    this.params = params;
    this.disabled = params.offline;
    if (this.disabled) {
      this.show_disabled_notice();
    } else {
      this.setup_map();
    }
  }

  show_disabled_notice() {
    $('.map-canvas').remove();
    if (this.params.offline) {
      $('.response-locations-offline').show();
    } else if (!this.params.key_present) {
      $('.response-locations-no-key').show();
    }
  }

  setup_map() {
    // create the map
    this.map = new google.maps.Map($('.map-canvas')[0], {
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      // This default zoom level shows most of the world on a big screen, but avoids grey bars at top/bottom.
      zoom: 3,
      streetViewControl: false,
      draggableCursor: 'pointer',
    });

    // keep track of which response ids we've rendered
    this.distinct_answers = {};

    // add the markers and keep expanding the bounding rectangle
    const bounds = new google.maps.LatLngBounds();
    for (const l of Array.from(this.params.locations)) {
      const m = this.add_answer(l);
      if (m) { bounds.extend(m.position); }
    }

    // if there are stored bounds, use those to center map
    if (this.load_bounds(this.params.serialization_key)) {
      true; // do nothing since the method call does it all

    // else if there are no responses, just center at 0 0
    } else if (this.params.locations.length === 0) {
      this.map.setCenter(new google.maps.LatLng(0, 0));

    // else use bounds determined above
    } else {
      // Prevent map from zooming in too far when calling fitBounds.
      // Does this by handling the asynchronous zoom and bounds changed events.
      google.maps.event.addListener(this.map, 'zoom_changed', () => {
        let zoomChangeBoundsListener;
        return zoomChangeBoundsListener = google.maps.event.addListener(this.map, 'bounds_changed', (event) => {
          if ((this.map.getZoom() > 10) && this.map.initialZoom) {
            this.map.setZoom(10);
            this.map.initialZoom = false;
          }
          return google.maps.event.removeListener(zoomChangeBoundsListener);
        });
      });
      this.map.initialZoom = true;

      // center/zoom the map
      this.map.fitBounds(bounds);
    }

    // save map bounds each time they change
    return google.maps.event.addListener(this.map, 'bounds_changed', () => this.save_bounds(this.params.serialization_key));
  }

  add_answer(answer) {
    const [response_id, latitude, longitude] = Array.from(answer);

    // only add each response_id/lat/long once
    if (this.distinct_answers[answer]) { return; }

    // get float values from string
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    // create marker - Question: is this affected by removing markers from server?
    const p = new google.maps.LatLng(lat, lng);
    const m = new google.maps.Marker({
      map: this.map,
      position: p,
      title: `${I18n.t('activerecord.models.response.one')} #${response_id}`,
      icon: this.params.small_marker_url,
      r_id: response_id,
    });

    // setup event listener to show info window
    google.maps.event.addListener(m, 'click', () => this.show_info_window(m));

    // keep track of the response_id/lat/long
    this.distinct_answers[answer] = true;

    return m;
  }

  show_info_window(marker) { // Question: is this affected by removing marker controller and model?
    // close any existing window
    if (this.info_window) {
      this.info_window.close();
    }

    // open the window and show the loading message
    this.info_window = new google.maps.InfoWindow({
      content: `<div class="info-window"><h3>${I18n.t('response.loading')}</h3></div>`,
    });
    this.info_window.open(this.map, marker);

    // do the ajax call after the info window is loaded
    return google.maps.event.addListener(this.info_window, 'domready', () => {
      // load the response
      return $.ajax({
        url: this.params.info_window_url,
        method: 'get',
        data: { response_id: marker.r_id },
        success(data) {
          $('div.info-window').replaceWith(data);
        },
        error() {
          if (ELMO.unloading) return;
          $('div.info-window').html(I18n.t('layout.server_contact_error'));
        },
      });
    });
  }

  // stores the current map bounds in localStorage using the given key
  save_bounds(key) {
    // load and parse
    const saved_bounds = JSON.parse(window.localStorage.dashboardMapBounds || '{}');

    // add hash with center and zoom
    saved_bounds[key] = {
      center: [this.map.getCenter().lat(), this.map.getCenter().lng()],
      zoom: this.map.zoom,
    };

    // write out again
    return window.localStorage.dashboardMapBounds = JSON.stringify(saved_bounds);
  }

  // checks if there are bounds stored in localStorage for the given key
  peek_bounds(key) {
    return window.localStorage.dashboardMapBounds && JSON.parse(window.localStorage.dashboardMapBounds)[key];
  }

  // attempts to load the map bounds from localStorage using the given key
  // if successful, returns true
  // if not found, does nothing and returns false
  load_bounds(key) {
    let bounds;
    if (bounds = this.peek_bounds(key)) {
      this.map.setCenter(new google.maps.LatLng(bounds.center[0], bounds.center[1]));
      this.map.setZoom(bounds.zoom);
      return true;
    }

    return false;
  }

  update_map(data) {
    if (this.disabled) { return; }
    return Array.from(data).map((answer) => this.add_answer(answer));
  }

  center() {
    if (this.disabled) { return null; }
    return this.map.getCenter();
  }

  // Called after viewport is resized. If center is given, sets the new center for the map.
  resized(center) {
    if (this.disabled) { return; }
    google.maps.event.trigger(this.map, 'resize');
    if (center) { return this.map.setCenter(center); }
  }
};
