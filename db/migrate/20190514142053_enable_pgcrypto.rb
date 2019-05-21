# frozen_string_literal: true

# Newer versions of Postgres us pgcrypto for UUID generation instead of uuid-ossp.
class EnablePgcrypto < ActiveRecord::Migration[5.2]
  def change
    enable_extension "pgcrypto"
  end
end
