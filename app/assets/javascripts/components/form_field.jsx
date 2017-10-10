class FormField extends React.Component {
  render() {

    let content = [<FormLabel text={this.props.label}/>, <FormSelect options={this.props.options}/>]
    return <div id="test-field"> {content} </div>
  }
}
