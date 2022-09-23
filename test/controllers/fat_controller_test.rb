# frozen_string_literal: true

require 'test_helper'

class FatControllerTest < ActionDispatch::IntegrationTest
  test 'should get authorize' do
    get fat_authorize_url
    assert_response :success
  end

  test 'should get callback' do
    get fat_callback_url
    assert_response :success
  end
end
