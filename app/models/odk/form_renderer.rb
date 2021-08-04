# frozen_string_literal: true

module ODK
  # Renders ODK XML from a given form.
  class FormRenderer
    attr_accessor :form

    def initialize(form)
      self.form = form
    end

    def xml
      @xml ||= render
    end

    private

    def render
      decorated_form = ODK::DecoratorFactory.decorate(form)
      ApplicationController.render(template: "forms/show", format: :xml, assigns: {
        preferred_locales: mission_config.preferred_locales,
        form: decorated_form,
        questionings: ODK::DecoratorFactory.decorate_collection(form.questionings),
        option_sets: ODK::DecoratorFactory.decorate_collection(form.option_sets),
        option_sets_for_instances: ODK::DecoratorFactory.decorate_collection(
          decorated_form.option_sets_for_instances
        ),
        condition_computer: Forms::ConditionComputer.new(form)
      })
    end

    def mission_config
      @mission_config ||= Setting.for_mission(form.mission)
    end
  end
end
