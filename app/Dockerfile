FROM nginx:alpine
ARG VERSION=v1
ARG COLOR=blue
COPY . /usr/share/nginx/html
RUN sed -i "s/__VERSION__/${VERSION}/g; s/__COLOR__/${COLOR}/g" /usr/share/nginx/html/index.html \
 && rm /usr/share/nginx/html/Dockerfile
EXPOSE 80
