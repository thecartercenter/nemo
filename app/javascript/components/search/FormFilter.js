import mapKeys from "lodash/mapKeys";
import React from "react";
import PropTypes from "prop-types";
import Button from "react-bootstrap/Button";
import Popover from "react-bootstrap/Popover";
import OverlayTrigger from "react-bootstrap/OverlayTrigger";
import Select2 from "react-select2-wrapper/lib/components/Select2.full";

import "react-select2-wrapper/css/select2.css";
import {getButtonHintString, getFormNameFromId} from "./utils";

/**
 * Converts a list of forms from the backend into something Select2 understands.
 */
const parseFormsForSelect2 = (allForms) => allForms
  .map((form) => mapKeys(form, (value, key) => key === "name" ? "text" : key));

class FormFilter extends React.Component {
  constructor(props) {
    super();
    this.handleClearSelection = this.handleClearSelection.bind(this);
    this.renderPopover = this.renderPopover.bind(this);

    this.select2 = React.createRef();
  }

  handleClearSelection() {
    const {onClearSelection} = this.props;
    onClearSelection();

    /*
     * Select2 doesn't make this easy... wait for state update then close the dropdown.
     * https://select2.org/programmatic-control/methods#closing-the-dropdown
     */
    setTimeout(() => this.select2.current.el.select2("close"), 1);
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
          onUnselect={this.handleClearSelection}
          options={{
            allowClear: true,
            placeholder: I18n.t("filter.chooseForm"),
            dropdownCssClass: "filters-select2-dropdown",
            width: "100%",
          }}
          ref={this.select2}
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
    const {allForms, originalFormIds} = this.props;
    const originalFormNames = originalFormIds.map((id) => getFormNameFromId(allForms, id));

    return (
      <OverlayTrigger
        containerPadding={25}
        overlay={this.renderPopover()}
        placement="bottom"
        rootClose
        trigger="click">
        <Button className="btn-form-filter btn-secondary">
          {I18n.t("filter.form") + getButtonHintString(originalFormNames)}
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
  onClearSelection: PropTypes.func.isRequired,
  onSelectForm: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  originalFormIds: PropTypes.arrayOf(PropTypes.string).isRequired,
  selectedFormIds: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default FormFilter;
