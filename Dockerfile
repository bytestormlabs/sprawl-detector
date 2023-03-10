FROM ruby:3.1.0

WORKDIR /home

COPY Gemfile* /home/

RUN bundle config set --local without test, development
RUN bundle config set --global jobs 4
RUN bundle install

COPY . /home/

EXPOSE 3000

CMD bundle exec rails s
