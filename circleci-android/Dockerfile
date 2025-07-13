FROM cimg/android:2025.04.1-node

# Switch to root to install packages
USER root

# Set non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install additional system dependencies
RUN apt-get update && \
    apt-get install -y \
        postgresql-server-dev-all \
        python3-pip \
        build-essential \
        ruby-full \
        libffi-dev \
        libssl-dev \
        libxml2-dev \
        libncurses-dev \
        libtinfo-dev \
        clang-14 \
        llvm-14 \
        libpq-dev \
        libgc1 \
        libjson-perl \
        libjson-xs-perl \
        libcommon-sense-perl \
        libtypes-serialiser-perl \
        libpipeline1 \
        binfmt-support \
        netbase \
        cron \
        logrotate \
        ssl-cert \
    && rm -rf /var/lib/apt/lists/*

# Install and enable pnpm via corepack
RUN npm install -g corepack@latest && \
    corepack enable pnpm

# Install bundler for Ruby dependencies
RUN gem install bundler

# Pre-install common npm packages that are frequently used (as root)
RUN npm install -g @expo/cli@latest tsx

# Pre-install common Ruby gems that are used in Android builds (as root)
RUN gem install fastlane cocoapods

# Set up environment variables
ENV BUNDLE_RETRY=3
ENV BUNDLE_JOBS=4
ENV BUNDLE_PATH=/home/circleci/.bundle
ENV DOCKER_DRIVER=overlay2

# Pre-install Android SDK components that are downloaded during build
# CircleCI image already has Android SDK, but we may need additional components
RUN (yes || true) | sdkmanager --licenses && \
    sdkmanager "build-tools;35.0.0" \
    "platforms;android-35" \
    "ndk;27.0.12077973" \
    "cmake;3.22.1" \
    "platform-tools" \
    "emulator" \
    "system-images;android-35;google_apis;x86_64"

# Pre-download Gradle 8.13 (from log)
RUN wget -q https://services.gradle.org/distributions/gradle-8.13-bin.zip -O /tmp/gradle.zip && \
    mkdir -p /opt/gradle && \
    unzip -q /tmp/gradle.zip -d /opt/gradle && \
    rm /tmp/gradle.zip
ENV GRADLE_HOME=/opt/gradle/gradle-8.13
ENV PATH="$GRADLE_HOME/bin:$PATH"

# Give circleci user sudo access
RUN echo "circleci ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chown -R circleci:circleci /home/circleci

# Switch back to circleci user
USER circleci

# Set up user environment
ENV PATH="$PATH:/home/circleci/.local/bin"
ENV PNPM_HOME="/home/circleci/.pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV BUNDLE_PATH=/home/circleci/.bundle
ENV GRADLE_USER_HOME=/home/circleci/.gradle

# Initialize pnpm (this will download pnpm 10.12.4 as seen in log)
RUN pnpm --version

# Create workspace directory and set up basic structure
WORKDIR /home/circleci/workspace

# Pre-create commonly used directories
RUN mkdir -p \
    /home/circleci/.bundle \
    /home/circleci/.gradle \
    /home/circleci/.pnpm \
    /home/circleci/.cache \
    /home/circleci/workspace

# Optimize for CI environment
ENV CI=true
ENV AUTOMATED_TESTS=1
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.workers.max=2 -Dorg.gradle.parallel=false"

# Set locale to avoid fastlane warnings
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Verify installations
RUN node --version && \
    npm --version && \
    pnpm --version && \
    ruby --version && \
    bundle --version && \
    java -version && \
    gradle --version

# Set the working directory to /app for the CI (GitLab CI expects this)
WORKDIR /app

