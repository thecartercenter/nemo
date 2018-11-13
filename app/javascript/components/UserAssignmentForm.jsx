import React from "react";
import PropTypes from "prop-types";

import UserAssignmentFormField from "./UserAssignmentFormField";

/**
 * User assignments form in edit user in admin mode.
 * Models the whole form consisting of rows of UserAssignmentFormFields.
 */
class UserAssignmentForm extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    this.handleAddClick = this.handleAddClick.bind(this);
    this.handleDeleteClick = this.handleDeleteClick.bind(this);
  }

  tempMissionId() {
    return "new-mission-" + Math.floor(Math.random() * Math.floor(9000));
  }

  handleAddClick() {
    let assignments = this.state.assignments;
    assignments.push({role: "", mission: this.tempMissionId(), new_record: true});
    this.setState({assignments: assignments});
  }

  handleDeleteClick(idx) {
    let assignments = this.state.assignments;
    assignments[idx].new ? assignments.splice(idx, 1) : assignments[idx]["_destroy"] = true
    this.setState({assignments: assignments});
  }

  render() {
    return (
      <div className="assignments">
        <div>
          {this.state.assignments.map(
            (props, idx) => (<UserAssignmentFormField
              hadDeleteClick={this.onDeleteClick}
              index={idx}
              key={idx}
              missions={this.state.missions}
              roles={this.state.roles}
              {...props} />)
          )}
        </div>
        <div>
          <a
            className="add-assignment"
            onClick={this.handleAddClick}>
            <i className="fa fa-plus" />
            &nbsp;
            {I18n.t("user.add_assignment")}
          </a>
        </div>
      </div>
    );
  }
}

export default UserAssignmentForm;
