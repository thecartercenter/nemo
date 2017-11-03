class FormSelect extends React.Component {
  render() {
    let options = [<option value="" value={this.props.id} key="blank"></option>]
    let full_options = options.concat(this.props.options.map((o) => {return <option value={o.id} key={o.id}>{o.name}</option>}))
    let props = {
      className : "form-control test-select",
      name : this.props.name,
      id: this.props.id,
      key: this.props.id,
      defaultValue: this.props.value
    }
    if (this.props.changeFunc) {
      props["onChange"] = (e) => this.props.changeFunc(e.target.value)
    }
    return <select {...props} >{full_options}</select>
  //  return <select className="form-control test-select" name={this.props.name} id={this.props.id} key={this.props.id} onChange={(e) => this.props.changeFunc(e.target.value)}>{full_options}</select>
  }
}
