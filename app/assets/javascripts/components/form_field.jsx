class FormField extends React.Component {
  render() {

    let content = [<FormLabel for={this.props.for} text={this.props.label}/>, <FormSelect name={this.props.name} id={this.props.id} options={this.props.options}/>]
    return <div id="test-field"> {content} </div>
  }
}
