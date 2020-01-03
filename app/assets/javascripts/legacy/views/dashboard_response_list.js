// ELMO.Views.DashboardResponseList
//
// View model for the Dashboard response listing
(function (ns, klass) {
  // horizontal cell padding
  const CELL_H_PADDING = 13;

  // constructor
  ns.DashboardResponseList = klass = function () {
    const self = this;
  };

  // adjusts column widths depending on how many there are
  klass.prototype.adjust_columns = function () {
    const self = this;
    // reviewed column gets fixed width
    const small_w = 75;

    // the rest are computed based on size of pane and number of cols
    const num_cols = $('.recent_responses tbody tr:first-child td').length;
    const pane_w = $('.recent_responses').width();

    // this is a guess. we set overflow-x to hidden just in case it's a bit off
    const scrollbar_w = 12;

    // first set all of them to the wider width, also allow for scrollbar
    set_col_width((pane_w - small_w) / (num_cols - 1) - scrollbar_w);

    // then set the two smaller ones
    set_col_width(small_w, '.reviewed_col');
  };

  // gets the ID of the latest response in the list, or empty string if no responses
  klass.prototype.latest_response_id = function (args) {
    const self = this;
    const dom_id = $('.recent_responses tbody tr:first-child').attr('id');
    return dom_id ? dom_id.replace(/^response_/, '') : '';
  };

  // highlights all responses after (higher in the list than) the response with the given id
  // id may be null, in which case we do nothing
  klass.prototype.highlight_responses_after = function (id) {
    const self = this;
    if (id) {
      let sound_played = false;

      // loop through the response rows, highlighting, until we reach the one with the given ID
      // also play a sound if we find a new response
      $('.recent_responses tbody tr').each(function () {
        if (this.id == `response_${id}`) return false;
        $(this).effect('highlight', {}, 4000);

        if (!sound_played) {
          $('#new_arrival_sound')[0].play();
          sound_played = true;
        }
      });
    }
  };

  // sets the width of the table columns. if cls is given, it's added as a suffix to the td selector.
  function set_col_width(width, cls) {
    const self = this;
    if (!cls) cls = '';

    $(`.recent_responses td${cls}`).width(width);

    // set inner divs to small width due to padding
    // we use an inner div to handle overflow and prevent wrapping
    $(`.recent_responses td${cls} > div`).width(width - CELL_H_PADDING);
  }
}(ELMO.Views));
