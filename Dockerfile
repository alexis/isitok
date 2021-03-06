FROM ruby:2.7-alpine

ENV LANG C.UTF-8

WORKDIR /app

RUN apk --no-cache add build-base libcurl

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENTRYPOINT ["bundle", "exec", "ruby", "isitok"]
