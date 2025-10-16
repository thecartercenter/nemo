# frozen_string_literal: true

class AiValidationService
  def self.validate_response(response)
    return unless response.mission

    # Get active AI validation rules for this mission
    rules = AiValidationRule.active
                            .where(mission: response.mission)
                            .where(rule_type: determine_applicable_rules(response))

    results = []
    
    rules.find_each do |rule|
      begin
        result = rule.validate_response(response)
        results << result if result
      rescue => e
        Rails.logger.error "AI validation failed for rule #{rule.id}: #{e.message}"
        # Create a failed result for tracking
        results << rule.ai_validation_results.create!(
          response: response,
          validation_type: rule.rule_type,
          confidence_score: 0.0,
          is_valid: false,
          issues: ["Validation error: #{e.message}"],
          suggestions: ["Please check the validation rule configuration"],
          explanation: "AI validation failed due to an error",
          passed: false
        )
      end
    end

    # Trigger notifications for failed validations
    notify_validation_failures(response, results.select { |r| !r.passed? })

    results
  end

  def self.validate_batch(responses)
    results = []
    
    responses.find_each do |response|
      results.concat(validate_response(response))
    end

    results
  end

  def self.generate_validation_report(mission, date_range = nil)
    query = AiValidationResult.joins(:response)
                              .where(responses: { mission: mission })
    
    query = query.where('ai_validation_results.created_at >= ?', date_range.begin) if date_range&.begin
    query = query.where('ai_validation_results.created_at <= ?', date_range.end) if date_range&.end

    results = query.includes(:ai_validation_rule, :response)

    {
      total_validations: results.count,
      passed_validations: results.passed.count,
      failed_validations: results.failed.count,
      pass_rate: calculate_pass_rate(results),
      by_rule_type: group_by_rule_type(results),
      by_severity: group_by_severity(results),
      common_issues: find_common_issues(results),
      recommendations: generate_recommendations(results)
    }
  end

  def self.suggest_validation_rules(mission)
    # Analyze existing data to suggest validation rules
    suggestions = []

    # Analyze form responses for patterns
    forms = Form.where(mission: mission).includes(:responses, :questions)
    
    forms.each do |form|
      # Suggest data quality rules
      if has_text_fields?(form)
        suggestions << {
          type: 'data_quality',
          name: "Data Quality Check - #{form.name}",
          description: "Check for spelling errors and formatting issues in text fields",
          confidence: 0.8
        }
      end

      # Suggest completeness rules
      if has_required_fields?(form)
        suggestions << {
          type: 'completeness_check',
          name: "Completeness Check - #{form.name}",
          description: "Ensure all required fields are completed",
          confidence: 0.9
        }
      end

      # Suggest format validation
      if has_date_fields?(form)
        suggestions << {
          type: 'format_validation',
          name: "Date Format Validation - #{form.name}",
          description: "Validate date formats and ranges",
          confidence: 0.7
        }
      end

      # Suggest anomaly detection
      if has_numeric_fields?(form)
        suggestions << {
          type: 'anomaly_detection',
          name: "Anomaly Detection - #{form.name}",
          description: "Detect unusual values in numeric fields",
          confidence: 0.6
        }
      end
    end

    suggestions.sort_by { |s| -s[:confidence] }
  end

  private

  def self.determine_applicable_rules(response)
    # Determine which validation rules are applicable based on response characteristics
    applicable_rules = ['data_quality', 'consistency_check']

    # Add specific rules based on form characteristics
    if response.form.questions.any? { |q| q.qtype_name == 'text' }
      applicable_rules << 'format_validation'
    end

    if response.form.questions.any? { |q| %w[integer decimal].include?(q.qtype_name) }
      applicable_rules << 'anomaly_detection'
      applicable_rules << 'outlier_detection'
    end

    if response.form.questions.any? { |q| q.required? }
      applicable_rules << 'completeness_check'
    end

    applicable_rules
  end

  def self.notify_validation_failures(response, failed_results)
    return if failed_results.empty?

    # Notify form coordinators about validation failures
    mission = response.mission
    coordinators = mission.users.joins(:assignments)
                          .where(assignments: { role: 'coordinator' })

    coordinators.find_each do |coordinator|
      Notification.create_for_user(
        coordinator,
        'ai_validation_failed',
        "AI Validation Failed: #{response.form.name}",
        message: "Response #{response.shortcode} failed AI validation checks",
        data: {
          response_id: response.id,
          form_id: response.form.id,
          failed_rules: failed_results.map(&:validation_type),
          issues: failed_results.flat_map(&:issues)
        },
        mission: mission
      )
    end
  end

  def self.calculate_pass_rate(results)
    return 0 if results.empty?
    
    (results.passed.count.to_f / results.count * 100).round(2)
  end

  def self.group_by_rule_type(results)
    results.group_by(&:validation_type).transform_values(&:count)
  end

  def self.group_by_severity(results)
    results.group_by(&:severity).transform_values(&:count)
  end

  def self.find_common_issues(results)
    all_issues = results.flat_map(&:issues)
    issue_counts = all_issues.tally
    issue_counts.sort_by { |_, count| -count }.first(10)
  end

  def self.generate_recommendations(results)
    recommendations = []

    if results.failed.count > results.count * 0.3
      recommendations << "Consider reviewing validation rules - high failure rate detected"
    end

    if results.low_confidence.count > results.count * 0.2
      recommendations << "Many low-confidence validations - consider adjusting AI model or thresholds"
    end

    common_issues = find_common_issues(results)
    if common_issues.any?
      recommendations << "Most common issues: #{common_issues.first(3).map(&:first).join(', ')}"
    end

    recommendations
  end

  def self.has_text_fields?(form)
    form.questions.any? { |q| q.qtype_name == 'text' }
  end

  def self.has_required_fields?(form)
    form.questions.any?(&:required?)
  end

  def self.has_date_fields?(form)
    form.questions.any? { |q| q.qtype_name == 'date' }
  end

  def self.has_numeric_fields?(form)
    form.questions.any? { |q| %w[integer decimal].include?(q.qtype_name) }
  end
end