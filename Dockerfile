FROM ruby:3.2.0

WORKDIR /home

COPY * /home/
RUN bundle config set path vendor/bundle
RUN bundle config set --local without test
RUN bundle config set --global jobs 4
RUN bundle install
ENTRYPOINT bundle exec ruby scripts/scan.rb --aws-account-id $AWS_ACCOUNT_ID --profile test
