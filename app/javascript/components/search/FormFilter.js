import mapKeys from "lodash/mapKeys";
import React from "react";
import PropTypes from "prop-types";
import Button from "react-bootstrap/lib/Button";
import Popover from "react-bootstrap/lib/Popover";
import OverlayTrigger from "react-bootstrap/lib/OverlayTrigger";
import Select2 from "react-select2-wrapper";

import "react-select2-wrapper/css/select2.css";

const parseFormsForSelect2 = (allForms) => allForms
  .map((form) => mapKeys(form, (value, key) => key === "displayName" ? "text" : key));

class FormFilter extends React.Component {
  constructor(props) {
    super();
    this.renderPopover = this.renderPopover.bind(this);
  }

  renderPopover() {
    const {allForms, selectedFormIds} = this.props;

    return (
      <Popover>
        <Select2
          data={parseFormsForSelect2(allForms)}
          defaultValue={selectedFormIds}
          options={{
            placeholder: "Choose a form",
          }} />
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
        <Button>
          {I18n.t("filter.form")}
        </Button>
      </OverlayTrigger>
    );
  }
}

FormFilter.propTypes = {
  allForms: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string,
    displayName: PropTypes.string
  })).isRequired,
  selectedFormIds: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default FormFilter;
