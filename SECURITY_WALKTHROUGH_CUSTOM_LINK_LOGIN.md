# Security Walkthrough: Custom Link Login Implementation

## Overview
This document provides a comprehensive security analysis for implementing custom link-based authentication in your WP SecureScan AI application.

## Current Authentication Status
Your application currently uses Devise for authentication with the following security measures:
- Session-based authentication
- CSRF protection enabled
- Secure password storage with bcrypt
- Session timeout configuration
- HTTP-only cookies

## Custom Link Authentication Security Considerations

### 1. Link Generation Security

#### Secure Token Generation
```ruby
# Use cryptographically secure random tokens
require 'securerandom'

class LoginLink < ApplicationRecord
  before_create :generate_secure_token
  
  private
  
  def generate_secure_token
    self.token = SecureRandom.urlsafe_base64(32)
  end
end
```

**Security Requirements:**
- Minimum 256-bit entropy (32 bytes)
- Use cryptographically secure random number generator
- URL-safe encoding to prevent encoding attacks

### 2. Link Storage Security

#### Database Schema
```ruby
class CreateLoginLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :login_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end
    
    add_index :login_links, :token_digest, unique: true
    add_index :login_links, :expires_at
  end
end
```

**Security Measures:**
- Store hashed tokens, not plaintext
- Track usage to prevent replay attacks
- Log IP and user agent for audit trail

### 3. Token Hashing Implementation

```ruby
class LoginLink < ApplicationRecord
  belongs_to :user
  
  attr_accessor :token
  
  before_create :generate_and_hash_token
  
  def self.find_by_valid_token(token)
    digest = Digest::SHA256.hexdigest(token)
    where(token_digest: digest)
      .where('expires_at > ?', Time.current)
      .where(used_at: nil)
      .first
  end
  
  private
  
  def generate_and_hash_token
    self.token = SecureRandom.urlsafe_base64(32)
    self.token_digest = Digest::SHA256.hexdigest(token)
    self.expires_at = 15.minutes.from_now
  end
end
```

### 4. Link Validation Security

#### Controller Implementation
```ruby
class LoginLinksController < ApplicationController
  skip_before_action :authenticate_user!, only: [:authenticate]
  
  def create
    @login_link = current_user.login_links.build
    
    if @login_link.save
      # Send link via secure channel (email, SMS, etc.)
      LoginLinkMailer.send_link(@login_link).deliver_later
      redirect_to root_path, notice: 'Login link sent!'
    else
      redirect_to root_path, alert: 'Failed to generate login link'
    end
  end
  
  def authenticate
    token = params[:token]
    
    # Rate limiting check
    if rate_limit_exceeded?(request.remote_ip)
      redirect_to root_path, alert: 'Too many attempts. Please try again later.'
      return
    end
    
    login_link = LoginLink.find_by_valid_token(token)
    
    if login_link
      # Additional security checks
      if suspicious_request?(login_link, request)
        log_security_event('Suspicious login attempt', login_link, request)
        redirect_to root_path, alert: 'Security verification failed'
        return
      end
      
      # Mark as used
      login_link.update!(
        used_at: Time.current,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      
      # Sign in user
      sign_in(login_link.user)
      
      # Log successful authentication
      log_security_event('Successful login via link', login_link, request)
      
      redirect_to dashboard_path, notice: 'Successfully logged in!'
    else
      # Log failed attempt
      log_security_event('Failed login attempt', nil, request)
      redirect_to root_path, alert: 'Invalid or expired login link'
    end
  end
  
  private
  
  def rate_limit_exceeded?(ip)
    # Implement rate limiting logic
    attempts = Rails.cache.read("login_attempts:#{ip}") || 0
    if attempts >= 5
      true
    else
      Rails.cache.write("login_attempts:#{ip}", attempts + 1, expires_in: 15.minutes)
      false
    end
  end
  
  def suspicious_request?(login_link, request)
    # Check for suspicious patterns
    return true if login_link.user.last_sign_in_ip && 
                   !same_network?(login_link.user.last_sign_in_ip, request.remote_ip)
    
    # Add more checks as needed
    false
  end
  
  def same_network?(ip1, ip2)
    # Implement IP network comparison logic
    # This is a simplified example
    IPAddr.new(ip1).mask(24) == IPAddr.new(ip2).mask(24)
  end
  
  def log_security_event(event, login_link, request)
    SecurityLog.create!(
      event: event,
      user_id: login_link&.user_id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      metadata: {
        token_digest: login_link&.token_digest,
        referrer: request.referrer
      }
    )
  end
end
```

### 5. Security Headers and Middleware

```ruby
# config/application.rb
config.force_ssl = true # Force HTTPS in production

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_security_headers
  
  private
  
  def set_security_headers
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
  end
end
```

### 6. Link Delivery Security

#### Email Delivery
```ruby
class LoginLinkMailer < ApplicationMailer
  def send_link(login_link)
    @user = login_link.user
    @login_url = authenticate_login_link_url(token: login_link.token, host: Rails.application.config.action_mailer.default_url_options[:host])
    
    mail(
      to: @user.email,
      subject: 'Your secure login link',
      # Use encrypted email if possible
    )
  end
end
```

### 7. Security Monitoring and Alerts

```ruby
class SecurityMonitor
  def self.check_suspicious_activity(user)
    recent_links = user.login_links.where('created_at > ?', 1.hour.ago).count
    
    if recent_links > 3
      # Alert security team
      SecurityAlert.create!(
        alert_type: 'excessive_login_links',
        user: user,
        metadata: { count: recent_links }
      )
    end
  end
end
```

## Security Checklist

### Before Implementation
- [ ] Review current authentication system
- [ ] Assess threat model for your application
- [ ] Define security requirements
- [ ] Plan monitoring and alerting

### During Implementation
- [ ] Use secure random token generation (minimum 256 bits)
- [ ] Store only hashed tokens in database
- [ ] Implement short expiration times (15-30 minutes)
- [ ] Add rate limiting to prevent brute force
- [ ] Log all authentication attempts
- [ ] Implement IP-based security checks
- [ ] Use HTTPS for all communications
- [ ] Add CSRF protection to all forms

### After Implementation
- [ ] Conduct security testing
- [ ] Monitor for suspicious patterns
- [ ] Regular security audits
- [ ] Update documentation

## Additional Security Recommendations

1. **Two-Factor Authentication**: Consider requiring 2FA for high-privilege accounts
2. **Device Fingerprinting**: Track device characteristics for anomaly detection
3. **Geolocation Checks**: Alert users of logins from new locations
4. **Session Management**: Implement proper session timeout and invalidation
5. **Audit Logging**: Maintain comprehensive logs for security analysis

## Next Steps

Once you provide the custom link format or requirements, I can:
1. Analyze the specific security implications
2. Provide tailored implementation code
3. Identify potential vulnerabilities
4. Suggest security enhancements

Please share the custom link details for a more specific security analysis.
