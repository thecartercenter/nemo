class ConditionsFormField extends React.Component {

  constructor(props) {
    super();
    this.getFieldData = this.getFieldData.bind(this)
    this.updateFieldData = this.updateFieldData.bind(this)
    this.formatRefQingOptions = this.formatRefQingOptions.bind(this)
    this.buildUrl = this.buildUrl.bind(this)
    this.state = props;
  }

  updateFieldData(ref_qing_id) {
    this.setState(this.getFieldData(ref_qing_id))
  }

  getFieldData(ref_qing_id) {
    ELMO.app.loading(true)
    var self = this;
    var url = this.buildUrl(ref_qing_id)
    $.ajax(url)
      .done(function(response) {
          self.setState(response);
        })
        .fail(function(jqXHR, exception){
          console.log(exception);
        })
        .always(function() {
          ELMO.app.loading(false)
        });
  }

  buildUrl(ref_qing_id) {
    var url = ELMO.app.url_builder.build('questionings', 'condition-form')
    url += '?ref_qing_id=' + ref_qing_id
    url += '&form_id=' + this.state.form_id
    url += '&questioning_id=' + this.state.questioning_id
    return url
  }

  formatRefQingOptions(reference_qing_options) {
    return reference_qing_options.map(function(o){
      return {id: o.id, name: `${o.rank}. ${o.code}`, key: o.id}
    })
  }

  render() {
    let condition_field = <input type="hidden" name="questioning[condition_attributes][id]" id="questioning_condition_attributes_id" key="questioning_condition_attributes_id" value={this.state.id}/>
    let rq_options =  this.state.refable_qing_options
    let ref_qing_form_field = <FormField name="questioning[condition_attributes][ref_qing_id]" for="questioning_condition_attributes_ref_qing_id" label={I18n.t('activerecord.attributes.condition.ref_qing_id')} type="select" options={this.formatRefQingOptions(rq_options)} id="questioning_condition_attributes_ref_qing_id" key="questioning_condition_attributes_ref_qing_id" changeFunc={this.updateFieldData} value={this.state.ref_qing_id}/>
    let operator_options =  this.state.operator_options
    let operator_form_field = <FormField name="questioning[condition_attributes][op]" for="questioning_condition_attributes_op" label={I18n.t('activerecord.attributes.condition.op')} type="select" options={operator_options} id="questioning_condition_attributes_op" key="questioning_condition_attributes_op" value={this.state.op}/>
    let value_options =  this.state.value_options
    let value_form_field =  <FormField name="questioning[condition_attributes][value]" for="questioning_condition_attributes_value" label={I18n.t('activerecord.attributes.condition.value')} type="text" id="questioning_condition_attributes_value" key="questioning_condition_attributes_value" options={value_options} value={this.state.value}/>
    let fields = [ref_qing_form_field, operator_form_field, value_form_field]
    return <div>{fields}</div>
  }
}
