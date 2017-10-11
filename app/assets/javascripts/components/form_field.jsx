class FormField extends React.Component {
  render() {

    let content = [<FormLabel for={this.props.for} text={this.props.label} key="label"/>, <FormSelect key="select" name={this.props.name} id={this.props.id} options={this.props.options} />]
    return <div id="test-field" key="XYZ"> {content} </div>
  }
}
