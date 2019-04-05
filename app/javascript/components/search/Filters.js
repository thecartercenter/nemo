import React from 'react';
import PropTypes from 'prop-types';
import ButtonToolbar from 'react-bootstrap/ButtonToolbar';
import { Provider as UnstatedProvider } from 'unstated';

import { CONTROLLER_NAME, getFilterString, submitSearch } from './utils';
import ErrorBoundary from '../ErrorBoundary';
import FormFilter from './FormFilter';
import QuestionFilter from './QuestionFilter';
import AdvancedSearchFilter from './AdvancedSearchFilter';

export class FiltersRoot extends React.Component {
  static propTypes = {
    advancedSearchText: PropTypes.string.isRequired,
    allForms: PropTypes.arrayOf(PropTypes.shape({
      id: PropTypes.string,
      name: PropTypes.string,
    })).isRequired,
    controllerName: PropTypes.string,
    selectedFormIds: PropTypes.arrayOf(PropTypes.string).isRequired,
  };

  static defaultProps = {
    // This is expected to be null if the feature flag is disabled.
    controllerName: null,
  };

  constructor(props) {
    super(props);

    const {
      selectedFormIds,
      advancedSearchText,
    } = props;

    /*
     * The state for all filters is held here.
     * Individual filters invoke callbacks to notify this parent component of changes.
     */
    this.state = {
      selectedFormIds,
      advancedSearchText,
    };
  }

  handleSubmit = () => {
    const { allForms } = this.props;
    const filterString = getFilterString(allForms, this.state);
    submitSearch(filterString);
  }

  handleSelectForm = (event) => {
    this.setState({ selectedFormIds: [event.target.value] });
  }

  handleClearFormSelection = () => {
    this.setState({ selectedFormIds: [] });
  }

  handleChangeAdvancedSearch = (event) => {
    this.setState({ advancedSearchText: event.target.value });
  }

  handleClearFilters = () => {
    submitSearch(null);
  }

  renderFilterButtons = () => {
    const { allForms, selectedFormIds: originalFormIds } = this.props;
    const { selectedFormIds } = this.state;

    return (
      <ButtonToolbar>
        <FormFilter
          allForms={allForms}
          selectedFormIds={selectedFormIds}
          originalFormIds={originalFormIds}
          onSelectForm={this.handleSelectForm}
          onClearSelection={this.handleClearFormSelection}
          onSubmit={this.handleSubmit}
        />
        <QuestionFilter
          selectedFormIds={selectedFormIds}
          onSubmit={this.handleSubmit}
        />
      </ButtonToolbar>
    );
  }

  render() {
    const { controllerName } = this.props;
    const { advancedSearchText } = this.state;
    const shouldRenderButtons = controllerName === CONTROLLER_NAME.RESPONSES;

    return (
      <div className="filters">
        <ErrorBoundary>
          {shouldRenderButtons ? this.renderFilterButtons() : null}

          <AdvancedSearchFilter
            advancedSearchText={advancedSearchText}
            onChangeAdvancedSearch={this.handleChangeAdvancedSearch}
            onClear={this.handleClearFilters}
            onSubmit={this.handleSubmit}
          />
        </ErrorBoundary>
      </div>
    );
  }
}

const Filters = (props) => (
  <UnstatedProvider>
    <FiltersRoot {...props} />
  </UnstatedProvider>
);

export default Filters;
