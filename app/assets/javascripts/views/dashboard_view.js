const MAX_RELOAD_COUNT = 120;

ELMO.Views.DashboardView = class DashboardView extends ELMO.Views.ApplicationView {
  get el() { return 'body.dashboard'; }

  get events() {
    return {
      'click a.full-screen': 'handleFullScreen',
      'click a.toggle-map': 'handleExpandMap',
      'report:loading': 'handleReportLoading',
      'report:load': 'handleReportLoad',
      'click a.reload-ajax': 'reloadAjax', // For testing
    };
  }

  initialize(params) {
    this.params = params;
    this.reloadCount = 0;
    this.resetReloadTimer();
    this.params.map.serialization_key = this.params.mission_id;
    this.listView = new ELMO.Views.DashboardResponseList();
    this.mapView = new ELMO.Views.DashboardMapView(this.params.map);
    this.dashboardReport = new ELMO.Views.DashboardReportView();
  }

  handleFullScreen(e) {
    e.preventDefault();
    this.setFullScreen('toggle');
  }

  handleExpandMap(e) {
    e.preventDefault();
    this.setExpandedMap('toggle');
  }

  handleReportLoading() {
    // We don't want to reload the dashboard while the report is loading.
    // Once it's finished we'll start a new timer.
    this.cancelReloadTimer();

    // We also don't want to allow a slow-running report generation during a reload to override
    // a freshly requested report in the report view.
    this.cancelReload();
  }

  handleReportLoad() {
    this.resetReloadTimer();
  }

  resetReloadTimer() {
    this.cancelReloadTimer();
    this.reloadTimer = setTimeout(this.reloadAjax.bind(this), this.params.reloadInterval * 1000);
  }

  cancelReloadTimer() {
    if (this.reloadTimer) {
      clearTimeout(this.reloadTimer);
    }
  }

  reloadAjax() {
    this.reloadCount += 1;
    if (this.reloadCount > MAX_RELOAD_COUNT) {
      this.reloadPage();
    }

    if (!this.dashboardReport.isEmpty()) {
      this.dashboardReport.toggleLoader(true);
    }

    // We only set the 'auto' parameter on this request if NOT in full screen mode.
    // The auto param prevents the AJAX request from resetting the auto-logout timer.
    // The dashboard in full screen mode is meant to be a long-running page so doesn't make
    // sense to let the session expire.
    const auto = this.viewSetting('full-screen') ? undefined : 1;

    this.reloadRequest = $.ajax({
      url: ELMO.app.url_builder.build('/'),
      method: 'GET',
      data: {
        latest_response_id: this.listView.latestResponseId(),
        auto,
      },
      success: this.handleReloadSuccess.bind(this),
    });
  }

  handleReloadSuccess(data) {
    $('.recent-responses').html(data.recent_responses);
    $('.stats').html(data.stats);
    $('.report-content').html(data.report_content);
    this.dashboardReport.toggleLoader(false);
    this.mapView.update_map(data.response_locations);
    this.resetReloadTimer();
    this.reloadRequest = null;
  }

  cancelReload() {
    if (this.reloadRequest) {
      this.reloadRequest.abort();
    }
  }

  // Reloads the page via full refresh to avoid memory issues.
  reloadPage() {
    this.dashboardReport.showLoader();
    const nonce = Math.floor(Math.random() * 1000000 + 1);
    window.location.href = `${ELMO.app.url_builder.build('')}?r=${nonce}`;
  }

  // Enables/disables full screen mode. Uses stored setting if no param given.
  // Toggles setting if 'toggle' given.
  setFullScreen(value) {
    const full = this.viewSetting('full-screen', value);

    if (full) {
      $('#footer').hide();
      $('#main-nav').hide();
      $('#userinfo').hide();
      $('#logo img').css('height', '30px');
      $('a.full-screen i').removeClass('fa-expand').addClass('fa-compress');

    // No need to unset things if toggle not given since it's only called that way on page load
    // and the default is to hide.
    } else if (value === 'toggle') {
      $('#footer').show();
      $('#main-nav').show();
      $('#userinfo').show();
      $('#logo img').css('height', '54px'); // initial does weird stuff on first load with oversized logo
      $('a.full-screen i').removeClass('fa-compress').addClass('fa-expand');
    }

    // Set link text
    $('a.full-screen span').text(I18n.t(`dashboard.${full ? 'exit' : 'enter'}_full_screen`));
  }

  // Enables/disables expanded map. Uses stored setting if no param given.
  // Toggles setting if 'toggle' given.
  // Always enables full screen if expanding map.
  // When collapsing map, disables full screen if it wasn't on when map was expanded.
  setExpandedMap(value) {
    const expand = this.viewSetting('expanded-map', value);

    if (expand) {
      const wasFull = this.viewSetting('full-screen');
      this.viewSetting('screen-full-before-map-expand', wasFull);
      this.setFullScreen(true);

      $('#content').addClass('expanded-map');

    // No need to unset things if toggle not given since it's only called that way on page load
    // and the default is to hide.
    } else if (value === 'toggle') {
      const wasFull = this.viewSetting('screen-full-before-map-expand');
      if (!wasFull) this.setFullScreen(false);

      $('#content').removeClass('expanded-map');
    }
  }

  viewSetting(settingName, value) {
    let bool = JSON.parse(localStorage.getItem(settingName));

    // Return unchanged if no value given.
    if (typeof value === 'undefined') return bool;

    // Toggle if requested.
    else if (value === 'toggle') bool = !bool;

    // Else set directly.
    else bool = value;

    localStorage.setItem(settingName, bool);
    return bool;
  }
};
