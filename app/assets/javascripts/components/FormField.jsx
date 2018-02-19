class FormField extends React.Component {
  render() {
    if (this.props.type === "select") {
      return (<FormSelect
        changeFunc={this.props.changeFunc}
        id={this.props.id}
        key="input"
        name={this.props.name}
        options={this.props.options}
        value={this.props.value} />);
    } else if (this.props.type === "cascading_select") {
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
