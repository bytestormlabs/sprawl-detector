FROM ruby:3.1.0

WORKDIR /home

COPY * /home/

RUN bundle config set --local without test
RUN bundle config set --global jobs 4
RUN bundle install

CMD bundle exec rails s
