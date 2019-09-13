import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';
import 'react-dates/initialize';
import { DateRangePicker } from 'react-dates';
import 'react-dates/lib/css/_datepicker.css';
import { last } from 'lodash';
import { queryToMoment } from '../utils';

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

  async componentDidMount() {
    const { filtersStore } = this.props;
    await filtersStore.updateRefableQings();
  }

  renderPopover = () => {
    const { filtersStore } = this.props;
    const { handleDateChange, advancedSearchText } = filtersStore;
    let { startDate, endDate } = filtersStore;
    const searchDates = advancedSearchText.split(' ').filter((s) => s.indexOf('submit-date') !== -1);
    startDate = startDate === null ? queryToMoment(last(searchDates.filter((s) => s.indexOf('>') !== -1))) : startDate;
    endDate = endDate === null ? queryToMoment(last(searchDates.filter((s) => s.indexOf('<') !== -1))) : endDate;
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
        />
      </div>
    );
  }

  render() {
    const { filtersStore, onSubmit } = this.props;
    const { advancedSearchText } = filtersStore;
    let { startDate, endDate } = filtersStore;
    const searchDates = advancedSearchText.split(' ').filter((s) => s.indexOf('submit-date') !== -1);
    startDate = startDate === null ? queryToMoment(searchDates.filter((s) => s.indexOf('>') !== -1)[0]) : startDate;
    endDate = endDate === null ? queryToMoment(searchDates.filter((s) => s.indexOf('<') !== -1)[0]) : endDate;

    const hints = [[startDate, 'Start Date'], [endDate, 'End Date']]
      .map(([date, label]) => (date === null ? null : `${label}: ${date.format('YYYY-MM-DD')}`))
      .filter((h) => h !== null);

    return (
      <FilterOverlayTrigger
        id="date-filter"
        title={I18n.t('filter.date')}
        popoverContent={this.renderPopover()}
        popoverClass="wide display-logic-container"
        buttonsContainerClass="condition-margin"
        onSubmit={onSubmit}
        buttonClass="btn-margin-left"
        hints={hints}
      />
    );
  }
}

export default DateFilter;
