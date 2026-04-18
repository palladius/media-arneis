# media-arneis - Justfile

# Default task: list all commands
default:
	@just --list

# Install dependencies
install:
	bundle install

# Run tests
test:
	@echo "🟢 Running tests..."
	bundle exec rspec

# Run linter
lint:
	@echo "🟢 Running linter..."
	bundle exec standardrb

# Run the CLI
arnectl *args:
	bundle exec bin/arnectl {{args}}
