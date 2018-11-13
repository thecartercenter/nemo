import React from "react";
import PropTypes from "prop-types";

/**
 * Models each row of User Assignments consisting of a mission and a role.
 */
class UserAssignmentFormField extends React.Component {
  constructor(props) {
    super();
  }

  missionField() {
    let missionSelectProps = {
      className: "mission form-control",
      defaultValue: this.props.mission,
      name: `user[assignments_attributes][${this.props.index}][mission_id]`
    };

    if (this.props.new_record) {
      return (
        <select {...missionSelectProps}>
          {this.missionOptionTags()}
        </select>
      );
    } else {
      return (
        <div>
          {this.props.name}
          <input
            name={`user[assignments_attributes][${this.props.index}][id]`}
            type="hidden"
            value={this.props.id === null ? "" : this.props.id} />
        </div>
      );
    }
  }

  missionOptionTags() {
    return this.props.missions.map((mission) => (
      <option
        key={mission.id}
        value={mission.id}>
        {mission.name}
      </option>
    ));
  }

  roleOptionTags() {
    return this.props.roles.map((option) => (
      <option
        key={option}
        value={option}>
        {I18n.t(`role.${option}`)}
      </option>
    ));
  }

  deleteInput() {
    return (
      <div>
        <input
          defaultValue={true}
          name={`user[assignments_attributes][${this.props.index}][_destroy]`}
          type="hidden"
        />
        <input
          defaultValue={this.props.id}
          name={`user[assignments_attributes][${this.props.index}][id]`}
          type="hidden"
        />
      </div>
    );
  }

  missionRoleFields() {
    let roleSelectProps = {
      className: "role form-control",
      defaultValue: this.props.role,
      name: `user[assignments_attributes][${this.props.index}][role]`
    };
    return (
      <div className="assignment-row">
        <div className="mission">
          {this.missionField()}
        </div>
        <div className="role">
          <select className="form-control"
            {...roleSelectProps}>
            {this.roleOptionTags()}
          </select>
        </div>
        <a className="trash"
          onClick={(e) => this.props.onDeleteClick(this.props.index)}>
          <i className="fa fa-close"/>
        </a>
      </div>
    );
  }

  render() {
    return this.props._destroy ? this.deleteInput() : this.missionRoleFields();
  }
}

export default UserAssignmentFormField;
