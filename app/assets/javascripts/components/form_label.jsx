class FormLabel extends React.Component {
  render() {
    return <label htmlFor={this.props.for}> {this.props.text} </label>
  }
}
