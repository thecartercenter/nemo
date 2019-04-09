import React from 'react';
import PropTypes from 'prop-types';
import ButtonToolbar from 'react-bootstrap/ButtonToolbar';
import { observer, inject, Provider } from 'mobx-react';

import { CONTROLLER_NAME, createFiltersStore, getFilterString, submitSearch } from './utils';
import ErrorBoundary from '../ErrorBoundary';
import FormFilter from './FormFilter';
import QuestionFilter from './QuestionFilter';
import AdvancedSearchFilter from './AdvancedSearchFilter';

@inject('filtersStore')
@observer
class FiltersRoot extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object.isRequired,
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
      filtersStore,
      selectedFormIds,
      advancedSearchText,
    } = props;

    // Directly assign initial values to the store.
    Object.assign(filtersStore, {
      selectedFormIds,
      advancedSearchText,
    });
  }

  handleSubmit = () => {
    const { filtersStore, allForms } = this.props;
    const filterString = getFilterString(allForms, filtersStore);
    submitSearch(filterString);
  }

  handleClearFilters = () => {
    submitSearch(null);
  }

  renderFilterButtons = () => {
    const { allForms, selectedFormIds: originalFormIds } = this.props;

    return (
      <ButtonToolbar>
        <FormFilter
          allForms={allForms}
          originalFormIds={originalFormIds}
          onSubmit={this.handleSubmit}
        />
        <QuestionFilter
          onSubmit={this.handleSubmit}
        />
      </ButtonToolbar>
    );
  }

  render() {
    const { controllerName } = this.props;
    const shouldRenderButtons = controllerName === CONTROLLER_NAME.RESPONSES;

    return (
      <div className="filters">
        <ErrorBoundary>
          {shouldRenderButtons ? this.renderFilterButtons() : null}

          <AdvancedSearchFilter
            onClear={this.handleClearFilters}
            onSubmit={this.handleSubmit}
          />
        </ErrorBoundary>
      </div>
    );
  }
}

const Filters = (props) => (
  <Provider filtersStore={createFiltersStore()}>
    <FiltersRoot {...props} />
  </Provider>
);

export default Filters;

// Root component for testing.
export { FiltersRoot };
