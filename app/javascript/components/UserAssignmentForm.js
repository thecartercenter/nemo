import React from 'react';
import PropTypes from 'prop-types';

import UserAssignmentFormField from './UserAssignmentFormField';

/**
 * User assignments form in edit user in admin mode.
 * Models the whole form consisting of rows of UserAssignmentFormFields.
 */
class UserAssignmentForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = { assignments: props.assignments };
    this.handleAddClick = this.handleAddClick.bind(this);
  }

  handleAddClick() {
    this.setState((curState) => {
      const newAssignments = [{ key: Math.round(Math.random() * 100000000), newRecord: true }];
      return { assignments: curState.assignments.concat(newAssignments) };
    });
  }

  render() {
    const { missions, roles } = this.props;
    const { assignments } = this.state;
    return (
      <div className="assignments">
        <div>
          {assignments.map(
            (assignment, idx) => (
              <UserAssignmentFormField
                {...assignment}
                index={idx}
                key={assignment.key || assignment.id}
                missions={missions}
                roles={roles}
              />
            ),
          )}
        </div>
        <div>
          {/* TODO: Improve a11y. */}
          {/* eslint-disable-next-line */}
          <a
            className="add-assignment"
            onClick={this.handleAddClick}
          >
            <i className="fa fa-plus" />
            &nbsp;
            {I18n.t('user.add_assignment')}
          </a>
        </div>
      </div>
    );
  }
}

UserAssignmentForm.propTypes = {
  assignments: PropTypes.arrayOf(PropTypes.object).isRequired,
  missions: PropTypes.arrayOf(PropTypes.object).isRequired,
  roles: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default UserAssignmentForm;
