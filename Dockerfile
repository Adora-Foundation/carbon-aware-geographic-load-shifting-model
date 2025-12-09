# Docker image for the carbon-aware geographic load shifting model
# Uses GHC to run the Haskell model and includes gnuplot for reproducing plots

FROM haskell:9.4

# Configure APT for the older Debian release used in this image and install gnuplot for plotting (used by the job.hs workflow)
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/security.debian.org/d' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends gnuplot && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app/src

# Copy the full repository into the image
COPY . /app

# Default command: run the main model, printing CSV data to stdout
CMD ["runhaskell", "runLocationShiftingModel.hs"]
