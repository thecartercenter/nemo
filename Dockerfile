# NEMO Application Dockerfile
# Multi-stage build for optimized image size

FROM ruby:3.3.4-slim as base

# Set environment variables
ENV RAILS_ENV=development
ENV NODE_VERSION=20
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    curl \
    git \
    imagemagick \
    graphviz \
    memcached \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x using NodeSource repository
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN npm install -g yarn@1.22.22

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy package.json and yarn.lock
COPY package.json yarn.lock ./

# Install Node.js dependencies
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Precompile assets (optional, can be done at runtime)
# RUN RAILS_ENV=production bundle exec rake assets:precompile

# Create necessary directories
RUN mkdir -p tmp/pids tmp/cache log public/packs

# Expose port
EXPOSE 8443

# Default command
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "8443"]
