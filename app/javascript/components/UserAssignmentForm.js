import React from "react";
import PropTypes from "prop-types";

import UserAssignmentFormField from "./UserAssignmentFormField";


// {missions: [34:"liberia", 99:"new guinea"], assignments: [34:3, 22:1], roles: ["whatever", "blargh"]}

class UserAssignmentForm extends React.Component {
  constructor(props) {
    super();
    console.log("in user assignment form");
    this.state = props;
    this.count = 0;
    console.log(this.state);
  }

  render() {
    return (
      <div>
        {this.state.assignments.map(
          (props, index) =>
            <UserAssignmentFormField
              index={index}
              key={props.id}
              missions={this.state.missions}
              roles={this.state.roles}
              {...props} />
         )}
      </div>
    );
  }
}

export default UserAssignmentForm;
