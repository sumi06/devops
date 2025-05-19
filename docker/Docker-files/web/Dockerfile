FROM nginx
LABEL "project"="vprofile"
LABEL "author"="Sumi"

RUN rm -rf /etc/nginx/config.d/default.conf
COPY nginvproapp.conf /etc/nginx/config.d/vproapp.conf