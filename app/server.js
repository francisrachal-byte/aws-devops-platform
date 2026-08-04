const express = require("express");
const path = require("path");
const os = require("os");

const app = express();

const PORT = Number.parseInt(process.env.PORT || "3000", 10);
const STARTED_AT = new Date();

const config = {
  appName: process.env.APP_NAME || "Platform Pulse",
  serviceName: process.env.SERVICE_NAME || "aws-devops-platform",
  version: process.env.APP_VERSION || "1.0.0",
  environment: process.env.ENVIRONMENT || "local",
  awsRegion: process.env.AWS_REGION || "us-east-1",
  gitCommit: process.env.GIT_COMMIT || "local-dev",
  deployedAt: process.env.DEPLOYED_AT || STARTED_AT.toISOString(),
};

// Express includes an X-Powered-By header by default.
// Removing it exposes less unnecessary implementation information.
app.disable("x-powered-by");

app.use(express.json());

// Basic security-related response headers.
// We can add Helmet later when we containerize the service.
app.use((request, response, next) => {
  response.setHeader("X-Content-Type-Options", "nosniff");
  response.setHeader("X-Frame-Options", "DENY");
  response.setHeader("Referrer-Policy", "no-referrer");
  next();
});

// Structured request logging for CloudWatch and container logs.
app.use((request, response, next) => {
  const startedAt = process.hrtime.bigint();

  response.on("finish", () => {
    const completedAt = process.hrtime.bigint();
    const durationMs = Number(completedAt - startedAt) / 1_000_000;

    console.log(
      JSON.stringify({
        timestamp: new Date().toISOString(),
        level: "info",
        event: "http_request",
        method: request.method,
        path: request.originalUrl,
        statusCode: response.statusCode,
        durationMs: Number(durationMs.toFixed(2)),
        userAgent: request.get("user-agent") || "unknown",
      }),
    );
  });

  next();
});

app.get("/health", (request, response) => {
  response.status(200).json({
    status: "healthy",
    service: config.serviceName,
    version: config.version,
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
  });
});

app.get("/ready", (request, response) => {
  response.status(200).json({
    status: "ready",
    service: config.serviceName,
    timestamp: new Date().toISOString(),
  });
});

app.get("/api/info", (request, response) => {
  response.status(200).json({
    application: {
      name: config.appName,
      service: config.serviceName,
      version: config.version,
      environment: config.environment,
    },
    deployment: {
      gitCommit: config.gitCommit,
      deployedAt: config.deployedAt,
      awsRegion: config.awsRegion,
    },
    runtime: {
      hostname: os.hostname(),
      nodeVersion: process.version,
      platform: process.platform,
      architecture: process.arch,
      uptimeSeconds: Math.floor(process.uptime()),
      memoryUsageMb: Math.round(process.memoryUsage().rss / 1024 / 1024),
    },
    timestamp: new Date().toISOString(),
  });
});

app.use(express.static(path.join(__dirname, "public")));

app.use((request, response) => {
  response.status(404).json({
    status: "not_found",
    message: "The requested resource was not found.",
    path: request.originalUrl,
  });
});

const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      level: "info",
      event: "application_started",
      service: config.serviceName,
      version: config.version,
      environment: config.environment,
      port: PORT,
    }),
  );
});

function shutDown(signal) {
  console.log(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      level: "info",
      event: "shutdown_started",
      signal,
    }),
  );

  server.close((error) => {
    if (error) {
      console.error(
        JSON.stringify({
          timestamp: new Date().toISOString(),
          level: "error",
          event: "shutdown_failed",
          message: error.message,
        }),
      );

      process.exit(1);
    }

    console.log(
      JSON.stringify({
        timestamp: new Date().toISOString(),
        level: "info",
        event: "shutdown_complete",
      }),
    );

    process.exit(0);
  });
}

process.on("SIGTERM", () => shutDown("SIGTERM"));
process.on("SIGINT", () => shutDown("SIGINT"));