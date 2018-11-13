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
    // need to delete ids of duplicates, since active seralizer doesnt wanna do it
    // props.assignments.map(a => a.id == null ? delete a.id : "");
    this.state = props;
    this.onAddClick = this.onAddClick.bind(this);
    this.onDeleteClick = this.onDeleteClick.bind(this);
  }

  tempMissionId() {
    return "new-mission-"+ Math.floor(Math.random() * Math.floor(9000));
  }

  onAddClick() {
    let assignments = this.state.assignments;
    assignments.push({role: "", mission: this.tempMissionId(), new_record: true});
    this.setState({assignments: assignments});
  }

  onDeleteClick(idx) {
    let assignments = this.state.assignments;
    assignments[idx].new ? assignments.splice(idx, 1) : assignments[idx]["_destroy"] = true
    this.setState({assignments: assignments});
  }

  render() {
    return (
      <div className="assignments">
        <div>
          {this.state.assignments.map(
            (props, index) =>
              <UserAssignmentFormField
                onDeleteClick={this.onDeleteClick}
                index={index}
                key={index}
                missions={this.state.missions}
                roles={this.state.roles}
                {...props} />
            )}
        </div>
        <div>
          <a className="add-assignment"
            onClick={this.onAddClick}>
            <i className="fa fa-plus"/>
            {I18n.t("user.add_assignment")}
          </a>
        </div>
      </div>
    );
  }
}

export default UserAssignmentForm;
