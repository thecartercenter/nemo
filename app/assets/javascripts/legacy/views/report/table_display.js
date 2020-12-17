// ELMO.Report.TableDisplay < ELMO.Report.Display
(function (ns, klass) {
  // constructor
  ns.TableDisplay = klass = function (report) {
    this.report = report;
  };

  // inherit
  klass.prototype = new ns.Display();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Display.prototype;

  klass.prototype.show_totals = function (row_or_col) {
    // show totals if the opposite header is defined
    return this.report.attribs.type.match(/TallyReport/) && this.report.attribs.headers[row_or_col == 'row' ? 'col' : 'row'].title;
  };

  // formats a given fraction as a percentage
  klass.prototype.format_percent = function (frac) {
    return `${(frac * 100).toFixed(1)}%`;
  };

  klass.prototype.render = function () {
    const _this = this;
    const { data } = this.report.attribs;
    const { headers } = this.report.attribs;
    const tbl = this.tbl = $('<table>');

    // column label row
    if (headers.col && headers.col.title) {
      var trow = $('<tr>');

      // blank cells for row grouping label and row header, if necessary
      if (headers.row) {
        if (headers.row.title) $('<th>').appendTo(trow);
        $('<th>').appendTo(trow);
      }

      // col grouping label
      $('<th>').addClass('col_grouping_label').attr('colspan', headers.col.cells.length).text(headers.col.title)
        .appendTo(trow);

      // row total cell
      if (_this.show_totals('row')) $('<th>').appendTo(trow);

      tbl.append(trow);
    }

    // header row
    // we need a header row if there are any col headers or if there is more than one row
    if (headers.col || headers.row && headers.row.cells.length > 1) {
      var trow = $('<tr>');

      // blank cells for row grouping label and row header, if necessary
      if (headers.row) {
        if (headers.row.title) $('<th>').appendTo(trow);
        $('<th>').appendTo(trow);
      }

      // rest of header cells
      if (headers.col) {
        $(headers.col.cells).each((idx, ch) => {
          $('<th>').addClass('col').html(ch.name || `[${I18n.t('report/report.blank')}]`).appendTo(trow);
        });
      }

      // row total header
      if (_this.show_totals('row')) $('<th>').addClass('row_total').text(I18n.t('common.total')).appendTo(trow);

      tbl.append(trow);
    }

    // create (but don't insert yet) the row grouping label
    let row_grouping_label;
    if (headers.row && headers.row.title) {
      const txt = headers.row.title.replace(/\s+/g, '<br/>');
      row_grouping_label = $('<th>').addClass('row_grouping_label').attr('rowspan', headers.row.cells.length);
      row_grouping_label.append($('<div>').html(txt));
    }

    // body
    $(data.rows).each((r, data_row) => {
      trow = $('<tr>');

      // add the row grouping label if it is defined (also delete it so it doesn't get added again)
      if (row_grouping_label) {
        trow.append(row_grouping_label);
        row_grouping_label = null;
      }

      // row header
      if (headers.row) $('<th>').addClass('row').html(headers.row.cells[r].name || `[${I18n.t('report/report.blank')}]`).appendTo(trow);

      // row cells
      $(data_row).each((c, cell) => {
        // get cell type
        const typ = typeof (cell);

        // get cell value
        let val = cell;
        if (val == null) val = '';

        // calculate percentage if necessary
        if (val != '' && _this.report.attribs.percent_type != 'none') {
          switch (_this.report.attribs.percent_type) {
            case 'overall': val /= data.totals.grand; break;
            case 'by_row': val /= data.totals.row[r]; break;
            case 'by_col': val /= data.totals.col[c]; break;
          }
          val = _this.format_percent(val);
        }
        $('<td>').html(val).addClass(typ).appendTo(trow);
      });

      // row total
      if (_this.show_totals('row')) {
        let val = data.totals.row[r];

        // don't display 0s
        if (val == 0) val = '';

        // calculate percentage if necessary
        if (_this.report.attribs.percent_type != 'none' && val != '') val = _this.format_percent(val / data.totals.grand);

        // add the cell
        $('<td>').addClass('row_total').text(val).addClass('number')
          .appendTo(trow);
      }

      tbl.append(trow);
    });

    // footer
    if (_this.show_totals('col')) {
      trow = $('<tr>');

      // blank cells for row grouping label, if necessary
      if (headers.row && headers.row.title) { $('<th>').appendTo(trow); }

      // row header
      if (headers.row) {
        $('<th>').addClass('row').addClass('col_total').text(I18n.t('common.total'))
          .appendTo(trow);
      }

      // row cells
      $(data.totals.col).each((c, ct) => {
        let val = ct;

        // don't display 0s
        if (val == 0) val = '';

        // calculate percentage if necessary
        if (_this.report.attribs.percent_type != 'none' && val != '') val = _this.format_percent(val / data.totals.grand);

        // add cell
        $('<td>').addClass('col_total').text(val).addClass('number')
          .appendTo(trow);
      });

      // grand total
      if (_this.show_totals('row')) {
        let val = (gt = data.totals.grand) > 0 ? gt : '';

        // calculate percentage if necessary
        if (_this.report.attribs.percent_type != 'none' && val != '') val = _this.format_percent(1);

        $('<td>').addClass('row_total').addClass('col_total').text(val)
          .addClass('number')
          .appendTo(trow);
      }

      tbl.append(trow);
    }

    // add a row count
    $('.report-info').append($('<div>').attr('id', 'row_count')
      .text(this.i18n_total_rows_label(data)));

    // add the table
    $('.report-body').empty().append(tbl);

    this.equalize_col_widths();
  };

  klass.prototype.equalize_col_widths = function () {
    // get the available extra space
    const extra_spc = $('.report-body').position().left + $('.report-body').width() - this.tbl.position().left - this.tbl.width();

    // get the current column widths
    const cur_widths = [];
    this.tbl.find('th.col').each(function () { cur_widths.push($(this).width()); });

    // bail if no find columns
    if (cur_widths.length == 0) return;

    // get largest current
    const largest_current = Math.max.apply(null, cur_widths);

    // get sum of current column widths
    let cur_sum = 0;
    $.each(cur_widths, function () { cur_sum += this; });

    // get the largest allowable column width
    const largest_allowable = (cur_sum + extra_spc) / cur_widths.length;

    // optimal column width is min(largest current, largest allowable)
    const optimal = Math.min(largest_current, largest_allowable) + 1;

    // set widths
    this.tbl.find('th.col').width(optimal);
  };

  klass.prototype.i18n_total_rows_label = function (data) {
    const resp_tally_or_list = this.report.attribs.type.match(/ListReport/)
      || this.is_response_tally_report(this.report);
    let msg = I18n.t('report/report.total_rows', { count: data.rows.length });
    if (data.truncated) {
      msg += ` (${I18n.t('common.clipped')})`;
    }
    return msg;
  };

  klass.prototype.is_response_tally_report = function (report) {
    return (report.attribs.type.match(/Report::TallyReport/)
      && report.attribs.tally_type.match(/Response/));
  };
}(ELMO.Report));
