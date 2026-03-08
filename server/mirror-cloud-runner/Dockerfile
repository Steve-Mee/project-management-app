FROM dart:stable AS build

WORKDIR /app

# Install Flutter SDK and required system tools for Flutter build in container.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
  && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_HOME} --depth 1 -b stable \
  && flutter config --no-analytics \
  && flutter doctor -v

COPY . .

RUN dart pub get
RUN dart compile exe lib/main.dart -o /app/bin/server

FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/bin/server /app/server

ENV PORT=8080
ENV MIRROR_WORKSPACE_ROOT=/tmp/mirror-workspaces

EXPOSE 8080

CMD ["/app/server"]
