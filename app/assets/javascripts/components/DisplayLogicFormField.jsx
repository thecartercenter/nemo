class DisplayLogicFormField extends React.Component {


  constructor(props) {
    super();
    this.state = props;
    this.conditionFields = props.display_conditions.map((props) =>
      <ConditionsFormField {...props}/>);
    console.log(this.state);
  }

  render() {
    return (
      <div>
        <div className="form_field questioning_display_if" id="display_if" data-field-name="display_if">
          <div className="label_and_control">
            <label className="main" for="questioning_display_if">Display Logic:</label>
            <div className="control ">
              <div className="widget">
                <select className="form-control" name="questioning[display_if]" id="questioning_display_if" value={this.state.display_if}>
                  <option value="always">Always display this question.</option>
                  <option value="all_met">Display this question if all of these conditions are met.</option>
                  <option value="any_met">Display this question if any of these conditions are met.</option>
                </select>
              </div>
            </div>
          </div>
        </div>
        {this.conditionFields}
      </div>
    );
  }
}
