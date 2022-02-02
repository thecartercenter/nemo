FROM ruby:2.7.5
RUN apt-get update -qq \
    && apt-get install -y nodejs postgresql-client
COPY . /nemo/

RUN echo 'export RAILS_ENV=production' >> ~/.bashrc \
    && exec $SHELL
    
WORKDIR /nemo/

COPY config/database.yml.docker /nemo/config/database.yml
COPY docs/memcached.conf /etc/

RUN bundle install --without development test --deployment

# RUN bundle exec"0 0 * * *" -i nemo # FIXME



COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Configure the main process to run when running the image
CMD ["rails", "server", "-b", "0.0.0.0"]