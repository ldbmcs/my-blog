FROM nginx:1.19.7-alpine
COPY public /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]
