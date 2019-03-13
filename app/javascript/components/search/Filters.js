import React from "react";
import PropTypes from "prop-types";
import ButtonToolbar from "react-bootstrap/lib/ButtonToolbar";

import {CONTROLLER_NAME, getFilterString, submitSearch} from "./utils";
import FormFilter from "./FormFilter";
import AdvancedSearchFilter from "./AdvancedSearchFilter";

class Filters extends React.Component {
  constructor(props) {
    super();

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

    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleSelectForm = this.handleSelectForm.bind(this);
    this.handleClearFormSelection = this.handleClearFormSelection.bind(this);
    this.handleChangeAdvancedSearch = this.handleChangeAdvancedSearch.bind(this);
    this.handleClearFilters = this.handleClearFilters.bind(this);
    this.renderFilterButtons = this.renderFilterButtons.bind(this);
  }

  handleSubmit() {
    const {allForms} = this.props;
    const {selectedFormIds} = this.state;
    const filterString = getFilterString(allForms, this.state);
    submitSearch(filterString);
  }

  handleSelectForm(event) {
    this.setState({selectedFormIds: [event.target.value]});
  }

  handleClearFormSelection() {
    this.setState({selectedFormIds: []});
  }

  handleChangeAdvancedSearch(event) {
    this.setState({advancedSearchText: event.target.value});
  }

  handleClearFilters() {
    submitSearch(null);
  }

  renderFilterButtons() {
    const {allForms, selectedFormIds: originalFormIds} = this.props;
    const {selectedFormIds} = this.state;

    return (
      <ButtonToolbar className="filters">
        <FormFilter
          allForms={allForms}
          onClearSelection={this.handleClearFormSelection}
          onSelectForm={this.handleSelectForm}
          onSubmit={this.handleSubmit}
          originalFormIds={originalFormIds}
          selectedFormIds={selectedFormIds} />
      </ButtonToolbar>
    );
  }

  render() {
    const {controllerName} = this.props;
    const {advancedSearchText} = this.state;
    const shouldRenderButtons = controllerName === CONTROLLER_NAME.RESPONSES;

    return (
      <React.Fragment>
        {shouldRenderButtons ? this.renderFilterButtons() : null}

        <AdvancedSearchFilter
          advancedSearchText={advancedSearchText}
          onChangeAdvancedSearch={this.handleChangeAdvancedSearch}
          onClear={this.handleClearFilters}
          onSubmit={this.handleSubmit} />
      </React.Fragment>
    );
  }
}

Filters.propTypes = {
  advancedSearchText: PropTypes.string.isRequired,
  allForms: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string,
    name: PropTypes.string
  })).isRequired,
  controllerName: PropTypes.string.isRequired,
  selectedFormIds: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default Filters;
