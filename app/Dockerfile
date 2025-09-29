# ----- Build stage -----
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund
COPY server.js ./server.js

# ----- Runtime stage -----
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app

# Non-root user for security
RUN addgroup -g 10001 app && adduser -u 10001 -G app -D app
USER 10001:10001

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/server.js ./server.js
COPY --from=build /app/package.json ./package.json

EXPOSE 3000
CMD ["npm", "start"]