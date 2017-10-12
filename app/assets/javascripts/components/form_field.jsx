class FormField extends React.Component {
  render() {
    var control = <input className="text form-control" type="text" name="questioning[condition_attributes][value]" id="questioning_condition_attributes_value" />
    if (this.props.type === "select") {
      control = <FormSelect key="select" name={this.props.name} id={this.props.id} options={this.props.options} changeFunc={this.props.changeFunc} />
    }
    let content = [<FormLabel for={this.props.for} text={this.props.label} key="label"/>, control]
    return <div id="test-field" key="XYZ"> {content} </div>
  }
}
