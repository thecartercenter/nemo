ELMO.Views.AnswerMapView = class AnswerMapView extends ELMO.Views.ApplicationView {
  initialize(params) {
    if (typeof (google) === 'undefined') { return; }

    this.$el.show();

    // create the map
    this.map = new google.maps.Map(this.$el[0], {
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      disableDefaultUI: true,
      maxZoom: 9, // The maps are so small that we can lose context if zooming too close.
      zoomControl: false
    });

    // add a marker for each option and calculate bounds
    const bounds = new google.maps.LatLngBounds();
    params.points.forEach((point) => {
      const latlng = new google.maps.LatLng(point.latitude, point.longitude);
      const marker = new google.maps.Marker({ map: this.map, position: latlng, icon: params.markerUrl });
      bounds.extend(latlng);
    });

    this.map.fitBounds(bounds);
  }
};
