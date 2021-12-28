import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';
import { DateRangePicker } from 'react-dates';

import 'react-dates/initialize';
import 'react-dates/lib/css/_datepicker.css';

import FilterOverlayTrigger from '../FilterOverlayTrigger/component';

@inject('filtersStore')
@observer
class DateFilter extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object,
    onSubmit: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);
    this.state = {
      focusedInput: null,
    };
  }

  renderPopover = () => {
    const { filtersStore } = this.props;
    const { startDate, endDate, handleDateChange } = filtersStore;
    const { focusedInput: focus } = this.state;
    return (
      <div>
        <DateRangePicker
          startDate={startDate}
          startDateId="start-date"
          endDate={endDate}
          endDateId="end-date"
          onDatesChange={handleDateChange}
          focusedInput={focus}
          onFocusChange={(focusedInput) => this.setState({ focusedInput })}
          isOutsideRange={() => false}
          showClearDates
          displayFormat="YYYY-MM-DD"
          startDatePlaceholderText={I18n.t('common.startDatePlaceholder')}
          endDatePlaceholderText={I18n.t('common.endDatePlaceholder')}
        />
      </div>
    );
  };

  render() {
    const { filtersStore, onSubmit } = this.props;
    const { startDate, endDate } = filtersStore;

    let hints = [];
    if (startDate != null && endDate != null) {
      hints = [`${startDate.format('YYYY-MM-DD')} – ${endDate.format('YYYY-MM-DD')}`];
    } else {
      hints = [[startDate, I18n.t('common.startDate')], [endDate, I18n.t('common.endDate')]]
        .map(([date, label]) => (date == null ? null : `${label}: ${date.format('YYYY-MM-DD')}`))
        .filter((hint) => hint != null);
    }
    return (
      <FilterOverlayTrigger
        id="date-filter"
        title={I18n.t('filter.date')}
        popoverContent={this.renderPopover()}
        popoverClass="wide display-logic-container"
        buttonsContainerClass="inline"
        onSubmit={onSubmit}
        buttonClass="btn-margin-left"
        hints={hints}
      />
    );
  }
}

export default DateFilter;
