import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';
import 'react-dates/initialize';
import { DateRangePicker } from 'react-dates';
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
      startDate: null,
      endDate: null,
      focusedInput: null,
    };
  }

  async componentDidMount() {
    const { filtersStore } = this.props;
    await filtersStore.updateRefableQings();
  }

  renderPopover = () => {
    const { startDate: start, endDate: end, focusedInput: focus } = this.state;
    return (
      <div>
        <DateRangePicker
          startDate={start}
          startDateId="start-date"
          endDate={end}
          endDateId="end-date"
          onDatesChange={({ startDate, endDate }) => this.setState({ startDate, endDate })}
          focusedInput={focus}
          onFocusChange={(focusedInput) => this.setState({ focusedInput })}
          isOutsideRange={() => false}
        />
      </div>
    );
  }

  render() {
    const { onSubmit } = this.props;

    return (
      <FilterOverlayTrigger
        id="date-filter"
        title={I18n.t('filter.date')}
        popoverContent={this.renderPopover()}
        popoverClass="wide display-logic-container"
        buttonsContainerClass="condition-margin"
        onSubmit={onSubmit}
        buttonClass="btn-margin-left"
      />
    );
  }
}

export default DateFilter;
