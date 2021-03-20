# Isitok
A simple script that periodically checks availability of your sites and
sends notifications to a Telegram chat.

## Usage
### With Docker
Just download [isitok.yaml](isitok.yaml?raw=1) and modify it as needed. Then run:

```shell
docker run --rm -it -v $PWD/isitok.yaml:/app/isitok.yaml alexisowl/isitok
```

### Without Docker
Of course, it's just a little ruby script, with a Gemfile, so feel free to clone the repo,
install dependencies, modify `isitok.yaml` and start it with `./isitok.rb`.

I recommend installing dependecies in a local directory to avoid poluting your system gems:

```shell
bundle config set path ./vendor
bundle install
```

## Configuration
```yaml
# isitok.yaml
notifications:
  delay: 150 # 2.5 min
telegram:
  chat_id: -1001XXXXXXXXX
  api_id: 1XXXXXXXXX:AXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
sites:
  example.com: / # check availability of https://example.com/
  example.com: /page.html # check availability of https://example.com/page.html
  http://example.com: / # https by default
  https://user:password@example.com: / # simple authentication (WILL BE VISIBLE IN NOTIFICATIONS!)
custom_checks:
  example.com:
    /page:
      http_code: 401 # passes when https://example.com/page fails with HTTP 401 (authentication error)
```
