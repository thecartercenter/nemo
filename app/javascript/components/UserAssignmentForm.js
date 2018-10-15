import React from "react";
import PropTypes from "prop-types";

import UserAssignmentFormField from "./UserAssignmentFormField";

class UserAssignmentForm extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    console.log(this.state);
    this.handleAddClick = this.handleAddClick.bind(this);
    this.handleDeleteClick = this.handleDeleteClick.bind(this);
  }

  randomUUID() {
    return "new-mission-"+ Math.floor(Math.random() * Math.floor(9000));
  }

  handleAddClick() {
    let assignments = this.state.assignments;
    assignments.push({role: "", mission: this.randomUUID(), new_assignment: true});
    this.setState({assignments: assignments});
  }

  handleDeleteClick(event) {
    let assignments = this.state.assignments;
    let idx = assignments.findIndex((e) => { return e.mission == event; });
    assignments[idx].new ? assignments.splice(idx, 1) : assignments[idx]["destroy"] = true
    this.setState({assignments: assignments});
  }

  render() {
    return (
      <div>
        <div>
          {this.state.assignments.map(
            (props, index) =>
              <UserAssignmentFormField
                index={index}
                key={props.mission}
                missions={this.state.missions}
                roles={this.state.roles}
                deleteClick={this.handleDeleteClick}
                {...props} />
           )}
        </div>
        <div>
          <a onClick={this.handleAddClick}>Add Assignment</a>
        </div>
      </div>
    );
  }
}

export default UserAssignmentForm;
