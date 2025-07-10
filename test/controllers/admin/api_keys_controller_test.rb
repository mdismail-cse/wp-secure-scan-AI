require "test_helper"

class Admin::ApiKeysControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_api_keys_index_url
    assert_response :success
  end

  test "should get new" do
    get admin_api_keys_new_url
    assert_response :success
  end

  test "should get create" do
    get admin_api_keys_create_url
    assert_response :success
  end

  test "should get edit" do
    get admin_api_keys_edit_url
    assert_response :success
  end

  test "should get update" do
    get admin_api_keys_update_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_api_keys_destroy_url
    assert_response :success
  end
end
