import mapKeys from "lodash/mapKeys";
import React from "react";
import PropTypes from "prop-types";
import Button from "react-bootstrap/lib/Button";
import Popover from "react-bootstrap/lib/Popover";
import OverlayTrigger from "react-bootstrap/lib/OverlayTrigger";
import Select2 from "react-select2-wrapper/lib/components/Select2.full";

import "react-select2-wrapper/css/select2.css";

/**
 * Converts a list of forms from the backend into something Select2 understands.
 */
const parseFormsForSelect2 = (allForms) => allForms
  .map((form) => mapKeys(form, (value, key) => key === "name" ? "text" : key));

class FormFilter extends React.Component {
  constructor(props) {
    super();
    this.renderPopover = this.renderPopover.bind(this);
  }

  renderPopover() {
    const {allForms, selectedFormIds, onSelectForm, onSubmit} = this.props;

    return (
      <Popover
        className="filters-popover"
        id="form-filter">
        <Select2
          data={parseFormsForSelect2(allForms)}
          onSelect={onSelectForm}
          options={{
            placeholder: I18n.t("filter.chooseForm"),
            dropdownCssClass: "filters-select2-dropdown",
            width: "100%",
          }}
          value={selectedFormIds && selectedFormIds[0]} />

        <div className="btn-apply-container">
          <Button
            className="btn-apply"
            onClick={onSubmit}>
            {I18n.t("common.apply")}
          </Button>
        </div>
      </Popover>
    );
  }

  render() {
    return (
      <OverlayTrigger
        containerPadding={25}
        overlay={this.renderPopover()}
        placement="bottom"
        rootClose
        trigger="click">
        <Button className="btn-form-filter">
          {I18n.t("filter.form")}
        </Button>
      </OverlayTrigger>
    );
  }
}

FormFilter.propTypes = {
  allForms: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string,
    name: PropTypes.string
  })).isRequired,
  onSelectForm: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  selectedFormIds: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default FormFilter;
