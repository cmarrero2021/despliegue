module.exports = {
  apps: [
    {
      name: "despliegue-auth",
      cwd: "/var/www/html/despliegue/auth",
      script: "src/index.js",
      watch: false,
      env_development: {
        NODE_ENV: "development",
        PORT: 4111
      },
      env_production: {
        NODE_ENV: "production",
        PORT: 4111
      }
    },
    {
      name: "despliegue-analytics",
      cwd: "/var/www/html/despliegue/analytics",
      script: "src/index.js",
      watch: false,
      env_development: {
        NODE_ENV: "development",
        PORT: 4121
      },
      env_production: {
        NODE_ENV: "production",
        PORT: 4121
      }
    },
    {
      name: "despliegue-api",
      cwd: "/var/www/html/despliegue/api",
      script: "src/index.js",
      watch: false,
      env_development: {
        NODE_ENV: "development",
        PORT: 4131
      },
      env_production: {
        NODE_ENV: "production",
        PORT: 4131
      }
    }
  ]
};
