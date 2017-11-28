class FormField extends React.Component {
  render() {
    //default to text
    var control = <input
      className="text form-control"
      key="input"
      type="text"
      name={this.props.name}
      id={this.props.id}
      defaultValue={this.props.value}
     />
    if (this.props.type === "select") {
      control = <FormSelect value={this.props.value}
        key="input"
        name={this.props.name}
        id={this.props.id}
        options={this.props.options}
        changeFunc={this.props.changeFunc}
      />
    }
    if (this.props.type === "cascading_select") {
      control = <CascadingSelect
        {...this.props}
        />
    }
    return (
      <div className="field">
        <label htmlFor={this.props.for} key={this.props.for}>{this.props.label}</label>
        {control}
      </div>
    );
  }
}
