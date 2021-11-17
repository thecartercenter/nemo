// Handles getting info about bulk media thresholds
ELMO.Views.ExportCsvView = class ExportCsvView extends ELMO.Views.ApplicationView {
  get events() {
    return {
      'click #response_csv_export_options_download_media': 'calculateDownloadSize',
      'click #response_csv_export_options_download_xml': 'calculateDownloadSize'
    };
  }

  initialize() {
    $(".calculating-info").hide();
    this.hideInfo();
  }

  async calculateDownloadSize(event) {
    let downloadType = $(event.target)[0].name.includes("xml") ? "xml" : "media";
    if (($(event.target)).is(':checked')) {
      $("input[type=submit]").prop("disabled", true);
      await this.spaceLeft(downloadType);
      $("." + downloadType + "-info").show();
    } else {
      this.enableSubmitButton();
      $("." + downloadType + "-info").hide();
    }
  }

  hideInfo() {
    $(".media-info").hide();
    $(".xml-info").hide();
    $(".error-info").hide();
  }

  async spaceLeft(downloadType) {
    $(".calculating-info").show();

    // Read the hidden metadata that was copied earlier.
    let form = $('#new_response_csv_export_options');
    let checked = form.find('input.batch_op:hidden:checked');
    let selectAll = form.find('input[name=select_all_pages]').val();

    let selected = checked.map(function() {
      return $(this).data("response-id");
    }).get();

    return $.ajax({
      url: ELMO.app.url_builder.build("media-size"),
      method: "get",
      data: { selected, selectAll, download_type: downloadType },
      success: (data) => {
        $(".calculating-info").hide();
        $("#" + downloadType + "-size").html(data.download_size + " MB");

        if (data.space_on_disk) {
          this.enableSubmitButton();
        } else {
          $("#export-error").html(I18n.t("response.export_options.no_space"));
          $(".error-info").show();
        }
        return data;
      },
      error: (xhr, error) => {
        $("#export-error").html(I18n.t("response.export_options.try_again"));
      }
    });
  }

  enableSubmitButton() {
    // The submit button MAY be disabled by other factors; prevent enabling it if so.
    let tooManyResponses = $('#export-count-error').is(':visible');
    if (!tooManyResponses) {
      $("input[type=submit]").removeAttr("disabled");
    }
  }
};
