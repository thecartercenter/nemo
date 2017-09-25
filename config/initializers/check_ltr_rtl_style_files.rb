ltr = Rails.root.join('app', 'assets', 'stylesheets', 'application_ltr.css.scss')
rtl = Rails.root.join('app', 'assets', 'stylesheets', 'application_rtl.css.scss')
unless `diff #{ltr} #{rtl}`.match(/\A\d+c\d+\n< \$dir: ltr;\n---\n> \$dir: rtl;\n\z/)
  raise "LTR and RTL stylesheets must be identical except for $dir variable. "\
    "Use `diff` to determine differences."
end
