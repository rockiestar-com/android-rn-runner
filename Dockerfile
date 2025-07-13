FROM reactnativecommunity/react-native-android:v18.0

# Set non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install system dependencies
RUN apt-get update && \
    apt-get install -y \
        postgresql-server-dev-all \
        curl \
        ca-certificates \
        gnupg \
        lsb-release \
        sudo \
        git \
        python3 \
        python3-pip \
        build-essential \
        wget \
        unzip \
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

# Install Node.js 20.x (specific version from log: 20.19.3)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install and enable pnpm via corepack
RUN npm install -g corepack@latest && \
    corepack enable pnpm

# Install bundler for Ruby dependencies
RUN gem install bundler

# Pre-install common npm packages that are frequently used (as root)
RUN npm install -g @expo/cli@latest tsx

# Set up environment variables
ENV BUNDLE_RETRY=3
ENV BUNDLE_JOBS=4
ENV BUNDLE_PATH=/home/builder/.bundle
ENV DOCKER_DRIVER=overlay2

# Pre-install Android SDK components that are downloaded during build
# Based on the log, these are commonly needed:
ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_ROOT=/opt/android
RUN yes | sdkmanager --licenses && \
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

# Create a user for running the build (avoid root warnings)
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chown -R builder:builder /home/builder

# Switch to builder user
USER builder

# Set up user environment
ENV PATH="$PATH:/home/builder/.local/bin"
ENV PNPM_HOME="/home/builder/.pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV BUNDLE_PATH=/home/builder/.bundle
ENV GRADLE_USER_HOME=/home/builder/.gradle

# Initialize pnpm (this will download pnpm 10.12.4 as seen in log)
RUN pnpm --version

# Create workspace directory and set up basic structure
WORKDIR /home/builder/workspace

# Pre-create commonly used directories
RUN mkdir -p \
    /home/builder/.bundle \
    /home/builder/.gradle \
    /home/builder/.pnpm \
    /home/builder/.cache \
    /home/builder/workspace

# Pre-install common Ruby gems that are used in Android builds
RUN gem install fastlane cocoapods

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

