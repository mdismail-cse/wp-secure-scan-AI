#!/bin/bash

echo "Setting up wp-secure-scan-AI..."

# Add Ruby gems path to PATH if not already present
if ! echo $PATH | grep -q "/home/$(whoami)/.local/share/gem/ruby/3.3.0/bin"; then
    echo "Adding Ruby gems path to PATH..."
    echo 'export PATH="$HOME/.local/share/gem/ruby/3.3.0/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/share/gem/ruby/3.3.0/bin:$PATH"
fi

# Install Ruby dependencies
echo "Installing Ruby dependencies..."
~/.local/share/gem/ruby/3.3.0/bin/bundle install

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
npm install

echo "Setup complete!"
echo "Note: You may need to restart your terminal or run 'source ~/.bashrc' to use the 'bundle' command directly."
