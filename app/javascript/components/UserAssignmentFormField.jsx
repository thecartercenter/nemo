import React from 'react';
import PropTypes from 'prop-types';

/**
 * Models each row of User Assignments consisting of a mission and a role.
 */
class UserAssignmentFormField extends React.Component {
  constructor(props) {
    super();
    this.state = { destroy: props.destroy };
    this.handleRemoveClick = this.handleRemoveClick.bind(this);
  }

  missionField() {
    if (this.props.newRecord) {
      return (
        <select
          className="mission form-control"
          defaultValue={this.props.missionId}
          name={`user[assignments_attributes][${this.props.index}][mission_id]`}
        >
          {this.missionOptionTags()}
        </select>
      );
    }
    return (
      <div>
        {this.props.missionName}
        <input
          name={`user[assignments_attributes][${this.props.index}][id]`}
          type="hidden"
          value={this.props.id || ''}
        />
      </div>
    );
  }

  missionOptionTags() {
    return this.props.missions.map((mission) => (
      <option
        key={mission.id}
        value={mission.id}
      >
        {mission.name}
      </option>
    ));
  }

  roleOptionTags() {
    return this.props.roles.map((option) => (
      <option
        key={option}
        value={option}
      >
        {I18n.t(`role.${option}`)}
      </option>
    ));
  }

  missionRoleFields() {
    return (
      <div className="assignment-row">
        <div className="mission">
          {this.missionField()}
        </div>
        <div className="role">
          <select
            className="form-control"
            defaultValue={this.props.role}
            name={`user[assignments_attributes][${this.props.index}][role]`}
          >
            {this.roleOptionTags()}
          </select>
        </div>
        <a
          className="remove"
          onClick={this.handleRemoveClick}
        >
          <i className="fa fa-close" />
        </a>
      </div>
    );
  }

  handleRemoveClick() {
    this.setState({ destroy: true });
  }

  render() {
    return (
      <div>
        {this.state.destroy ? '' : this.missionRoleFields()}
        <input
          name={`user[assignments_attributes][${this.props.index}][_destroy]`}
          type="hidden"
          value={this.state.destroy}
        />
        <input
          name={`user[assignments_attributes][${this.props.index}][id]`}
          type="hidden"
          value={this.props.id || ''}
        />
      </div>
    );
  }
}

UserAssignmentFormField.propTypes = {
  destroy: PropTypes.bool,
  id: PropTypes.string,
  index: PropTypes.number.isRequired,
  missionId: PropTypes.string,
  missionName: PropTypes.string,
  missions: PropTypes.arrayOf(PropTypes.object).isRequired,
  newRecord: PropTypes.bool,
  role: PropTypes.string,
  roles: PropTypes.arrayOf(PropTypes.string).isRequired,
};

UserAssignmentFormField.defaultProps = {
  destroy: false,
  id: null,
  missionId: null,
  missionName: null,
  newRecord: false,
  role: null,
};

export default UserAssignmentFormField;
