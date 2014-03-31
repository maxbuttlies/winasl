require 'test_helper'

class BlogControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get post" do
    get :post
    assert_response :success
  end

  test "should get site" do
    get :site
    assert_response :success
  end

end
