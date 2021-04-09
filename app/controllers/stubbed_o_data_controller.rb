# frozen_string_literal: true

class StubbedODataController < ApplicationController
  skip_authorization_check

  def root
    render(plain: '
{ your root here }
')
  end

  def metadata
    render(plain: '
<your xml here>
')
  end

  def resource
    render(plain: '
{ your resource here }
')
  end
end
