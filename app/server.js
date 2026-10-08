import express from "express";

const app = express();
const appName = process.env.APP_NAME;
const port = process.env.PORT || 3000;
const secretFavoriteColor = process.env.SECRET_FAVORITE_COLOR || "unknown";

// Health endpoints
app.get("/healthz", (_req, res) => res.status(200).send("Ok"));
app.get("/readyz", (_req, res) => res.status(200).send("Ready"));

// Business endpoint
app.all("*", (_req, res) => res.status(200).send("Hello World!"));

const server = app.listen(port, () => {
  console.log(`${appName} listening on ${port}`);
  console.log(`Secret Favorite Color loaded: ${secretFavoriteColor ? "***" : "unkown"}`);
});

// Graceful shutdown
const shutdown = () => {
  console.log("Shutting down...");
  server.close(() => process.exit(0));
  // Hard kill after 10s
  setTimeout(() => process.exit(1), 10000).unref();
};
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);