# WP SecureScan AI

A comprehensive Ruby on Rails application for WordPress plugin security scanning with AI-powered analysis using OpenAI GPT-4.

## 🚀 Features

- **File Upload**: Accept WordPress plugin ZIP files up to 12MB
- **Static Analysis**: Detect 15+ vulnerability types using pattern matching
- **AI Analysis**: OpenAI GPT-4 integration for vulnerability explanation and remediation
- **Report Generation**: Export reports in HTML, Markdown, and PDF formats
- **User Management**: Devise authentication with admin controls
- **Background Processing**: Sidekiq for asynchronous scan processing
- **Modern UI**: Responsive design with Tailwind CSS

## 🔍 Vulnerability Detection

The system detects the following vulnerability types:

### High Severity
- SQL Injection
- Cross-Site Scripting (XSS)
- Remote Code Execution (RCE)
- Arbitrary File Upload
- PHP Object Injection
- Local File Inclusion (LFI)

### Medium Severity
- CSRF (Cross-Site Request Forgery)
- Broken Access Control
- Server-Side Request Forgery (SSRF)
- Open Redirect
- Arbitrary File Operations

### Low Severity
- Sensitive Data Exposure
- Type Juggling
- Race Conditions
- Insecure Randomness

## 🛠 Technology Stack

- **Backend**: Ruby on Rails 7.2.2.1
- **Database**: MySQL/MariaDB
- **Background Jobs**: Sidekiq + Redis
- **Authentication**: Devise
- **File Storage**: Active Storage
- **Encryption**: Lockbox for API keys
- **PDF Generation**: Prawn
- **Styling**: Tailwind CSS
- **AI Integration**: OpenAI GPT-4

## 📁 Project Structure

```
wp-secure-scan-AI/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── home_controller.rb
│   │   ├── scans_controller.rb
│   │   └── admin/
│   │       └── api_keys_controller.rb
│   ├── models/
│   │   ├── user.rb
│   │   ├── scan.rb
│   │   ├── vulnerability.rb
│   │   └── api_key.rb
│   ├── services/
│   │   ├── vulnerability_scanner.rb
│   │   ├── openai_analyzer.rb
│   │   └── report_generator.rb
│   ├── jobs/
│   │   └── scan_processor_job.rb
│   └── views/
│       ├── layouts/
│       ├── home/
│       ├── scans/
│       └── admin/
├── config/
│   ├── routes.rb
│   ├── database.yml
│   └── environments/
├── db/
│   └── migrate/
└── test/
```

## 🔧 Installation & Setup

### Prerequisites
- Ruby 3.1.2
- Rails 7.2.2.1
- MySQL/MariaDB
- Redis
- Node.js (for Tailwind CSS)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd wp-secure-scan-AI
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

3. **Database setup**
   ```bash
   rails db:create
   rails db:migrate
   ```

4. **Create admin user**
   ```bash
   rails console
   User.create!(email: 'admin@example.com', password: 'password', admin: true)
   ```

5. **Start services**
   ```bash
   # Terminal 1: Redis
   redis-server
   
   # Terminal 2: Sidekiq
   bundle exec sidekiq
   
   # Terminal 3: Rails server
   rails server
   ```

## 🔑 Configuration

### OpenAI API Key
1. Visit `/admin/api_keys` as an admin user
2. Enter your OpenAI API key
3. The key is encrypted using Lockbox

### Environment Variables
Create a `.env` file with:
```
OPENAI_API_KEY=your_openai_api_key_here
REDIS_URL=redis://localhost:6379/0
```

## 📊 Usage

### Scanning a Plugin

1. **Upload**: Navigate to the dashboard and click "New Scan"
2. **Select File**: Choose a WordPress plugin ZIP file (max 12MB)
3. **Process**: The system will:
   - Extract and analyze files
   - Run static vulnerability detection
   - Send flagged code to OpenAI for analysis
   - Generate comprehensive report
4. **View Results**: Access detailed vulnerability reports with AI explanations

### Report Formats

- **HTML**: Interactive web-based report
- **Markdown**: Text-based format for documentation
- **PDF**: Professional printable report

### Admin Features

- **API Key Management**: Secure storage of OpenAI credentials
- **User Management**: Control access and permissions
- **System Monitoring**: View scan statistics and performance

## 🔒 Security Features

- **Encrypted Storage**: API keys encrypted with Lockbox
- **File Validation**: ZIP file type and size validation
- **Secure Upload**: Temporary file handling with cleanup
- **Authentication**: Devise-based user management
- **Authorization**: Admin-only sensitive operations

## 🧪 Testing

### Manual Testing
A test plugin with intentional vulnerabilities is included:

```bash
# Run the test scanner
ruby test_scanner.rb
```

### Vulnerability Patterns
The system includes comprehensive regex patterns for detecting:
- SQL injection in WordPress database queries
- XSS in PHP echo statements and JavaScript DOM manipulation
- RCE in eval() and system() calls
- File inclusion vulnerabilities
- CSRF in admin actions
- And many more...

## 📈 Performance

- **Background Processing**: Scans run asynchronously via Sidekiq
- **Efficient Parsing**: Optimized file reading and pattern matching
- **Caching**: Redis-based job queue and session storage
- **Database Optimization**: Proper indexing and relationships

## 🔄 Workflow

1. **Upload** → User uploads WordPress plugin ZIP
2. **Extract** → System extracts and validates files
3. **Scan** → Static analysis detects vulnerability patterns
4. **Analyze** → AI provides context and remediation advice
5. **Report** → Generate comprehensive security report
6. **Archive** → Store results for future reference

## 🚦 Status Indicators

- **Pending**: Scan queued for processing
- **Processing**: Active vulnerability analysis
- **Completed**: Scan finished with results
- **Failed**: Error occurred during processing

## 📝 API Endpoints

- `GET /` - Dashboard
- `GET /scans` - Scan history
- `POST /scans` - Create new scan
- `GET /scans/:id` - View scan results
- `GET /scans/:id.pdf` - Download PDF report
- `GET /scans/:id.md` - Download Markdown report
- `GET /admin/api_keys` - API key management (admin only)

## 🔧 Customization

### Adding New Vulnerability Patterns
Edit `app/services/vulnerability_scanner.rb`:

```ruby
new_vulnerability: {
  patterns: [
    /your_regex_pattern/i
  ],
  severity: 'high|medium|low',
  description: 'Vulnerability description'
}
```

### Modifying AI Analysis
Update `app/services/openai_analyzer.rb` to customize:
- AI prompts
- Response processing
- Error handling

## 🐛 Troubleshooting

### Common Issues

1. **Redis Connection**: Ensure Redis server is running
2. **OpenAI API**: Verify API key is set correctly
3. **File Upload**: Check file size and format
4. **Background Jobs**: Monitor Sidekiq queue

### Logs
- Rails logs: `log/development.log`
- Sidekiq logs: Console output
- Error tracking: Built-in Rails error handling

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Submit pull request

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

**MD Ismail** - SQA + Security Engineer  
**Company**: WPDeveloper  
**Date**: July 9, 2025

---

## 🎯 Project Status: COMPLETED ✅

All core features have been implemented:
- ✅ File upload and validation
- ✅ Vulnerability scanning engine
- ✅ OpenAI GPT-4 integration
- ✅ Report generation (HTML/PDF/Markdown)
- ✅ User authentication and admin controls
- ✅ Background job processing
- ✅ Modern responsive UI
- ✅ Comprehensive security measures

The application is ready for production deployment with proper environment configuration.
