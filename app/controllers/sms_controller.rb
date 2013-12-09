# handles incoming sms messages from various providers
class SmsController < ApplicationController
  # load resource for index
  load_and_authorize_resource :class => "Sms::Message", :only => :index

  # don't need authorize for this controller. authorization is handled inside the sms processing machinery.
  skip_authorization_check :only => :create

  # disable csrf protection for this stuff
  protect_from_forgery :except => :create

  # takes an incoming sms and returns an outgoing one
  # may return nil if no response is appropriate
  def self.handle_sms(sms)
    elmo_response = nil

    reply_body = begin
      # decode and get the (ELMO) response
      elmo_response = Sms::Decoder.new(sms).decode

      # attempt to save it
      elmo_response.save!

      # send congrats!
      t_sms_msg("sms_form.decoding.congrats", :user => elmo_response.user, :form => elmo_response.form, :mission => sms.mission)

    # if there is a decoding error, respond accordingly
    rescue Sms::DecodingError

      # if it's a user not found and the from number is a string, don't reply at all, b/c it's probably some robot
      if $!.type == "user_not_found" && sms.from =~ /[a-z]/i
        nil
      else
        msg = t_sms_msg("sms_form.decoding.#{$!.type}", $!.params)

        # if this is an answer format error, add an intro to the beginning and add a period
        if $!.type =~ /^answer_not_/
          t_sms_msg("sms_form.decoding.answer_error_intro", $!.params) + " " + msg + "."
        else
          msg
        end
      end

    # if there is a validation error, respond accordingly
    rescue ActiveRecord::RecordInvalid
      # we only need to handle the first error
      field, error_msgs = elmo_response.errors.messages.first
      error_msg = error_msgs.first

      # get the orignal error key by inverting the dictionary
      # we use the system-wide locale since that's what the model would have used when generating the error
      dict = I18n.t("activerecord.errors.models.response")
      key = dict ? dict.invert[error_msg] : nil

      case key
      when :missing_answers
        # if it's the missing_answers error, we need to include which answers are missing
        # get the ranks
        ranks = elmo_response.missing_answers.map(&:rank).sort.join(",")

        # pluralize the translation key if appropriate
        key = "sms_form.validation.missing_answer"
        key += "s" if elmo_response.missing_answers.size > 1

        # translate
        t_sms_msg(key, :ranks => ranks, :user => elmo_response.user, :form => elmo_response.form, :mission => sms.mission)

      when :invalid_answers
        # if it's the invalid_answers error, we need to find the first answer that's invalid and report its error
        invalid_answer = elmo_response.answers.detect{|a| a.errors && a.errors.messages.size > 0}
        t_sms_msg("sms_form.validation.invalid_answer", :rank => invalid_answer.questioning.rank,
          :error => invalid_answer.errors.full_messages.join(", "), :user => elmo_response.user, :form => elmo_response.form, :mission => sms.mission)

      else
        # if we don't recognize the key, just use the regular message. it may not be pretty but it's better than nothing.
        error_msg
      end
    end

    if reply_body.nil?
      return nil
    else
      # build the reply message
      reply = Sms::Message.new(:to => sms.from, :body => reply_body, :mission => sms.mission)

      # add to the array
      return reply
    end
  end

  def index
    # cancan load_resource messes up the inflection so we need to create smses from sms
    @smses = @sms.newest_first.paginate(:page => params[:page], :per_page => 50)
  end

  def create
    # get the mission from the params. if not found raise an error (we need the mission)
    @mission = Mission.find_by_compact_name(params[:mission])
    raise Sms::Error.new("Mission not specified") if @mission.nil?

    # first we need to figure out which provider sent this message, so we shop it around to all the adapters and see if any recognize it
    handled = false
    Sms::Adapters::Factory.products.each do |klass|

      # if we get a match
      if klass.recognize_receive_request?(request)

        @adapter = klass.new

        # go ahead with processing, catching any errors
        begin
          # do the receive
          @incomings = @adapter.receive(request)

          # we should set the mission parameter in the incoming messages
          @incomings.each{|m| m.update_attributes(:mission => @mission)}

          # for each sms, decode it and
          # store the sms responses in an instance variable so the functional test can access them
          @sms_replies = @incomings.map{|sms| self.class.handle_sms(sms)}.compact

          # send the responses
          @sms_replies.each do |r|
            # copy the settings for the message's mission
            r.mission && r.mission.setting ? r.mission.setting.load : Setting.build_default.load

            # set the incoming_sms_number as the from number, if we have one
            r.update_attributes(:from => configatron.incoming_sms_number) unless configatron.incoming_sms_number.blank?

            # send the message using the mission's outgoing adapter
            configatron.outgoing_sms_adapter.deliver(r)
          end

        # if we get an error
        rescue Sms::Error
          # notify the admin (if production) but don't re-raise it so that we can keep processing other msgs
          if Rails.env == "production"
            notify_error($!, :dont_re_raise => true)
          # if not in production, re-raise it
          else
            raise $!
          end
        end

        # we can now exit the loop
        handled = true
        break
      end
    end

    raise Sms::Error.new("no adapters recognized this receive request") unless handled

    # render something nice for the robot
    render :text => "OK"
  end

  private
    # translates a message for the sms reply using the appropriate locale
    def self.t_sms_msg(key, options = {})
      # throw in the form_code if it's not there already and we have the form
      options[:form_code] ||= options[:form].current_version.code if options[:form]

      # get the reply language (if we have the user, use their pref_lang; if not, use default)
      lang = options[:user] && options[:user].pref_lang ? options[:user].pref_lang.to_sym : I18n.default_locale

      # do the translation, raising error on failure
      I18n.t(key, options.merge(:locale => lang, :raise => true))
    end
end
