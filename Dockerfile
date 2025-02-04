# Docker image for the Nginx web server that serves the exchange_rates.html file

# Use the official Nginx image from Docker Hub
FROM nginx:alpine

# Copy the exchange_rates.html from the host to the Nginx web root directory
COPY ./www/exchange_rates.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80