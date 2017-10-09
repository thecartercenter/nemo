class FormField extends React.Component {
  render() {
    let content = [<FormLabel/>, <FormSelect/>]
    return <div id="test-field"> {content} </div>
  }
}
