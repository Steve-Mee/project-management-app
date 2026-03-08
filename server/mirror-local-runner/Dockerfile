FROM dart:stable AS build

WORKDIR /app

# Install Flutter SDK and required tools so the local runner can execute Flutter/Dart compile commands.
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

ENV PORT=50051
ENV MIRROR_WORKSPACE_ROOT=/tmp/mirror-local-workspaces
ENV ARTIFACT_BASE_URL=http://127.0.0.1:50051/artifacts
ENV SIGNED_URL_SECRET=local-dev-secret

EXPOSE 50051

CMD ["/app/server"]
