class FormField extends React.Component {
  render() {
    if (this.props.type === "select") {
      return <FormSelect value={this.props.value}
        key="input"
        name={this.props.name}
        id={this.props.id}
        options={this.props.options}
        changeFunc={this.props.changeFunc} />
    } else if (this.props.type === "cascading_select") {
      return <CascadingSelect {...this.props} />
    } else {
      return <input
        className="text form-control"
        key="input"
        type="text"
        name={this.props.name}
        id={this.props.id}
        defaultValue={this.props.value} />
    }
  }
}
