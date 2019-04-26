import React from 'react';
import PropTypes from 'prop-types';

import CascadingSelect from './CascadingSelect';

class ConditionValueField extends React.Component {
  static propTypes = {
    id: PropTypes.string.isRequired,
    name: PropTypes.string,
    type: PropTypes.string.isRequired,
    value: PropTypes.string,
  };

  // These are not needed for CascadingSelect
  static defaultProps = {
    name: null,
    value: null,
  };

  render() {
    const { type, value, id, name } = this.props;

    if (type === 'cascading_select') {
      return <CascadingSelect {...this.props} />;
    }

    return (
      <input
        className="text form-control"
        defaultValue={value}
        id={id}
        key="input"
        name={name}
        type="text"
      />
    );
  }
}

export default ConditionValueField;
