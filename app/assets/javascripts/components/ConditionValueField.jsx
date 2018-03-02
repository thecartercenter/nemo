class ConditionValueField extends React.Component {
  render() {
    if (this.props.type === "cascading_select") {
      return <CascadingSelect {...this.props} />;
    } else {
      return (<input
        className="text form-control"
        defaultValue={this.props.value}
        id={this.props.id}
        key="input"
        name={this.props.name}
        type="text" />);
    }
  }
}

ConditionValueField.propTypes = {
  id: React.PropTypes.string.isRequired,
  name: React.PropTypes.string,
  type: React.PropTypes.string.isRequired,
  value: React.PropTypes.string
};

// These are not needed for CascadingSelect
ConditionValueField.defaultProps = {
  name: null,
  value: null
};
