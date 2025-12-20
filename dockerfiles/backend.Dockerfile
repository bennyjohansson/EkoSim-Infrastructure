# C++ Backend Dockerfile
FROM ubuntu:22.04

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    sqlite3 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy C++ source code from ekosim
COPY ../ekosim/ .

# Build the application
RUN mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc)

# Create data directory for SQLite
RUN mkdir -p /app/data

# Create non-root user
RUN groupadd -r ekosim && useradd -r -g ekosim ekosim
RUN chown -R ekosim:ekosim /app
USER ekosim

EXPOSE 8080

CMD ["./build/ekosim"]