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
Of course, it's just a little ruby script with a Gemfile, so feel free to clone the repo,
install dependencies, modify `isitok.yaml` and start it with `./isitok.rb`.

I recommend installing dependencies in a subfolder to avoid poluting your system gems:

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
  api_id: 1XXXXXXXXX:AXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  chat_id: -1001XXXXXXXXX
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

### Getting your `api_id` from Telegram

Create your bot with [botfather](https://t.me/botfather) and get the access token from its answer.

**Don't forget to add your bot to your chat (for channels this means adding it as admin).**

### Your `chat_id`

There's no single standard way to get your chat ID, but many well [known](https://gist.github.com/mraaroncruz/e76d19f7d61d59419002db54030ebe35)
[work](https://stackoverflow.com/a/32572159/786948) [arounds](https://stackoverflow.com/a/46247058/786948).
