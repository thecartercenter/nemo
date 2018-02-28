class FormSelect extends React.Component {
  render() {
    let options = this.props.options;
    let optionTags = [];
    if (this.props.prompt || this.props.includeBlank !== false) {
      optionTags.push(<option
        key="blank"
        value="">
        {this.props.prompt || ""}
      </option>);
    }
    options.forEach((o) => optionTags.push(<option
      key={o.id}
      value={o.id}>
      {o.name}
    </option>));
    let props = {
      className: "form-control",
      name: this.props.name,
      id: this.props.id,
      key: this.props.id,
      defaultValue: this.props.value
    };
    if (this.props.changeFunc) {
      props["onChange"] = (e) => this.props.changeFunc(e.target.value);
    }
    return (
      <select {...props} >
        {optionTags}
      </select>
    );
  }
}

FormSelect.propTypes = {
  changeFunc: React.PropTypes.func,
  id: React.PropTypes.string,
  includeBlank: React.PropTypes.bool,
  name: React.PropTypes.string,
  options: React.PropTypes.arrayOf(React.PropTypes.shape({
    id: React.PropTypes.string,
    name: React.PropTypes.string
  })).isRequired,
  prompt: React.PropTypes.string,
  value: React.PropTypes.node
};

FormSelect.defaultProps = {
  changeFunc: null,
  id: null,
  includeBlank: true,
  name: null,
  prompt: null,
  value: null
};
