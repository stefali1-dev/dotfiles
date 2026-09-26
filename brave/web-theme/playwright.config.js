const { defineConfig } = require("@playwright/test");

module.exports = defineConfig({
  testDir: "tests",
  // The tests share one Brave with one profile copy.
  workers: 1,
  timeout: 60000,
  reporter: "list",
});
