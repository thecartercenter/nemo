module ActionView
  module Helpers
    class FormBuilder
      attr_accessor :mode
      alias :old_text_field :text_field
      alias :old_select :select
      alias :old_check_box :check_box
      def text_field(*args)
        html = old_text_field(*args)
        mode == :show ? html.match(/value="(.+?)"/) && dummy_tag($1) : html
      end
      def select(*args)
        html = old_select(*args)
        mode == :show ? html.match(/<option.*?selected="selected".*?>(.*?)<\/option>/) && dummy_tag($1) : html
      end
      def check_box(*args)
        html = old_check_box(*args)
        if mode == :show
          dummy_tag(html.match(/checked="checked"/) ? "x" : "&nbsp;", :style => :dummy_checkbox)
        else
          html
        end
      end
      private
        def dummy_tag(content, options = {})
          options[:style] ||= "dummy"
          "<div class=\"#{options[:style]}\">#{content}</div>".html_safe
        end
    end
  end
end