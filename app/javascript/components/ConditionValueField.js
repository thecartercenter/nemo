import React from 'react';
import PropTypes from 'prop-types';

import CascadingSelect from './CascadingSelect';

class ConditionValueField extends React.Component {
  static propTypes = {
    id: PropTypes.string.isRequired,
    name: PropTypes.string,
    type: PropTypes.string.isRequired,
    value: PropTypes.string,
    onChange: PropTypes.func,
  };

  render() {
    const { type, value, id, name, onChange } = this.props;

    if (type === 'cascading_select') {
      return <CascadingSelect {...this.props} />;
    }

    return (
      <input
        className="text form-control"
        value={value}
        id={id}
        key="input"
        name={name}
        type="text"
        onChange={onChange ? (e) => onChange(e.target.value) : undefined}
      />
    );
  }
}

export default ConditionValueField;
