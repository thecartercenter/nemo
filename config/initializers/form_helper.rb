module ActionView
  module Helpers
    class FormBuilder
      include ActionView::Helpers::TagHelper
      
      attr_accessor :mode
      alias :old_text_field :text_field
      alias :old_text_area :text_area
      alias :old_select :select
      alias :old_datetime_select :datetime_select
      alias :old_date_select :date_select
      alias :old_time_select :time_select
      alias :old_check_box :check_box
      alias :old_submit :submit

      def text_field(*args)
        rewrite_if_show_mode(:text_field, *args)
      end
      
      def text_area(*args)
        rewrite_if_show_mode(:text_area, *args)
      end
      
      def select(*args)
        rewrite_if_show_mode(:select, *args)
      end
      
      def datetime_select(*args)
        rewrite_if_show_mode(:datetime_select, *args)
      end
      
      def date_select(*args)
        rewrite_if_show_mode(:date_select, *args)
      end
      
      def time_select(*args)
        rewrite_if_show_mode(:time_select, *args)
      end
      
      def check_box(*args)
        rewrite_if_show_mode(:check_box, *args)
      end
      
      def submit(*args)
        rewrite_if_show_mode(:submit, *args)
      end
      
      private
      
        # rewrites the output for the given field_type if the form is in show mode
        def rewrite_if_show_mode(field_type, *args)
          html = send("old_#{field_type}", *args)
        
          # if not show mode, or field hidden, just return straight html
          if mode != :show || html.match(/display: none/)
            html
          else
            # get the dummy representation
            dummy = case field_type
            when :text_field
              # if value is defined, wrap in dummy tag, else return empty string
              dummy_tag(html.match(/^<input.*?value="(.*)".*?>$/) ? $1 : "")
            when :text_area
              dummy_tag(html.match(/<textarea.+?>(.*?)<\/textarea>/m) ? $1.gsub("\n", "<br/>") : "")
            when :select, :datetime_select, :date_select, :time_select
              dummy_tag(html.gsub(/<select.*?<option.*?selected="selected".*?>(.*?)<\/option>.*?<\/select>/mi, '\1'))
            when :check_box
              dummy_tag(html.match(/checked="checked"/) ? "&nbsp;x&nbsp;" : "&nbsp;&nbsp;&nbsp;&nbsp;", :style => :dummy_checkbox)
            when :submit
              dummy_tag("")
            # should never get to this point so if we do, print an error
            else
              dummy_tag("[Rendering Error]")
            end
            
            # return the dummy tag plus the original html hidden
            (html.gsub(/(<\w+ )/, '\1style="display: none" ') + dummy).html_safe
          end
        end
        
        def dummy_tag(content, options = {})
          options[:style] ||= "dummy"
          "<div class=\"#{options[:style]}\">#{content}</div>".html_safe
        end
    end
  end
end