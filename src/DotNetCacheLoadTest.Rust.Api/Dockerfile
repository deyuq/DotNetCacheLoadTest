# Use the official Rust image as a parent image
FROM rust:latest

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the Cargo.toml and Cargo.lock files first
COPY DotNetCacheLoadTest.Rust.Api/Cargo.toml DotNetCacheLoadTest.Rust.Api/Cargo.lock ./

# Create a dummy main.rs to allow the build to proceed
RUN mkdir -p src && echo "fn main() {}" > src/main.rs

# Build the dependencies only
RUN cargo build --release

# Remove the dummy main.rs
RUN rm -f src/main.rs

# Copy the source code
COPY DotNetCacheLoadTest.Rust.Api/src ./src

# Build the Rust application
RUN cargo build --release

# Set the environment variable for the binary
ENV RUST_LOG=debug

# Expose the port that the Actix web server will run on
EXPOSE 8080

# Run the Actix web server binary
CMD ["./target/release/dotnetcacheloadtestrustapi"]
