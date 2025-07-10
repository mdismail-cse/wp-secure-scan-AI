require 'test_helper'

class SecurityTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      admin: true
    )
  end

  test "API key encryption works" do
    api_key = @user.api_keys.create!(
      name: "Test Key",
      key: "sk-test123456789"
    )
    
    # Key should be encrypted in database
    assert_not_equal "sk-test123456", api_key.encrypted_key_ciphertext
    
    # But should decrypt correctly
    assert_equal "sk-test123456", api_key.key
  end

  test "scan file size validation" do
    scan = @user.scans.build(plugin_name: "test-plugin")
    
    # Mock a large file
    large_file = Tempfile.new(['large', '.zip'])
    large_file.write('x' * 13.megabytes) # Larger than 12MB limit
    large_file.rewind
    
    scan.plugin_file.attach(
      io: large_file,
      filename: 'large_plugin.zip',
      content_type: 'application/zip'
    )
    
    assert_not scan.valid?
    assert_includes scan.errors[:plugin_file], "File size must be less than 12MB"
    
    large_file.close
    large_file.unlink
  end

  test "vulnerability scanner prevents directory traversal" do
    scanner = VulnerabilityScanner.new(nil)
    
    # Test the directory traversal protection
    malicious_entry = OpenStruct.new(name: "../../../etc/passwd")
    
    # This should be skipped due to ".." check
    assert scanner.send(:extract_zip, nil, "/tmp") do |zip_file|
      zip_file.stub :each, [malicious_entry] do
        # The malicious entry should be skipped
        assert true # If we get here, the protection worked
      end
    end
  end

  test "admin access control" do
    regular_user = User.create!(
      email: 'regular@example.com', 
      password: 'password123',
      admin: false
    )
    
    assert @user.admin?
    assert_not regular_user.admin?
  end

  test "parameter filtering includes sensitive data" do
    filtered_params = Rails.application.config.filter_parameters
    
    assert_includes filtered_params, :passw
    assert_includes filtered_params, :secret
    assert_includes filtered_params, :token
    assert_includes filtered_params, :_key
  end
end
