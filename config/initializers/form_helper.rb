module ActionView
  module Helpers
    class FormBuilder
      attr_accessor :mode
      alias :old_text_field :text_field
      alias :old_text_area :text_area
      alias :old_select :select
      alias :old_check_box :check_box
      alias :old_submit :submit
      def text_field(*args)
        html = old_text_field(*args)
        unless mode == :show && html.match(/display: none/)
          mode == :show ? html.match(/value="(.+?)"/) && dummy_tag($1) : html
        end
      end
      def text_area(*args)
        html = old_text_area(*args)
        mode == :show ? html.match(/<textarea.+?>(.*?)<\/textarea>/m) && dummy_tag($1.gsub("\n", "<br/>")) : html
      end
      def select(*args)
        html = old_select(*args)
        unless mode == :show && html.match(/display: none/)
          mode == :show ? html.match(/<option.*?selected="selected".*?>(.*?)<\/option>/) && dummy_tag($1) : html
        end
      end
      def check_box(*args)
        html = old_check_box(*args)
        if mode == :show
          dummy_tag(html.match(/checked="checked"/) ? "&nbsp;x&nbsp;" : "&nbsp;&nbsp;&nbsp;&nbsp;", :style => :dummy_checkbox)
        else
          html
        end
      end
      def submit(*args)
        html = old_submit(*args)
        mode == :show ? '' : html
      end
      private
        def dummy_tag(content, options = {})
          options[:style] ||= "dummy"
          "<div class=\"#{options[:style]}\">#{content}</div>".html_safe
        end
    end
  end
end