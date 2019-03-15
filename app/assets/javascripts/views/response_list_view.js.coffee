# Handles polling for new responses.
class ELMO.Views.ResponseListView extends ELMO.Views.ApplicationView

  initialize: (options) ->
    setInterval(@fetch.bind(this), 10000)
    @batchView = ELMO.batch_actions_views.response

  fetch: ->
    @oldIds = @getIds()
    url = Utils.add_url_param(window.location.href, "auto=1")
    return unless @batchView

    @batchView.get_selected_items().each ->
      url = Utils.add_url_param(url, "sel[]=" + $(this).data('response-id'))
    if @batchView.select_all_pages_field.val()
      url = Utils.add_url_param(url, "select_all_pages=1")

    ELMO.app.loading(true)
    $.ajax({url: url, method: "get", success: @update.bind(this)})

  update: (data) ->
    ELMO.app.loading(false)
    $('#index_table').html(data)

    @batchView.update_select_all_elements()

    # Highlight any new rows.
    @getIds().forEach (id) =>
      @$("##{id}").effect("highlight", {}, 1000) if @oldIds.indexOf(id) == -1

  # Gets IDs of each row in index table
  getIds: ->
    ids = []
    @$('.index_table_body tr').each -> ids.push(this.id)
    ids
