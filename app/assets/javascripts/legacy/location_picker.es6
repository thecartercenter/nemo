// ELMO.LocationPicker
(function (ns, klass) {
  // constructor
  ns.LocationPicker = klass = function (el) {
    const self = this;
    self.el = el;
    self.el.on('shown.bs.modal', (e) => { self.initialize_map(); });
    self.map_ready = false;
  };

  klass.prototype.show = function (field) {
    const self = this;
    self.el.modal('show');
    self.location_field = field;

    if (self.location_field.val()) self.set_location(self.parse_lat_lng(self.location_field.val()));

    if (self.map_ready) self.mark_location({ pan: true });
  };

  // Fires only on first show.
  klass.prototype.initialize_map = function () {
    const self = this;
    if (!self.location) self.set_location([-34.397, 150.644]); // Default center

    self.map = new google.maps.Map(self.el.find('.map-canvas')[0], {
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      zoom: self.location ? 7 : 2,
      streetViewControl: false,
      draggableCursor: 'pointer',
      center: new google.maps.LatLng(self.location[0], self.location[1]),
    });

    self.mark_location();
    self.search_focus(false);

    // Hook up events.
    google.maps.event.addListener(self.map, 'click', (event) => { self.map_click(event); });
    self.el.find('button.btn-primary').click(() => { self.close(true); return false; });
    self.el.find('form.location-search input.query').focus(() => { self.search_focus(true); });
    self.el.find('form.location-search input.query').blur(() => { self.search_focus(false); });
    self.el.find('form.location-search').submit(() => { self.search_submit(); return false; });

    self.map_ready = true;
  };

  // get float values for lat ang lng from a string
  klass.prototype.parse_lat_lng = function (str) {
    const m = str.match(ELMO.LAT_LNG_REGEXP);
    return m && m[1] && m[3] ? [parseFloat(m[1]), parseFloat(m[3])] : null;
  };

  // handles a click event on the map
  klass.prototype.map_click = function (event) {
    const self = this;
    self.set_location([event.latLng.lat(), event.latLng.lng()]);
    self.mark_location();
  };

  klass.prototype.search_focus = function (is_focus) {
    const self = this;
    console.log(self.el);
    // get ref.
    const box = self.el.find('form.location-search input.query');
    const init_str = I18n.t('location_picker.search_locations');

    // if focused, blank the box and set the color and font style
    if (is_focus && box.val() == init_str) box.css('color', '#222').css('font-style', 'normal').val('');

    // otherwise (blur), reset the box to the blank style using the boilerplate code
    else if (box.val().trim() == '') box.css('color', '#888').css('font-style', 'italic').val(init_str);
  };

  // submits the search to the google geocoder class
  klass.prototype.search_submit = function () {
    const self = this;

    // get query
    const query = self.el.find('form.location-search input.query').val().trim();

    // do nothing if empty
    if (query == '') return;

    ELMO.app.loading(true);

    (new google.maps.Geocoder()).geocode({ address: query }, (results, status) => {
      ELMO.app.loading(false);
      const results_div = self.el.find('form.location-search div.results').empty();
      if (status == 'OK') {
        // create links
        for (let i = 0; i < results.length; i++) {
          results_div.append($('<a>')
            .attr('href', '#').addClass('result-link')
            .attr('title', `${results[i].geometry.location.lat()}, ${results[i].geometry.location.lng()}`)
            .text(results[i].formatted_address));
        }

        self.el.find('a.result-link').click((e) => {
          e.preventDefault();
          self.set_location(self.parse_lat_lng(e.target.title));
          self.mark_location({ pan: true });
        });
      } else {
        alert('Search Error');
      }
    });
  };

  klass.prototype.set_location = function (val) {
    const self = this;
    self.location = [val[0].toFixed(6), val[1].toFixed(6)];
  };

  // updates the map to indicate that the current location has been chosen
  klass.prototype.mark_location = function (options) {
    const self = this;
    ELMO.app.loading(false);

    if (self.location) {
      if (!self.marker) self.marker = new google.maps.Marker({ map: self.map });

      // move the marker
      self.marker.setPosition(new google.maps.LatLng(self.location[0], self.location[1]));
    }

    // show the chosen location
    self.el.find('.cur-lat-lng').html(`${I18n.t('location_picker.current_location')}: ${
      self.location ? `${self.location[0]} ${self.location[1]}` : 'None'}`);

    // pan if requested
    if (options && options.pan) self.map.panTo(self.marker.getPosition());
  };

  // closes the window, optionally saving the chosen location in the location field
  klass.prototype.close = function (save) {
    const self = this;
    // copy the value if requested
    if (save) self.location_field.val(`${self.location[0]} ${self.location[1]}`);

    self.el.modal('hide');
  };
}(ELMO));
