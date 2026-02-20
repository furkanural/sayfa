# Stage 1: Build
FROM elixir:1.19-otp-28 AS builder
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && MIX_ENV=prod mix deps.compile
COPY . .
RUN MIX_ENV=prod mix sayfa.build

# Stage 2: Serve
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/output /usr/share/nginx/html
EXPOSE 80
