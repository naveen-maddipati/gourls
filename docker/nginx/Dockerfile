FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Remove default nginx website
RUN rm /etc/nginx/conf.d/default.conf

# Copy our nginx configuration
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint script
COPY docker/nginx/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]