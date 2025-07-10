require "test_helper"

class ScansControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get scans_index_url
    assert_response :success
  end

  test "should get show" do
    get scans_show_url
    assert_response :success
  end

  test "should get new" do
    get scans_new_url
    assert_response :success
  end

  test "should get create" do
    get scans_create_url
    assert_response :success
  end
end
