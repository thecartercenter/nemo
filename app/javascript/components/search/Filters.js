import isEmpty from "lodash/isEmpty";
import React from "react";
import PropTypes from "prop-types";
import ButtonToolbar from "react-bootstrap/lib/ButtonToolbar";

import FormFilter from "./FormFilter";

class Filters extends React.Component {
  constructor(props) {
    super();

    const {selectedFormIds} = props;
    this.state = {selectedFormIds};

    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleSelectForm = this.handleSelectForm.bind(this);
  }

  componentDidMount() {
    // Initialize all popovers on the page.
    $(function() {
      // TODO: Be more selective about which ones to initialize.
      $("[data-toggle=\"popover\"]").popover();
    });
  }

  handleSubmit() {
    const {selectedFormIds} = this.state;
    const formString = isEmpty(selectedFormIds) ? "" : `form:(${selectedFormIds.join("|")})`;

    // TODO: Play nicely with the other filter options instead of clobbering them.
    window.location.href = `?search=${formString}`;
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
