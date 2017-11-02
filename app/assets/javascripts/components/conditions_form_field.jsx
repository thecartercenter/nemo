class ConditionsFormField extends React.Component {

  constructor() {
    console.log("constrcutore")
    super();

    this.name_prefix = "questioning[condition_attributes]"
    this.for_prefix = "questioning_condition_attributes"
    this.getFieldData = this.getFieldData.bind(this)
    this.updateFieldData = this.updateFieldData.bind(this)
    this.formatRefQingOptions = this.formatRefQingOptions.bind(this)

  }

  updateFieldData(ref_qing_id) {
    console.log("updateFieldData!")
    this.setState(this.getFieldData(ref_qing_id))
  }

  getFieldData(ref_qing_id) {
    var self = this;
    $.ajax({
      method: 'GET',
      //url: `/en/m/questionings/fakemission2169/condition-form`,
      url: "/json",
      success: function(response) {
        console.log(response)
        console.log("success!")
        self.setState({response})
      },
      error: function(res) {
        console.log(res)
        console.log("error!")
      }
    });
  }


    ///////////////////
    // console.log("get field data! ref_qing_id:")
    // console.log(ref_qing_id)
    // //fake data first
    // let reference_qing_options = [{id: 123, code: "One", rank: 1}, {id: 456, code: "Two", rank: 2}, {id: 789, code: "Three", rank: 3}]
    // //let reference_qing_data = {for: "questioning_condition_attributes_ref_qing_id", label: "question", name: "questioning[condition_attributes][ref_qing_id]", id: "questioning_condition_attributes_ref_qing_id", type: "select", options: reference_qing_options}
    //
    // let operator_options = (ref_qing_id == 456) ? [{id: "A", name: "Amandla"}, {id: "B", name: "Beyonce"}] : []
    // //let operator_data = {for: "questioning_condition_attributes_op", label: "operator", name: "questioning[condition_attributes][op]", id: "questioning_condition_attributes_op", type: "select", options: operator_options }
    //
    // let value_options = (ref_qing_id == 456) ? [{id: "D", name: "Destiny's Child"}, {id: "S", name: "Sasha Fierce"}, {id: "L", name: "Lemonade"}] : []
    // //let value_data = {for: "questioning_condition_attributes_value" , label: "Value", name: "questioning[condition_attributes][value]" , id: "questioning_condition_attributes_value" , type: "text"}
    //
    // return {reference_qing_options : reference_qing_options, operator_options: operator_options, value_options: value_options}


  formatRefQingOptions(reference_qing_options) {
    return reference_qing_options.map(function(o){
      return {id: o.id, name: `${o.rank}. ${o.code}`, key: o.id}
    })
  }

  componentWillMount() {
    console.log("component will mount")
    this.state = this.getFieldData()
  }

  render() {
    console.log("render")
    let rq_options = this.state ? this.state.reference_qing_options : this.props.reference_qing_options
    let ref_qing_form_field = <FormField name="questioning[condition_attributes][ref_qing_id]" for="questioning_condition_attributes_ref_qing_id" label="Question TO TRANSLATE" type="select" options={this.formatRefQingOptions(rq_options)} id="questioning_condition_attributes_ref_qing_id" key="questioning_condition_attributes_ref_qing_id" changeFunc={this.updateFieldData}/>
    let operator_options = this.state ? this.state.operator_options : this.props.operator_options
    let operator_form_field = <FormField name="questioning[condition_attributes][op]" for="questioning_condition_attributes_op" label="Operator TO TRANSLATE" type="select" options={operator_options} id="questioning_condition_attributes_op" key="questioning_condition_attributes_op"/>
    let value_options = this.state ? this.state.value_options : this.props.value_options
    let value_form_field =  <FormField name="questioning[condition_attributes][value]" for="questioning_condition_attributes_value" label="Value TO TRANSLATE" type="text" id="questioning_condition_attributes_value" key="questioning_condition_attributes_value" options={value_options}/>
    let fields = [ref_qing_form_field, operator_form_field, value_form_field]
    return <div>{fields}</div>
  }
}
