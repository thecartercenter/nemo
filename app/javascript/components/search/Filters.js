import React from 'react';
import PropTypes from 'prop-types';
import ButtonToolbar from 'react-bootstrap/ButtonToolbar';
import { Provider as UnstatedProvider, Container as Store, Subscribe } from 'unstated';

import { CONTROLLER_NAME, getFilterString, submitSearch } from './utils';
import ErrorBoundary from '../ErrorBoundary';
import FormFilter from './FormFilter';
import QuestionFilter from './QuestionFilter';
import AdvancedSearchFilter from './AdvancedSearchFilter';

class FiltersStore extends Store {
  state = {
    selectedFormIds: [],
    advancedSearchText: '',
  };

  handleSelectForm = (event) => {
    this.setState({ selectedFormIds: [event.target.value] });
  }

  handleClearFormSelection = () => {
    this.setState({ selectedFormIds: [] });
  }

  handleChangeAdvancedSearch = (event) => {
    this.setState({ advancedSearchText: event.target.value });
  }
}

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

    // TODO: Set initial store state based on props.
  }

  handleSubmit = (filters) => () => {
    const { allForms } = this.props;
    const filterString = getFilterString(allForms, filters.state);
    submitSearch(filterString);
  }

  handleClearFilters = () => {
    submitSearch(null);
  }

  renderFilterButtons = (filters) => {
    const { allForms, selectedFormIds: originalFormIds } = this.props;
    const { selectedFormIds } = filters.state;

    return (
      <ButtonToolbar>
        <FormFilter
          allForms={allForms}
          selectedFormIds={selectedFormIds}
          originalFormIds={originalFormIds}
          onSelectForm={filters.handleSelectForm}
          onClearSelection={filters.handleClearFormSelection}
          onSubmit={this.handleSubmit(filters)}
        />
        <QuestionFilter
          selectedFormIds={selectedFormIds}
          onSubmit={this.handleSubmit(filters)}
        />
      </ButtonToolbar>
    );
  }

  renderWithFilters = (filters) => {
    const { controllerName } = this.props;
    const { advancedSearchText } = filters.state;
    const shouldRenderButtons = controllerName === CONTROLLER_NAME.RESPONSES;

    return (
      <React.Fragment>
        {shouldRenderButtons ? this.renderFilterButtons(filters) : null}

        <AdvancedSearchFilter
          advancedSearchText={advancedSearchText}
          onChangeAdvancedSearch={filters.handleChangeAdvancedSearch}
          onClear={this.handleClearFilters}
          onSubmit={this.handleSubmit(filters)}
        />
      </React.Fragment>
    );
  }

  render() {
    return (
      <div className="filters">
        <ErrorBoundary>
          <Subscribe to={[FiltersStore]}>
            {this.renderWithFilters}
          </Subscribe>
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
