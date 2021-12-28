import React from 'react';
import PropTypes from 'prop-types';

/**
 * Models each row of User Assignments consisting of a mission and a role.
 */
class UserAssignmentFormField extends React.Component {
  static propTypes = {
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

  constructor(props) {
    super(props);
    const { destroy } = this.props;
    this.state = { destroy };
  }

  missionField = () => {
    const { newRecord, missionId, missionName, index, id } = this.props;

    if (newRecord) {
      return (
        <select
          className="mission form-control"
          defaultValue={missionId}
          name={`user[assignments_attributes][${index}][mission_id]`}
        >
          {this.missionOptionTags()}
        </select>
      );
    }

    return (
      <div>
        {missionName}
        <input
          name={`user[assignments_attributes][${index}][id]`}
          type="hidden"
          value={id || ''}
        />
      </div>
    );
  };

  missionOptionTags = () => {
    const { missions } = this.props;

    return missions.map((mission) => (
      <option
        key={mission.id}
        value={mission.id}
      >
        {mission.name}
      </option>
    ));
  };

  roleOptionTags = () => {
    const { roles } = this.props;

    return roles.map((option) => (
      <option
        key={option}
        value={option}
      >
        {I18n.t(`role.${option}`)}
      </option>
    ));
  };

  missionRoleFields = () => {
    const { role, index } = this.props;

    return (
      <div className="assignment-row">
        <div className="mission">
          {this.missionField()}
        </div>
        <div className="role">
          <select
            className="form-control"
            defaultValue={role}
            name={`user[assignments_attributes][${index}][role]`}
          >
            {this.roleOptionTags()}
          </select>
        </div>
        {/* TODO: Improve a11y. */}
        {/* eslint-disable-next-line */}
        <a
          className="remove"
          onClick={this.handleRemoveClick}
        >
          <i className="fa fa-close" />
        </a>
      </div>
    );
  };

  handleRemoveClick = () => {
    this.setState({ destroy: true });
  };

  render() {
    const { index, id } = this.props;
    const { destroy } = this.state;

    return (
      <div>
        {destroy ? '' : this.missionRoleFields()}
        <input
          name={`user[assignments_attributes][${index}][_destroy]`}
          type="hidden"
          value={destroy}
        />
        <input
          name={`user[assignments_attributes][${index}][id]`}
          type="hidden"
          value={id || ''}
        />
      </div>
    );
  }
}

export default UserAssignmentFormField;
