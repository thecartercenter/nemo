# frozen_string_literal: true

module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_api_user!, only: %i[login register forgot_password reset_password]

      def login
        user = User.find_by(login: params[:login])

        if user&.active? && user.valid_password?(params[:password])
          # Generate or update API key
          user.regenerate_api_key if user.api_key.blank?

          # Update last login
          user.update!(current_login_at: Time.current, login_count: user.login_count + 1)

          render(json: success_response({
            user: user_json(user),
            api_token: user.api_key,
            expires_at: 1.year.from_now.iso8601
          }, "Login successful"))
        else
          render(json: error_response("Invalid credentials"), status: :unauthorized)
        end
      end

      def logout
        # In a more sophisticated implementation, you might want to invalidate the token
        render(json: success_response({}, "Logout successful"))
      end

      def register
        # This would typically be more restricted in a real application
        user = User.new(user_params)
        user.password = params[:password]
        user.password_confirmation = params[:password_confirmation]

        if user.save
          # Generate API key
          user.regenerate_api_key

          render(json: success_response({
            user: user_json(user),
            api_token: user.api_key
          }, "Registration successful"), status: :created)
        else
          render(json: error_response("Registration failed", user.errors), status: :unprocessable_entity)
        end
      end

      def profile
        render(json: success_response(user_json(current_user)))
      end

      def update_profile
        if current_user.update(user_params)
          render(json: success_response(user_json(current_user), "Profile updated successfully"))
        else
          render(json: error_response("Failed to update profile", current_user.errors), status: :unprocessable_entity)
        end
      end

      def change_password
        if current_user.valid_password?(params[:current_password])
          if current_user.update(password: params[:new_password],
            password_confirmation: params[:new_password_confirmation])
            render(json: success_response({}, "Password changed successfully"))
          else
            render(json: error_response("Failed to change password", current_user.errors),
              status: :unprocessable_entity)
          end
        else
          render(json: error_response("Current password is incorrect"), status: :unauthorized)
        end
      end

      def forgot_password
        user = User.find_by(email: params[:email])

        if user
          user.deliver_password_reset_instructions!
          render(json: success_response({}, "Password reset instructions sent"))
        else
          render(json: error_response("Email not found"), status: :not_found)
        end
      end

      def reset_password
        user = User.find_by(perishable_token: params[:token])

        if user&.password_reset_period_valid?
          if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
            render(json: success_response({}, "Password reset successfully"))
          else
            render(json: error_response("Failed to reset password", user.errors), status: :unprocessable_entity)
          end
        else
          render(json: error_response("Invalid or expired token"), status: :unauthorized)
        end
      end

      def missions
        missions = current_user.missions.includes(:assignments)

        render(json: success_response({
          missions: missions.map do |mission|
            assignment = mission.assignments.find_by(user: current_user)
            {
              id: mission.id,
              name: mission.name,
              shortcode: mission.shortcode,
              role: assignment&.role,
              created_at: mission.created_at.iso8601
            }
          end
        }))
      end

      def switch_mission
        mission = current_user.missions.find(params[:mission_id])
        current_user.update!(last_mission: mission)

        render(json: success_response({
          mission: {
            id: mission.id,
            name: mission.name,
            shortcode: mission.shortcode
          }
        }, "Mission switched successfully"))
      end

      private

      def user_params
        params.require(:user).permit(
          :name, :email, :phone, :pref_lang, :gender, :birth_year, :nationality
        )
      end

      def user_json(user)
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
          created_at: user.created_at.iso8601,
          updated_at: user.updated_at.iso8601,
          last_login_at: user.current_login_at&.iso8601
        }
      end
    end
  end
end
