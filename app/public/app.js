const elements = {
  healthBadge: document.querySelector("#healthBadge"),
  healthText: document.querySelector("#healthText"),
  refreshButton: document.querySelector("#refreshButton"),
  lastUpdated: document.querySelector("#lastUpdated"),
  environment: document.querySelector("#environment"),
  version: document.querySelector("#version"),
  awsRegion: document.querySelector("#awsRegion"),
  uptime: document.querySelector("#uptime"),
  serviceName: document.querySelector("#serviceName"),
  gitCommit: document.querySelector("#gitCommit"),
  hostname: document.querySelector("#hostname"),
  nodeVersion: document.querySelector("#nodeVersion"),
  memoryUsage: document.querySelector("#memoryUsage"),
  footerTimestamp: document.querySelector("#footerTimestamp"),
};

function formatUptime(totalSeconds) {
  const seconds = Math.max(0, Number(totalSeconds) || 0);

  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  if (days > 0) {
    return `${days}d ${hours}h`;
  }

  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }

  return `${minutes}m`;
}

function setHealthState(status) {
  elements.healthBadge.classList.remove(
    "checking",
    "healthy",
    "unhealthy",
  );

  if (status === "healthy") {
    elements.healthBadge.classList.add("healthy");
    elements.healthText.textContent = "Healthy";
    return;
  }

  elements.healthBadge.classList.add("unhealthy");
  elements.healthText.textContent = "Unavailable";
}

async function fetchJson(path) {
  const response = await fetch(path, {
    headers: {
      Accept: "application/json",
    },
  });

  if (!response.ok) {
    throw new Error(`${path} returned HTTP ${response.status}`);
  }

  return response.json();
}

async function refreshDashboard() {
  elements.refreshButton.disabled = true;
  elements.refreshButton.textContent = "Refreshing…";
  elements.lastUpdated.textContent = "Retrieving live telemetry";

  try {
    const [health, info] = await Promise.all([
      fetchJson("/health"),
      fetchJson("/api/info"),
    ]);

    setHealthState(health.status);

    elements.environment.textContent =
      info.application.environment.toUpperCase();

    elements.version.textContent = info.application.version;
    elements.awsRegion.textContent = info.deployment.awsRegion;
    elements.uptime.textContent = formatUptime(info.runtime.uptimeSeconds);

    elements.serviceName.textContent = info.application.service;
    elements.gitCommit.textContent = info.deployment.gitCommit;
    elements.hostname.textContent = info.runtime.hostname;
    elements.nodeVersion.textContent = info.runtime.nodeVersion;
    elements.memoryUsage.textContent = `${info.runtime.memoryUsageMb} MB`;

    const updatedAt = new Date(info.timestamp);

    elements.lastUpdated.textContent =
      `Updated ${updatedAt.toLocaleTimeString()}`;

    elements.footerTimestamp.textContent =
      `Last telemetry: ${updatedAt.toLocaleString()}`;
  } catch (error) {
    console.error("Unable to refresh dashboard:", error);
    setHealthState("unhealthy");
    elements.lastUpdated.textContent = "Telemetry request failed";
    elements.footerTimestamp.textContent = "Application data unavailable";
  } finally {
    elements.refreshButton.disabled = false;
    elements.refreshButton.textContent = "Refresh telemetry";
  }
}

elements.refreshButton.addEventListener("click", refreshDashboard);

refreshDashboard();

setInterval(refreshDashboard, 15000);