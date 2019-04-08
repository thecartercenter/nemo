import React from 'react';
import PropTypes from 'prop-types';
import ButtonToolbar from 'react-bootstrap/ButtonToolbar';
import { observable, action } from 'mobx';
import { observer, inject, Provider } from 'mobx-react';

import { CONTROLLER_NAME, getFilterString, submitSearch } from './utils';
import ErrorBoundary from '../ErrorBoundary';
import FormFilter from './FormFilter';
import QuestionFilter from './QuestionFilter';
import AdvancedSearchFilter from './AdvancedSearchFilter';

class FiltersModel {
  @observable
  selectedFormIds = [];

  @observable
  advancedSearchText = '';

  @action
  handleSelectForm = (event) => {
    this.selectedFormIds = [event.target.value];
  }

  @action
  handleClearFormSelection = () => {
    this.selectedFormIds = [];
  }

  @action
  handleChangeAdvancedSearch = (event) => {
    this.advancedSearchText = event.target.value;
  }
}

export { FiltersModel };

const filtersStore = new FiltersModel();

if (process.env.NODE_ENV === 'development') {
  // Debug helper.
  window.store = filtersStore;
}

@inject('store')
@observer
class FiltersRoot extends React.Component {
  static propTypes = {
    store: PropTypes.object.isRequired,
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
      store,
      selectedFormIds,
      advancedSearchText,
    } = props;

    // Directly assign initial values to the store.
    Object.assign(store, {
      selectedFormIds,
      advancedSearchText,
    });
  }

  handleSubmit = () => {
    const { store, allForms } = this.props;
    const filterString = getFilterString(allForms, store);
    submitSearch(filterString);
  }

  handleClearFilters = () => {
    submitSearch(null);
  }

  renderFilterButtons = () => {
    const { store, allForms, selectedFormIds: originalFormIds } = this.props;
    const { selectedFormIds, handleSelectForm, handleClearFormSelection } = store;

    return (
      <ButtonToolbar>
        <FormFilter
          allForms={allForms}
          selectedFormIds={selectedFormIds}
          originalFormIds={originalFormIds}
          onSelectForm={handleSelectForm}
          onClearSelection={handleClearFormSelection}
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
    const { store, controllerName } = this.props;
    const { advancedSearchText, handleChangeAdvancedSearch } = store;
    const shouldRenderButtons = controllerName === CONTROLLER_NAME.RESPONSES;

    return (
      <div className="filters">
        <ErrorBoundary>
          {shouldRenderButtons ? this.renderFilterButtons() : null}

          <AdvancedSearchFilter
            advancedSearchText={advancedSearchText}
            onChangeAdvancedSearch={handleChangeAdvancedSearch}
            onClear={this.handleClearFilters}
            onSubmit={this.handleSubmit}
          />
        </ErrorBoundary>
      </div>
    );
  }
}

const Filters = (props) => (
  <Provider store={filtersStore}>
    <FiltersRoot {...props} />
  </Provider>
);

export default Filters;

// Root component for testing.
const { wrappedComponent } = FiltersRoot;
export { wrappedComponent as FiltersRoot };
