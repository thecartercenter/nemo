import React from "react";
import PropTypes from "prop-types";
import Button from "react-bootstrap/lib/Button";

import {isQueryParamTruthy} from "./utils";

class AdvancedSearchFilter extends React.Component {
  constructor(props) {
    super();
  }

  render() {
    const {advancedSearchText, onChangeAdvancedSearch, onClear, onSubmit} = this.props;

    return (
      <div>
        <input
          autoComplete="off"
          className="form-control"
          id="search-str"
          name="search"
          onChange={onChangeAdvancedSearch}
          placeholder={I18n.t("filter.advancedSearch")}
          type="text"
          value={advancedSearchText} />
        <Button
          className="btn-apply btn-advanced-search"
          onClick={onSubmit}>
          {I18n.t("common.search")}
        </Button>
        {isQueryParamTruthy("search") ? (
          <Button
            className="btn-clear btn-margin-left"
            onClick={onClear}>
            {I18n.t("common.clear")}
          </Button>
        ) : null}
      </div>
    );
  }
}

AdvancedSearchFilter.propTypes = {
  advancedSearchText: PropTypes.string.isRequired,
  onChangeAdvancedSearch: PropTypes.func.isRequired,
  onClear: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
};

export default AdvancedSearchFilter;
