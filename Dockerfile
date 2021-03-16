FROM ruby:2.6
COPY . .
RUN gem install bundler:2.1.4
RUN bundle install
