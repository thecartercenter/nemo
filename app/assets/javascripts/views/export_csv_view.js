// Handles getting info about bulk media thresholds
ELMO.Views.ExportCsvView = class ExportCsvView extends ELMO.Views.ApplicationView {
  get events() {
    return {
      'click #response_csv_export_options_download_media': 'calculateMediaSize'
    };
  }

  initialize(params) {
    $(".calculating-info").hide();
    $(".error-info").hide();
    $(".media-info").hide();
  }

  calculateMediaSize(event) {
    if (($(event.target)).is(':checked')) {
      $("input[type=submit]").prop("disabled", true);
      this.spaceLeft();
      $(".media-info").show();

    } else {
      $("input[type=submit]").removeAttr("disabled");
      $(".media-info").hide();
      $(".error-info").hide();
    }
  }

  spaceLeft() {
    $(".calculating-info").show();

    $.ajax({
      url: ELMO.app.url_builder.build("media-size"),
      method: "get",
      data: "",
      success: (data) => {
        $(".calculating-info").hide();
        $("#media-size").html(data.media_size + " MB");

        if (data.space_on_disk) {
          $("input[type=submit]").removeAttr("disabled");

        } else {
          $(".error-info").show();
        }
        return data;
      }
    });
  }
};
