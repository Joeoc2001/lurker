FROM oven/bun:latest

# Copy application files (default WORKDIR in oven/bun is /home/bun/app)
ADD ./ ./

# Install dependencies
RUN bun install

# Create a directory for data
RUN mkdir -p /data

# Ensure /home/bun has proper permissions for traversal
RUN chmod 755 /home/bun

# Set default PUID and PGID
ENV PUID=1000
ENV PGID=1000

# Install gosu for privilege switching
RUN apt-get update && apt-get install -y gosu && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add entrypoint script for handling dynamic PUID/PGID
ADD entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Keep working directory as /home/bun/app so bun can find modules
# The entrypoint will cd to /data if needed
WORKDIR /home/bun/app

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD bun -e "fetch('http://localhost:' + (process.env.LURKER_PORT || 3000) + '/login').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

# Default command
CMD ["bun", "run", "src/index.js"]
