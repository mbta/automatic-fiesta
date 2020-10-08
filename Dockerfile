FROM hexpm/elixir:1.10.3-erlang-23.0.2-alpine-3.11.6 as builder

WORKDIR /root

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

RUN apk add --update git make build-base erlang-dev

ENV MIX_ENV=prod

ADD apps apps
ADD config config
ADD mix.* /root/

RUN mix do deps.get --only prod, phx.swagger.generate, compile, phx.digest

ADD rel/ rel/

RUN mix release

# The one the elixir image was built with
FROM alpine:3.11.6

RUN apk add --update libssl1.1 curl bash dumb-init \
  && rm -rf /var/cache/apk/*

WORKDIR /root

COPY --from=builder /root/_build/prod/rel/api_web /root/rel
COPY --from=builder /root/rel/bin/startup /root/rel/bin/

# Set exposed ports
EXPOSE 4000
ENV PORT=4000 MIX_ENV=prod TERM=xterm LANG=C.UTF-8 REPLACE_OS_VARS=true

RUN mkdir /root/work

WORKDIR /root/work

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/root/rel/bin/startup", "start"]
