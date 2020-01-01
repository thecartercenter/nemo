// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.AnswerMapView = class AnswerMapView extends ELMO.Views.ApplicationView {
  initialize(params) {
    if (typeof (google) === 'undefined') { return; }

    this.$el.show();

    // create the map
    this.map = new google.maps.Map(this.$el[0], {
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      disableDefaultUI: true,
      maxZoom: 11,
      zoomControl: true,
      zoomControlOptions: {
        position: google.maps.ControlPosition.TOP_RIGHT,
        style: google.maps.ZoomControlStyle.SMALL,
      },
    });

    // add a marker for each option and calculate bounds
    const bounds = new google.maps.LatLngBounds();
    for (const o of Array.from(params.options)) {
      const p = new google.maps.LatLng(o.latitude, o.longitude);
      const m = new google.maps.Marker({
        map: this.map,
        position: p,
        icon: params.small_marker_url,
      });
      bounds.extend(p);
    }

    // set the bounds
    return this.map.fitBounds(bounds);
  }
};
