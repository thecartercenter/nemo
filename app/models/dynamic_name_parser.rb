class DynamicNameParser
  CODE_PATTERN = /([$][!]?[A-z]\w+)/
  RESERVED_CODES = {
  }

  def initialize(form, pattern)
    @form = form
    @pattern = pattern
    @src_item = Odk::QingGroupDecorator.decorate(form.root_group)
  end

  def to_odk
    odk_mapping = {}

    # Map expression codes to relative paths
    code_mapping.each do |code, other_qing|
      other_qing = Odk::QingDecorator.decorate(other_qing)

      if reserved_codes.keys.include?(code)
        odk_mapping[code] = reserved_codes[code]
      else
        if other_qing.has_options?
          if other_qing.multilevel?
            xpath = other_qing.subqings.first.absolute_xpath
          else
            xpath = other_qing.absolute_xpath
          end
          # We need to use jr:itext to look up the option name instead of its odk_code
          # The coalesce is because ODK returns some ugly thing like [itext:] if it can't
          # find the requested itext resource. If the requested xml node not filled in yet
          # we end up in this situation. Using 'blank' assumes there is an itext node in the form
          # with id 'blank' and an empty value.
          odk_mapping[code] = %Q{<output value="jr:itext(coalesce(#{xpath},'blank'))"/>}
        else
          xpath = other_qing.absolute_xpath
          odk_mapping[code] = %Q{<output value="#{xpath}"/>}
        end
      end
    end

    tokens = pattern.split(CODE_PATTERN).reject(&:empty?)
    tokens = tokens.map do |token|
      if odk_mapping.has_key?(token)
        odk_mapping[token]
      elsif token =~ /\A\s+\z/ #this token is only whitespace between two $ phrases in pattern
        "&#160;" #odk ignores plain whitespace between output tags. This is a non-breaking space xml character
      else
        token
      end
    end
    tokens.compact!

    tokens.size > 1 ? tokens.join : tokens.first
  end

  private

  attr_reader :pattern, :src_item, :form

  def reserved_codes
    return @reserved_codes if @reserved_codes
    @reserved_codes = RESERVED_CODES.dup

    # We can't use repeat num if src_item is root because root or top level
    # because can't be in a repeat group.
    if src_item.depth < 2
      @reserved_codes["$!RepeatNum"] = nil
    end

    @reserved_codes
  end

  def extract_codes
    @extracted_codes ||= pattern.scan(CODE_PATTERN).flatten
  end

  def code_mapping
    return @mapping if @mapping.present?
    @mapping = {}
    extract_codes.each do |code|
      questioning = form.questioning_with_code(code[1..-1])
      @mapping[code] = questioning if questioning.present?
      @mapping[code] = code if RESERVED_CODES.keys.include?(code)
    end
    @mapping
  end
end