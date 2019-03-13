import React from "react";
import PropTypes from "prop-types";
import ButtonToolbar from "react-bootstrap/lib/ButtonToolbar";

import {getFilterString, submitSearch} from "./utils";
import FormFilter from "./FormFilter";

class Filters extends React.Component {
  constructor(props) {
    super();

    const {selectedFormIds} = props;

    /*
     * The state for all filters is held here.
     * Individual filters invoke callbacks to notify this parent component of changes.
     */
    this.state = {selectedFormIds};

    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleSelectForm = this.handleSelectForm.bind(this);
  }

  handleSubmit() {
    const {selectedFormIds} = this.state;
    const filterString = getFilterString(selectedFormIds);
    submitSearch(filterString);
  }

  handleSelectForm(event) {
    this.setState({selectedFormIds: [event.target.value]});
  }

  render() {
    const {allForms} = this.props;
    const {selectedFormIds} = this.state;

    return (
      <ButtonToolbar className="filters">
        <FormFilter
          allForms={allForms}
          onSelectForm={this.handleSelectForm}
          onSubmit={this.handleSubmit}
          selectedFormIds={selectedFormIds} />
      </ButtonToolbar>
    );
  }
}

Filters.propTypes = {
  allForms: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string,
    displayName: PropTypes.string
  })).isRequired,
  selectedFormIds: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default Filters;
