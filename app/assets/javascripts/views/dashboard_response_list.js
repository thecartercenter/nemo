ELMO.Views.DashboardResponseList = class DashboardResponseList extends ELMO.Views.ApplicationView {
  // gets the ID of the latest response in the list, or empty string if no responses
  latestResponseId() {
    const domId = $('.recent-responses tbody tr:first-child').attr('id');
    return domId ? domId.replace(/^response_/, '') : '';
  }

  // highlights all responses after (higher in the list than) the response with the given id
  // id may be null, in which case we do nothing
  highlightResponsesAfter(id) {
    if (id) {
      let soundPlayed = false;

      // loop through the response rows, highlighting, until we reach the one with the given ID
      // also play a sound if we find a new response
      $('.recent-responses tbody tr').each((idx, tr) => {
        if (tr.id === `response_${id}`) {
          return false;
        }
        $(tr).effect('highlight', {}, 4000);

        if (!soundPlayed) {
          $('#new-arrival-sound')[0].play();
          soundPlayed = true;
        }
        return true;
      });
    }
  }
};
