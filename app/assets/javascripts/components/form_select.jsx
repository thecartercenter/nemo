class FormSelect extends React.Component {
  render() {
    let options = [<option value=""></option>]

    let full_options = options.concat(this.props.options.map((o) => {return <option value={o.value} key={o.value}>{o.display}</option>}))
    return <select className="form-control test-select" name={this.props.name} id={this.props.id}>{full_options}</select>
  }
}
