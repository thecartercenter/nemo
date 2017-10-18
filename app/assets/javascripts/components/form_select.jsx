class FormSelect extends React.Component {
  render() {
    let options = [<option value="" value={this.props.id}></option>]
    let full_options = options.concat(this.props.options.map((o) => {return <option value={o.id} key={o.value}>{o.name}</option>}))
    return <select className="form-control test-select" name={this.props.name} id={this.props.id} key={this.props.id} onChange={this.props.changeFunc}>{full_options}</select>
  }
}
