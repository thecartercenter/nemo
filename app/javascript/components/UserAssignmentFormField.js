import React from "react";
import PropTypes from "prop-types";

// {missions: [34:"liberia", 99:"new guinea"], assignments: [34:3, 22:1], roles: ["whatever", "blargh"]}

class UserAssignmentFormField extends React.Component {
  constructor(props) {
    super();
    console.log("in user assignment form field");
    console.log(props);
    this.state = props;
  }

  missionOptionTags() {
    console.log("Missions");
    console.log(this.state.missions);
    return this.state.missions.map((mission) => (
      <option
        key={mission.id}
        value={mission.id}>
        {mission.name}
      </option>
    ));
  }

  roleOptionTags() {
    return this.state.roles.map((option) => (
      <option
        key={option}
        value={option}>
        {option}
      </option>
    ));
  }


  render() {
    let missionSelectProps = {
      className: "mission",
      defaultValue: this.state.mission,
      name: `user[assignments_attributes][${this.state.index}][mission_id]`
    };

    let roleSelectProps = {
      className: "role",
      defaultValue: this.state.role,
      name: `user[assignments_attributes][${this.state.index}][role]`
    };

    return (
      <div>
        <div className="mission">
          <select {...missionSelectProps}>
            {this.missionOptionTags()}
          </select>
        </div>
        <div className="role">
          <select {...roleSelectProps}>
            {this.roleOptionTags()}
          </select>
        </div>
      </div>
    );
  }
}

export default UserAssignmentFormField;
