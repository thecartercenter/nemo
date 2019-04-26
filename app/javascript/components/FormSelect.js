import React from 'react';
import PropTypes from 'prop-types';

class FormSelect extends React.Component {
  static propTypes = {
    id: PropTypes.string,
    includeBlank: PropTypes.bool,
    name: PropTypes.string,
    options: PropTypes.arrayOf(PropTypes.shape({
      id: PropTypes.string,
      name: PropTypes.string,
    })).isRequired,
    prompt: PropTypes.string,
    value: PropTypes.node,
    onChange: PropTypes.func,
  };

  static defaultProps = {
    includeBlank: true,
  };

  render() {
    const { options, prompt, includeBlank, name, id, value, onChange } = this.props;
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
      value: value || '',
      onChange: onChange ? (e) => onChange(e.target.value) : undefined,
    };

    return (
      <select {...props}>
        {optionTags}
      </select>
    );
  }
}

export default FormSelect;
