# frozen_string_literal: true

Rack::Utils::SYMBOL_TO_STATUS_CODE[:form_not_live] = 460
Rack::Utils::HTTP_STATUS_CODES[460] = "Form Not Live"
