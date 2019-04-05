import React from 'react';
import PropTypes from 'prop-types';

class FormSelect extends React.Component {
  static propTypes = {
    changeFunc: PropTypes.func,
    id: PropTypes.string,
    includeBlank: PropTypes.bool,
    name: PropTypes.string,
    options: PropTypes.arrayOf(PropTypes.shape({
      id: PropTypes.string,
      name: PropTypes.string,
    })).isRequired,
    prompt: PropTypes.string,
    value: PropTypes.node,
  };

  static defaultProps = {
    includeBlank: true,
  };

  render() {
    const { options, prompt, includeBlank, name, id, value, changeFunc } = this.props;
    const optionTags = [];
    if (prompt || includeBlank !== false) {
      optionTags.push(
        <option
          key="blank"
          value=""
        >
          {prompt || ''}
        </option>,
      );
    }
    options.forEach((o) => optionTags.push(
      <option
        key={o.id}
        value={o.id}
      >
        {o.name}
      </option>,
    ));
    const props = {
      className: 'form-control',
      name,
      id,
      key: id,
      defaultValue: value,
    };
    if (changeFunc) {
      props.onChange = (e) => changeFunc(e.target.value);
    }

    return (
      <select {...props}>
        {optionTags}
      </select>
    );
  }
}

export default FormSelect;
