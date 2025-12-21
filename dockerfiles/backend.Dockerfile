# C++ Backend Dockerfile
FROM ubuntu:22.04

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    cmake \
    sqlite3 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy C++ source code from ekosim  
COPY . .

# Clean any existing build artifacts and build fresh for Linux
RUN make clean || true && make

# Create directory structure for SQLite database
RUN mkdir -p /var/app/current/myDB

# Create non-root user
RUN groupadd -r ekosim && useradd -r -g ekosim ekosim
RUN chown -R ekosim:ekosim /app
USER ekosim

EXPOSE 8080

CMD ["./main"]