# frozen_string_literal: true

class DataExportService
  include ActiveModel::Model

  attr_accessor :mission, :user, :export_type, :filters, :format, :include_media

  EXPORT_TYPES = %w[responses forms users reports].freeze
  EXPORT_FORMATS = %w[csv excel pdf json xml].freeze

  validates :mission, presence: true
  validates :user, presence: true
  validates :export_type, inclusion: {in: EXPORT_TYPES}
  validates :format, inclusion: {in: EXPORT_FORMATS}

  def initialize(attributes = {})
    super
    @filters ||= {}
    @include_media ||= false
  end

  def export
    return false unless valid?

    case export_type
    when "responses"
      export_responses
    when "forms"
      export_forms
    when "users"
      export_users
    when "reports"
      export_reports
    end
  end

  def filename
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    "#{export_type}_#{mission.shortcode}_#{timestamp}.#{format}"
  end

  private

  def export_responses
    responses = Response.accessible_by(user.ability)
      .where(mission: mission)
      .includes(:form, :user, :answers)

    responses = apply_filters(responses) if filters.present?

    case format
    when "csv"
      export_responses_csv(responses)
    when "excel"
      export_responses_excel(responses)
    when "pdf"
      export_responses_pdf(responses)
    when "json"
      export_responses_json(responses)
    when "xml"
      export_responses_xml(responses)
    end
  end

  def export_forms
    forms = Form.accessible_by(user.ability)
      .where(mission: mission)
      .includes(:questions, :responses)

    case format
    when "csv"
      export_forms_csv(forms)
    when "excel"
      export_forms_excel(forms)
    when "pdf"
      export_forms_pdf(forms)
    when "json"
      export_forms_json(forms)
    when "xml"
      export_forms_xml(forms)
    end
  end

  def export_users
    users = User.joins(:assignments)
      .where(assignments: {mission: mission})
      .includes(:assignments, :responses)

    case format
    when "csv"
      export_users_csv(users)
    when "excel"
      export_users_excel(users)
    when "pdf"
      export_users_pdf(users)
    when "json"
      export_users_json(users)
    when "xml"
      export_users_xml(users)
    end
  end

  def export_reports
    reports = Report::Report.accessible_by(user.ability)
      .where(mission: mission)

    case format
    when "csv"
      export_reports_csv(reports)
    when "excel"
      export_reports_excel(reports)
    when "pdf"
      export_reports_pdf(reports)
    when "json"
      export_reports_json(reports)
    when "xml"
      export_reports_xml(reports)
    end
  end

  def apply_filters(responses)
    if filters[:date_from] && filters[:date_to]
      responses = responses.where(created_at: filters[:date_from]..filters[:date_to])
    end
    responses = responses.where(form_id: filters[:form_ids]) if filters[:form_ids].present?
    responses = responses.where(user_id: filters[:user_ids]) if filters[:user_ids].present?
    responses = responses.where(source: filters[:sources]) if filters[:sources].present?
    responses = responses.where(incomplete: filters[:incomplete]) if filters[:incomplete].present?
    responses
  end

  def export_responses_csv(responses)
    CSV.generate do |csv|
      # Headers
      headers = ["Response ID", "Form Name", "Submitter", "Source", "Status", "Created At", "Updated At"]

      # Add question headers
      question_headers = responses.joins(:answers)
        .joins("JOIN questionings ON answers.questioning_id = questionings.id")
        .joins("JOIN questions ON questionings.question_id = questions.id")
        .pluck("questions.code")
        .uniq
        .sort

      csv << (headers + question_headers)

      # Data rows
      responses.find_each do |response|
        row = [
          response.shortcode,
          response.form.name,
          response.user.name,
          response.source,
          response.incomplete? ? "Incomplete" : "Complete",
          response.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          response.updated_at.strftime("%Y-%m-%d %H:%M:%S")
        ]

        # Add answer values
        answers_by_question = response.answers.includes(:questioning).index_by { |a| a.questioning.question.code }
        question_headers.each do |code|
          answer = answers_by_question[code]
          row << (answer&.value || "")
        end

        csv << row
      end
    end
  end

  def export_responses_excel(responses)
    # This would use a gem like axlsx or rubyXL
    # For now, return CSV format
    export_responses_csv(responses)
  end

  def export_responses_pdf(responses)
    # This would use a gem like prawn
    # For now, return a simple text format
    content = "Response Export Report\n"
    content += "Mission: #{mission.name}\n"
    content += "Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}\n"
    content += "Total Responses: #{responses.count}\n\n"

    responses.find_each do |response|
      content += "Response ID: #{response.shortcode}\n"
      content += "Form: #{response.form.name}\n"
      content += "Submitter: #{response.user.name}\n"
      content += "Source: #{response.source}\n"
      content += "Status: #{response.incomplete? ? 'Incomplete' : 'Complete'}\n"
      content += "Created: #{response.created_at.strftime('%Y-%m-%d %H:%M:%S')}\n"
      content += "---\n"
    end

    content
  end

  def export_responses_json(responses)
    {
      mission: {
        id: mission.id,
        name: mission.name,
        shortcode: mission.shortcode
      },
      export_info: {
        type: "responses",
        format: "json",
        generated_at: Time.current.iso8601,
        total_count: responses.count
      },
      responses: responses.map do |response|
        {
          id: response.id,
          shortcode: response.shortcode,
          form: {
            id: response.form.id,
            name: response.form.name
          },
          user: {
            id: response.user.id,
            name: response.user.name
          },
          source: response.source,
          incomplete: response.incomplete?,
          created_at: response.created_at.iso8601,
          updated_at: response.updated_at.iso8601,
          answers: response.answers.map do |answer|
            {
              question_code: answer.questioning.question.code,
              question_text: answer.questioning.question.name,
              value: answer.value,
              created_at: answer.created_at.iso8601
            }
          end
        }
      end
    }.to_json
  end

  def export_responses_xml(responses)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.export do
        xml.mission do
          xml.id(mission.id)
          xml.name(mission.name)
          xml.shortcode(mission.shortcode)
        end

        xml.export_info do
          xml.type("responses")
          xml.format("xml")
          xml.generated_at(Time.current.iso8601)
          xml.total_count(responses.count)
        end

        xml.responses do
          responses.find_each do |response|
            xml.response do
              xml.id(response.id)
              xml.shortcode(response.shortcode)
              xml.form do
                xml.id(response.form.id)
                xml.name(response.form.name)
              end
              xml.user do
                xml.id(response.user.id)
                xml.name(response.user.name)
              end
              xml.source(response.source)
              xml.incomplete(response.incomplete?)
              xml.created_at(response.created_at.iso8601)
              xml.updated_at(response.updated_at.iso8601)

              xml.answers do
                response.answers.each do |answer|
                  xml.answer do
                    xml.question_code(answer.questioning.question.code)
                    xml.question_text(answer.questioning.question.name)
                    xml.value(answer.value)
                    xml.created_at(answer.created_at.iso8601)
                  end
                end
              end
            end
          end
        end
      end
    end

    builder.to_xml
  end

  # Similar methods for forms, users, and reports...
  def export_forms_csv(forms)
    CSV.generate do |csv|
      csv << ["Form ID", "Name", "Status", "Questions Count", "Responses Count", "Created At", "Updated At"]

      forms.find_each do |form|
        csv << [
          form.id,
          form.name,
          form.status,
          form.questions.count,
          form.responses.count,
          form.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          form.updated_at.strftime("%Y-%m-%d %H:%M:%S")
        ]
      end
    end
  end

  def export_forms_excel(forms)
    export_forms_csv(forms)
  end

  def export_forms_pdf(forms)
    content = "Forms Export Report\n"
    content += "Mission: #{mission.name}\n"
    content += "Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}\n"
    content += "Total Forms: #{forms.count}\n\n"

    forms.find_each do |form|
      content += "Form: #{form.name}\n"
      content += "Status: #{form.status}\n"
      content += "Questions: #{form.questions.count}\n"
      content += "Responses: #{form.responses.count}\n"
      content += "---\n"
    end

    content
  end

  def export_forms_json(forms)
    {
      mission: {
        id: mission.id,
        name: mission.name,
        shortcode: mission.shortcode
      },
      export_info: {
        type: "forms",
        format: "json",
        generated_at: Time.current.iso8601,
        total_count: forms.count
      },
      forms: forms.map do |form|
        {
          id: form.id,
          name: form.name,
          status: form.status,
          questions_count: form.questions.count,
          responses_count: form.responses.count,
          created_at: form.created_at.iso8601,
          updated_at: form.updated_at.iso8601
        }
      end
    }.to_json
  end

  def export_forms_xml(forms)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.export do
        xml.mission do
          xml.id(mission.id)
          xml.name(mission.name)
          xml.shortcode(mission.shortcode)
        end

        xml.export_info do
          xml.type("forms")
          xml.format("xml")
          xml.generated_at(Time.current.iso8601)
          xml.total_count(forms.count)
        end

        xml.forms do
          forms.find_each do |form|
            xml.form do
              xml.id(form.id)
              xml.name(form.name)
              xml.status(form.status)
              xml.questions_count(form.questions.count)
              xml.responses_count(form.responses.count)
              xml.created_at(form.created_at.iso8601)
              xml.updated_at(form.updated_at.iso8601)
            end
          end
        end
      end
    end

    builder.to_xml
  end

  def export_users_csv(users)
    CSV.generate do |csv|
      csv << ["User ID", "Name", "Login", "Email", "Role", "Active", "Responses Count", "Created At"]

      users.find_each do |user|
        assignment = user.assignments.find_by(mission: mission)
        csv << [
          user.id,
          user.name,
          user.login,
          user.email,
          assignment&.role || "N/A",
          user.active? ? "Yes" : "No",
          user.responses.where(mission: mission).count,
          user.created_at.strftime("%Y-%m-%d %H:%M:%S")
        ]
      end
    end
  end

  def export_users_excel(users)
    export_users_csv(users)
  end

  def export_users_pdf(users)
    content = "Users Export Report\n"
    content += "Mission: #{mission.name}\n"
    content += "Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}\n"
    content += "Total Users: #{users.count}\n\n"

    users.find_each do |user|
      assignment = user.assignments.find_by(mission: mission)
      content += "User: #{user.name}\n"
      content += "Login: #{user.login}\n"
      content += "Email: #{user.email}\n"
      content += "Role: #{assignment&.role || 'N/A'}\n"
      content += "Active: #{user.active? ? 'Yes' : 'No'}\n"
      content += "Responses: #{user.responses.where(mission: mission).count}\n"
      content += "---\n"
    end

    content
  end

  def export_users_json(users)
    {
      mission: {
        id: mission.id,
        name: mission.name,
        shortcode: mission.shortcode
      },
      export_info: {
        type: "users",
        format: "json",
        generated_at: Time.current.iso8601,
        total_count: users.count
      },
      users: users.map do |user|
        assignment = user.assignments.find_by(mission: mission)
        {
          id: user.id,
          name: user.name,
          login: user.login,
          email: user.email,
          role: assignment&.role,
          active: user.active?,
          responses_count: user.responses.where(mission: mission).count,
          created_at: user.created_at.iso8601
        }
      end
    }.to_json
  end

  def export_users_xml(users)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.export do
        xml.mission do
          xml.id(mission.id)
          xml.name(mission.name)
          xml.shortcode(mission.shortcode)
        end

        xml.export_info do
          xml.type("users")
          xml.format("xml")
          xml.generated_at(Time.current.iso8601)
          xml.total_count(users.count)
        end

        xml.users do
          users.find_each do |user|
            assignment = user.assignments.find_by(mission: mission)
            xml.user do
              xml.id(user.id)
              xml.name(user.name)
              xml.login(user.login)
              xml.email(user.email)
              xml.role(assignment&.role)
              xml.active(user.active?)
              xml.responses_count(user.responses.where(mission: mission).count)
              xml.created_at(user.created_at.iso8601)
            end
          end
        end
      end
    end

    builder.to_xml
  end

  def export_reports_csv(reports)
    CSV.generate do |csv|
      csv << ["Report ID", "Name", "Type", "Creator", "View Count", "Created At", "Updated At"]

      reports.find_each do |report|
        csv << [
          report.id,
          report.name,
          report.type,
          report.creator&.name || "N/A",
          report.view_count,
          report.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          report.updated_at.strftime("%Y-%m-%d %H:%M:%S")
        ]
      end
    end
  end

  def export_reports_excel(reports)
    export_reports_csv(reports)
  end

  def export_reports_pdf(reports)
    content = "Reports Export Report\n"
    content += "Mission: #{mission.name}\n"
    content += "Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}\n"
    content += "Total Reports: #{reports.count}\n\n"

    reports.find_each do |report|
      content += "Report: #{report.name}\n"
      content += "Type: #{report.type}\n"
      content += "Creator: #{report.creator&.name || 'N/A'}\n"
      content += "Views: #{report.view_count}\n"
      content += "---\n"
    end

    content
  end

  def export_reports_json(reports)
    {
      mission: {
        id: mission.id,
        name: mission.name,
        shortcode: mission.shortcode
      },
      export_info: {
        type: "reports",
        format: "json",
        generated_at: Time.current.iso8601,
        total_count: reports.count
      },
      reports: reports.map do |report|
        {
          id: report.id,
          name: report.name,
          type: report.type,
          creator: report.creator&.name,
          view_count: report.view_count,
          created_at: report.created_at.iso8601,
          updated_at: report.updated_at.iso8601
        }
      end
    }.to_json
  end

  def export_reports_xml(reports)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.export do
        xml.mission do
          xml.id(mission.id)
          xml.name(mission.name)
          xml.shortcode(mission.shortcode)
        end

        xml.export_info do
          xml.type("reports")
          xml.format("xml")
          xml.generated_at(Time.current.iso8601)
          xml.total_count(reports.count)
        end

        xml.reports do
          reports.find_each do |report|
            xml.report do
              xml.id(report.id)
              xml.name(report.name)
              xml.type(report.type)
              xml.creator(report.creator&.name)
              xml.view_count(report.view_count)
              xml.created_at(report.created_at.iso8601)
              xml.updated_at(report.updated_at.iso8601)
            end
          end
        end
      end
    end

    builder.to_xml
  end
end
