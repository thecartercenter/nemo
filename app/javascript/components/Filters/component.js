import React from 'react';
import PropTypes from 'prop-types';
import ButtonToolbar from 'react-bootstrap/ButtonToolbar';
import { observer, inject } from 'mobx-react';

import { CONTROLLER_NAME, getFilterString, submitSearch } from './utils';
import FormFilter from './FormFilter/component';
import QuestionFilter from './QuestionFilter/component';
import ReviewedFilter from './ReviewedFilter/component';
import SubmitterFilter from './SubmitterFilter/component';
import AdvancedSearchFilter from './AdvancedSearchFilter/component';
import DateFilter from './DateFilter/component';

@inject('filtersStore')
@inject('conditionSetStore')
@observer
class Filters extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object.isRequired,
    conditionSetStore: PropTypes.object.isRequired,
    controllerName: PropTypes.string,
  };

  static defaultProps = {
    // This is expected to be null if the feature flag is disabled.
    controllerName: null,
  };

  constructor(props) {
    super(props);

    const { controllerName } = props;
    this.state = {
      shouldRenderButtons: controllerName === CONTROLLER_NAME.RESPONSES,
    };
  }

  handleSubmit = () => {
    const { filtersStore } = this.props;
    const { advancedSearchText } = filtersStore;
    const { shouldRenderButtons } = this.state;
    const filterString = shouldRenderButtons ? getFilterString(filtersStore) : advancedSearchText;
    submitSearch(filterString);
  };

  handleClearFilters = () => {
    submitSearch(null);
  };

  renderFilterButtons = () => {
    const defaultProps = {
      onSubmit: this.handleSubmit,
    };

    return (
      <ButtonToolbar>
        <i className="fa fa-filter" />
        <FormFilter {...defaultProps} />
        <QuestionFilter {...defaultProps} />
        <ReviewedFilter {...defaultProps} />
        <SubmitterFilter {...defaultProps} />
        <DateFilter {...defaultProps} />
      </ButtonToolbar>
    );
  };

  render() {
    const { shouldRenderButtons } = this.state;

    return (
      <div className="filters">
        {shouldRenderButtons ? this.renderFilterButtons() : null}

        <AdvancedSearchFilter
          renderInfoButton={shouldRenderButtons}
          onClear={this.handleClearFilters}
          onSubmit={this.handleSubmit}
        />
      </div>
    );
  }
}

export default Filters;
