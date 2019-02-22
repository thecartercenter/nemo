import React from "react";
import PropTypes from "prop-types";

import FormFilter from "./FormFilter";

class Filters extends React.Component {
  componentDidMount() {
    // Initialize all popovers on the page.
    $(function() {
      // TODO: Be more selective about which ones to initialize.
      $("[data-toggle=\"popover\"]").popover();
    });
  }

  render() {
    return (
      <div className="filters">
        <FormFilter {...this.props} />
      </div>
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
