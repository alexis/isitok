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
```shell
git clone https://github.com/alexis/isitok.git
cd isitok
gem install bundler
bundle config set path ./vendor && bundle
```

Modify isitok.yaml as needed an run `./isitok.rb`
