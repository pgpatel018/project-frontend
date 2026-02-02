# -------- Stage 1: Build React app --------
FROM node:current-alpine3.23 AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build


# -------- Stage 2: OpenShift-compatible Nginx --------
FROM nginx:1.25-alpine

# OpenShift runs containers with random UID
# Grant permissions to group 0 (root group)
RUN chmod -R g+rwX /var/cache/nginx \
    /var/run \
    /var/log/nginx \
    /usr/share/nginx/html \
 && chgrp -R 0 /var/cache/nginx \
    /var/run \
    /var/log/nginx \
    /usr/share/nginx/html

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy React build
COPY --from=build /app/build /usr/share/nginx/html

# OpenShift-friendly port
EXPOSE 8080

# Nginx must run in foreground
CMD ["nginx", "-g", "daemon off;"]