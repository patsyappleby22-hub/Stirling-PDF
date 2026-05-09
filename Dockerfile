# Stirling-PDF — Full build with ALL features
# Includes: LibreOffice, Tesseract OCR, Ghostscript, Calibre, OCRmyPDF, WeasyPrint
# Used for Northflank / Docker production deployment
#
# Build args:
#   BASE_VERSION — version of stirling-pdf-base image (default 1.0.2)

ARG BASE_VERSION=1.0.2
ARG BASE_IMAGE=stirlingtools/stirling-pdf-base:${BASE_VERSION}

# ─── Stage 1: Build Java application + frontend ───────────────────────────────
FROM gradle:9.3.1-jdk25 AS app-build

ARG TASK_VERSION=3.49.1
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && update-ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_${TASK_VERSION}_linux_${ARCH}.deb" -o /tmp/task.deb \
    && dpkg -i /tmp/task.deb \
    && rm /tmp/task.deb \
    && rm -rf /var/lib/apt/lists/*

ENV JDK_JAVA_OPTIONS="--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED \
  --add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED \
  --add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED \
  --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED \
  --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED"

WORKDIR /app

COPY build.gradle settings.gradle gradlew ./
COPY gradle/                               gradle/
COPY app/core/build.gradle                 app/core/
COPY app/common/build.gradle               app/common/
COPY app/proprietary/build.gradle          app/proprietary/

RUN gradle dependencies --no-daemon || true

COPY . .

RUN DISABLE_ADDITIONAL_FEATURES=false \
    gradle clean build \
      -PbuildWithFrontend=true \
      -x spotlessApply -x spotlessCheck -x test -x sonarqube \
      --no-daemon

# ─── Stage 2: Extract Spring Boot layers ──────────────────────────────────────
FROM eclipse-temurin:25-jre-noble AS jar-extract
WORKDIR /tmp
COPY --from=app-build /app/app/core/build/libs/*.jar app.jar
RUN java -Djarmode=tools -jar app.jar extract --layers --destination /layers

# ─── Stage 3: Final runtime image (base has all system tools pre-installed) ───
FROM ${BASE_IMAGE}

ARG VERSION_TAG

WORKDIR /app

COPY --link --from=jar-extract --chown=1000:1000 /layers/dependencies/           /app/
COPY --link --from=jar-extract --chown=1000:1000 /layers/spring-boot-loader/     /app/
COPY --link --from=jar-extract --chown=1000:1000 /layers/snapshot-dependencies/  /app/
COPY --link --from=jar-extract --chown=1000:1000 /layers/application/            /app/

COPY --link --from=app-build --chown=1000:1000 \
     /app/build/libs/restart-helper.jar /restart-helper.jar
COPY --link --chown=1000:1000 scripts/ /scripts/

COPY app/core/src/main/resources/static/fonts/*.ttf /usr/share/fonts/truetype/

RUN set -eux; \
    chmod +x /scripts/*; \
    ln -s /logs /app/logs; \
    ln -s /configs /app/configs; \
    ln -s /customFiles /app/customFiles; \
    ln -s /pipeline /app/pipeline; \
    chown -h stirlingpdfuser:stirlingpdfgroup /app/logs /app/configs /app/customFiles /app/pipeline; \
    chown stirlingpdfuser:stirlingpdfgroup /app; \
    chmod 750 /tmp/stirling-pdf; \
    chmod 750 /tmp/stirling-pdf/heap_dumps; \
    fc-cache -f

RUN echo "${VERSION_TAG:-dev}" > /etc/stirling_version

ENV VERSION_TAG=$VERSION_TAG \
    STIRLING_AOT_ENABLE="false" \
    STIRLING_JVM_PROFILE="balanced" \
    _JVM_OPTS_BALANCED="-XX:+ExitOnOutOfMemoryError -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/configs/heap_dumps -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:G1HeapRegionSize=4m -XX:G1PeriodicGCInterval=60000 -XX:+UseStringDeduplication -XX:+UseCompactObjectHeaders -XX:+ExplicitGCInvokesConcurrent -Dspring.threads.virtual.enabled=true -Djava.awt.headless=true" \
    _JVM_OPTS_PERFORMANCE="-XX:+ExitOnOutOfMemoryError -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/configs/heap_dumps -XX:+UseShenandoahGC -XX:ShenandoahGCMode=generational -XX:+UseCompactObjectHeaders -XX:+UseStringDeduplication -XX:+AlwaysPreTouch -XX:+ExplicitGCInvokesConcurrent -Dspring.threads.virtual.enabled=true -Djava.awt.headless=true" \
    JAVA_CUSTOM_OPTS="" \
    HOME=/home/stirlingpdfuser \
    PUID=1000 \
    PGID=1000 \
    UMASK=022 \
    FAT_DOCKER=true \
    INSTALL_BOOK_AND_ADVANCED_HTML_OPS=false \
    STIRLING_TEMPFILES_DIRECTORY=/tmp/stirling-pdf \
    TMPDIR=/tmp/stirling-pdf \
    TEMP=/tmp/stirling-pdf \
    TMP=/tmp/stirling-pdf \
    DBUS_SESSION_BUS_ADDRESS=/dev/null \
    SAL_TMP=/tmp/stirling-pdf/libre

EXPOSE 8080/tcp
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=5 \
  CMD curl -fs --max-time 10 http://localhost:8080/api/v1/info/status || exit 1

ENTRYPOINT ["tini", "--", "/scripts/init.sh"]
CMD []
