# frozen_string_literal: true

class BackupService
  include ActiveModel::Model
  
  attr_accessor :mission, :user, :backup_type, :include_media, :include_audit_logs

  BACKUP_TYPES = %w[full mission_data forms_only responses_only].freeze

  validates :mission, presence: true
  validates :user, presence: true
  validates :backup_type, inclusion: { in: BACKUP_TYPES }

  def initialize(attributes = {})
    super
    @include_media ||= false
    @include_audit_logs ||= false
  end

  def create_backup
    return false unless valid?

    backup_id = SecureRandom.uuid
    backup_dir = Rails.root.join('tmp', 'backups', backup_id)
    FileUtils.mkdir_p(backup_dir)

    begin
      case backup_type
      when 'full'
        create_full_backup(backup_dir)
      when 'mission_data'
        create_mission_backup(backup_dir)
      when 'forms_only'
        create_forms_backup(backup_dir)
      when 'responses_only'
        create_responses_backup(backup_dir)
      end

      # Create backup metadata
      create_backup_metadata(backup_dir, backup_id)

      # Compress backup
      compressed_file = compress_backup(backup_dir, backup_id)

      # Store backup record
      backup_record = create_backup_record(backup_id, compressed_file)

      # Clean up temporary directory
      FileUtils.rm_rf(backup_dir)

      backup_record
    rescue => e
      # Clean up on error
      FileUtils.rm_rf(backup_dir) if Dir.exist?(backup_dir)
      raise e
    end
  end

  def self.restore_backup(backup_file, user, mission = nil)
    backup_dir = extract_backup(backup_file)
    
    begin
      metadata = load_backup_metadata(backup_dir)
      
      case metadata['backup_type']
      when 'full'
        restore_full_backup(backup_dir, user, mission)
      when 'mission_data'
        restore_mission_backup(backup_dir, user, mission)
      when 'forms_only'
        restore_forms_backup(backup_dir, user, mission)
      when 'responses_only'
        restore_responses_backup(backup_dir, user, mission)
      end
      
      true
    ensure
      FileUtils.rm_rf(backup_dir) if Dir.exist?(backup_dir)
    end
  end

  private

  def create_full_backup(backup_dir)
    # Export all data for the mission
    export_mission_data(backup_dir)
    export_forms(backup_dir)
    export_responses(backup_dir)
    export_users(backup_dir)
    export_audit_logs(backup_dir) if include_audit_logs
    export_media(backup_dir) if include_media
  end

  def create_mission_backup(backup_dir)
    export_mission_data(backup_dir)
    export_forms(backup_dir)
    export_responses(backup_dir)
    export_audit_logs(backup_dir) if include_audit_logs
  end

  def create_forms_backup(backup_dir)
    export_forms(backup_dir)
  end

  def create_responses_backup(backup_dir)
    export_responses(backup_dir)
    export_media(backup_dir) if include_media
  end

  def export_mission_data(backup_dir)
    mission_data = {
      mission: {
        id: mission.id,
        name: mission.name,
        shortcode: mission.shortcode,
        created_at: mission.created_at,
        updated_at: mission.updated_at
      }
    }
    
    File.write(backup_dir.join('mission.json'), mission_data.to_json)
  end

  def export_forms(backup_dir)
    forms = Form.where(mission: mission).includes(:questions, :questionings)
    
    forms_data = forms.map do |form|
      {
        id: form.id,
        name: form.name,
        description: form.description,
        status: form.status,
        allow_incomplete: form.allow_incomplete,
        authenticate_sms: form.authenticate_sms,
        smsable: form.smsable,
        sms_relay: form.sms_relay,
        access_level: form.access_level,
        created_at: form.created_at,
        updated_at: form.updated_at,
        questions: form.questions.map do |question|
          {
            id: question.id,
            code: question.code,
            name: question.name,
            qtype_name: question.qtype_name,
            required: question.required?,
            created_at: question.created_at,
            updated_at: question.updated_at
          }
        end
      }
    end
    
    File.write(backup_dir.join('forms.json'), forms_data.to_json)
  end

  def export_responses(backup_dir)
    responses = Response.where(mission: mission).includes(:form, :user, :answers)
    
    responses_data = responses.map do |response|
      {
        id: response.id,
        shortcode: response.shortcode,
        form_id: response.form_id,
        user_id: response.user_id,
        source: response.source,
        incomplete: response.incomplete?,
        reviewed: response.reviewed?,
        reviewer_notes: response.reviewer_notes,
        device_id: response.device_id,
        created_at: response.created_at,
        updated_at: response.updated_at,
        answers: response.answers.map do |answer|
          {
            id: answer.id,
            questioning_id: answer.questioning_id,
            value: answer.value,
            created_at: answer.created_at,
            updated_at: answer.updated_at
          }
        end
      }
    end
    
    File.write(backup_dir.join('responses.json'), responses_data.to_json)
  end

  def export_users(backup_dir)
    users = User.joins(:assignments).where(assignments: { mission: mission }).distinct
    
    users_data = users.map do |user|
      assignment = user.assignments.find_by(mission: mission)
      {
        id: user.id,
        login: user.login,
        name: user.name,
        email: user.email,
        phone: user.phone,
        pref_lang: user.pref_lang,
        gender: user.gender,
        birth_year: user.birth_year,
        nationality: user.nationality,
        active: user.active?,
        role: assignment&.role,
        created_at: user.created_at,
        updated_at: user.updated_at
      }
    end
    
    File.write(backup_dir.join('users.json'), users_data.to_json)
  end

  def export_audit_logs(backup_dir)
    audit_logs = AuditLog.where(mission: mission)
    
    audit_logs_data = audit_logs.map do |log|
      {
        id: log.id,
        action: log.action,
        resource: log.resource,
        resource_id: log.resource_id,
        changes: log.changes,
        metadata: log.metadata,
        ip_address: log.ip_address,
        user_agent: log.user_agent,
        user_id: log.user_id,
        created_at: log.created_at,
        updated_at: log.updated_at
      }
    end
    
    File.write(backup_dir.join('audit_logs.json'), audit_logs_data.to_json)
  end

  def export_media(backup_dir)
    media_dir = backup_dir.join('media')
    FileUtils.mkdir_p(media_dir)
    
    # Export media files from responses
    Response.where(mission: mission).find_each do |response|
      response.answers.find_each do |answer|
        if answer.attachments.attached?
          answer.attachments.each do |attachment|
            file_path = media_dir.join("#{answer.id}_#{attachment.filename}")
            File.binwrite(file_path, attachment.download)
          end
        end
      end
    end
  end

  def create_backup_metadata(backup_dir, backup_id)
    metadata = {
      backup_id: backup_id,
      backup_type: backup_type,
      mission_id: mission.id,
      mission_name: mission.name,
      created_by: user.id,
      created_at: Time.current.iso8601,
      include_media: include_media,
      include_audit_logs: include_audit_logs,
      version: '1.0'
    }
    
    File.write(backup_dir.join('metadata.json'), metadata.to_json)
  end

  def compress_backup(backup_dir, backup_id)
    compressed_file = Rails.root.join('tmp', 'backups', "#{backup_id}.tar.gz")
    
    system("tar", "-czf", compressed_file.to_s, "-C", backup_dir.parent.to_s, backup_id)
    
    compressed_file
  end

  def create_backup_record(backup_id, compressed_file)
    Backup.create!(
      backup_id: backup_id,
      mission: mission,
      user: user,
      backup_type: backup_type,
      file_path: compressed_file.to_s,
      file_size: File.size(compressed_file),
      include_media: include_media,
      include_audit_logs: include_audit_logs
    )
  end

  def self.extract_backup(backup_file)
    backup_id = SecureRandom.uuid
    extract_dir = Rails.root.join('tmp', 'backups', backup_id)
    FileUtils.mkdir_p(extract_dir)
    
    system("tar", "-xzf", backup_file.to_s, "-C", extract_dir.to_s)
    
    extract_dir
  end

  def self.load_backup_metadata(backup_dir)
    metadata_file = backup_dir.join('metadata.json')
    JSON.parse(File.read(metadata_file))
  end

  def self.restore_full_backup(backup_dir, user, mission)
    restore_mission_data(backup_dir, user, mission)
    restore_forms(backup_dir, user, mission)
    restore_responses(backup_dir, user, mission)
    restore_users(backup_dir, user, mission)
    restore_audit_logs(backup_dir, user, mission)
    restore_media(backup_dir, user, mission)
  end

  def self.restore_mission_backup(backup_dir, user, mission)
    restore_mission_data(backup_dir, user, mission)
    restore_forms(backup_dir, user, mission)
    restore_responses(backup_dir, user, mission)
    restore_audit_logs(backup_dir, user, mission)
  end

  def self.restore_forms_backup(backup_dir, user, mission)
    restore_forms(backup_dir, user, mission)
  end

  def self.restore_responses_backup(backup_dir, user, mission)
    restore_responses(backup_dir, user, mission)
    restore_media(backup_dir, user, mission)
  end

  def self.restore_mission_data(backup_dir, user, mission)
    # Mission data restoration would be implemented here
    # This is a simplified version
  end

  def self.restore_forms(backup_dir, user, mission)
    forms_data = JSON.parse(File.read(backup_dir.join('forms.json')))
    
    forms_data.each do |form_data|
      form = Form.find_or_initialize_by(id: form_data['id'])
      form.assign_attributes(
        name: form_data['name'],
        description: form_data['description'],
        status: form_data['status'],
        allow_incomplete: form_data['allow_incomplete'],
        authenticate_sms: form_data['authenticate_sms'],
        smsable: form_data['smsable'],
        sms_relay: form_data['sms_relay'],
        access_level: form_data['access_level'],
        mission: mission
      )
      form.save!
    end
  end

  def self.restore_responses(backup_dir, user, mission)
    responses_data = JSON.parse(File.read(backup_dir.join('responses.json')))
    
    responses_data.each do |response_data|
      response = Response.find_or_initialize_by(id: response_data['id'])
      response.assign_attributes(
        shortcode: response_data['shortcode'],
        form_id: response_data['form_id'],
        user_id: response_data['user_id'],
        source: response_data['source'],
        incomplete: response_data['incomplete'],
        reviewed: response_data['reviewed'],
        reviewer_notes: response_data['reviewer_notes'],
        device_id: response_data['device_id'],
        mission: mission
      )
      response.save!
    end
  end

  def self.restore_users(backup_dir, user, mission)
    users_data = JSON.parse(File.read(backup_dir.join('users.json')))
    
    users_data.each do |user_data|
      user = User.find_or_initialize_by(id: user_data['id'])
      user.assign_attributes(
        login: user_data['login'],
        name: user_data['name'],
        email: user_data['email'],
        phone: user_data['phone'],
        pref_lang: user_data['pref_lang'],
        gender: user_data['gender'],
        birth_year: user_data['birth_year'],
        nationality: user_data['nationality'],
        active: user_data['active']
      )
      user.save!
      
      # Create assignment
      assignment = Assignment.find_or_initialize_by(user: user, mission: mission)
      assignment.role = user_data['role']
      assignment.save!
    end
  end

  def self.restore_audit_logs(backup_dir, user, mission)
    audit_logs_data = JSON.parse(File.read(backup_dir.join('audit_logs.json')))
    
    audit_logs_data.each do |log_data|
      log = AuditLog.find_or_initialize_by(id: log_data['id'])
      log.assign_attributes(
        action: log_data['action'],
        resource: log_data['resource'],
        resource_id: log_data['resource_id'],
        changes: log_data['changes'],
        metadata: log_data['metadata'],
        ip_address: log_data['ip_address'],
        user_agent: log_data['user_agent'],
        user_id: log_data['user_id'],
        mission: mission
      )
      log.save!
    end
  end

  def self.restore_media(backup_dir, user, mission)
    media_dir = backup_dir.join('media')
    return unless Dir.exist?(media_dir)
    
    # Media restoration would be implemented here
    # This is a simplified version
  end
end