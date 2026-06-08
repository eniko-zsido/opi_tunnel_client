#!/bin/bash

# tunnel.sh - Easy execution script for Java Tunnel Client

set -e

# Default values
TUNNEL_SERVER=${TUNNEL_SERVER:-"wss://opi-tunnel.onrender.com"}
LOCAL_PORT=${LOCAL_PORT:-"3000"}
TUNNEL_NAME=${TUNNEL_NAME:-""}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Java is installed
check_java() {
    if ! command -v java &> /dev/null; then
        print_error "Java is not installed or not in PATH"
        print_error "Please install Java 11 or higher"
        exit 1
    fi

    # Check Java version
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    major_version=$(echo "$java_version" | cut -d. -f1)

    if [ "$major_version" -lt 11 ]; then
        print_error "Java 11 or higher is required. Current version: $java_version"
        exit 1
    fi

    print_status "Java version: $java_version"
}

# Check if Maven is available
check_maven() {
    if command -v mvn &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if Gradle is available
check_gradle() {
    if command -v ./gradlew &> /dev/null; then
        return 0
    elif command -v gradle &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Build with Maven
build_maven() {
    print_status "Building with Maven..."
    mvn clean compile package -q
    JAR_FILE="./target/tunnel-client-1.0.0.jar"
}

# Build with Gradle
build_gradle() {
    print_status "Building with Gradle..."
    if [ -f "./gradlew" ]; then
        ./gradlew clean build -q
    else
        gradle clean build -q
    fi
    JAR_FILE="build/libs/tunnel-client-1.0.0-all.jar"
}

# Run the tunnel client
run_tunnel() {
    print_status "Starting Tunnel Proxy Java Client"
    echo
    echo "   Server:       $TUNNEL_SERVER"
    echo "   Local Port:   $LOCAL_PORT"
    echo "   Tunnel Name:  ${TUNNEL_NAME:-auto-generated}"
    echo

    # Set environment variables and run
    export TUNNEL_SERVER="$TUNNEL_SERVER"
    export LOCAL_PORT="$LOCAL_PORT"
    export TUNNEL_NAME="$TUNNEL_NAME"

    java -jar "$JAR_FILE"
}

# Main execution
main() {
    echo -e "${BLUE}🚇 Tunnel Proxy Java Client${NC}"
    echo "================================="
    echo

    # Check prerequisites
    check_java

    # Build the project
    if [ ! -f "pom.xml" ] && [ ! -f "build.gradle" ]; then
        print_error "No pom.xml or build.gradle found. Please run this script from the project directory."
        exit 1
    fi

    if [ -f "pom.xml" ] && check_maven; then
        build_maven
    elif [ -f "build.gradle" ] && check_gradle; then
        build_gradle
    else
        print_error "Neither Maven nor Gradle is available"
        print_error "Please install Maven (mvn) or Gradle (gradle) to build the project"
        exit 1
    fi

    # Check if JAR was built successfully
    if [ ! -f "$JAR_FILE" ]; then
        print_error "Build failed - JAR file not found: $JAR_FILE"
        exit 1
    fi

    print_status "Build successful: $JAR_FILE"
    echo

    # Run the tunnel client
    run_tunnel
}

# Handle command line arguments
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Usage: $0 [options]"
        echo
        echo "Environment Variables:"
        echo "  TUNNEL_SERVER  - WebSocket URL of your tunnel server"
        echo "  LOCAL_PORT     - Port of your local server (default: 3000)"
        echo "  TUNNEL_NAME    - Custom tunnel name (optional)"
        echo
        echo "Examples:"
        echo "  $0"
        echo "  TUNNEL_SERVER=wss://my-app.onrender.com LOCAL_PORT=8080 $0"
        echo "  TUNNEL_SERVER=wss://my-app.onrender.com TUNNEL_NAME=myapp $0"
        exit 0
        ;;
    *)
        main
        ;;
esac