FROM ruby:3.1.0

WORKDIR /home

COPY Gemfile* /home/

RUN bundle config set --local without test
RUN bundle config set --global jobs 4
RUN bundle install

COPY . /home/

CMD bundle exec rails s
