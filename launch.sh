#!/usr/bin/env bash

if [ "$CHAINLIT_RANDOM_SECRET" = "true" ]; then
  # Set the secret_length of the random string
  secret_length=${1:-64}

  # Define the characters that can be used in the secret
  secret_chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$%*,-./:=>?@^_~'

  # Function to generate a random secret
  generate_random_secret() {
    local i=1
    local secret=''

    while [ $i -le $secret_length ]; do
      # Pick a random character from secret_chars
      local index=$(($RANDOM % ${#secret_chars}))
      secret="${secret}${secret_chars:$index:1}"
      ((i++))
    done

    echo "$secret"
  }

  export CHAINLIT_AUTH_SECRET=$(generate_random_secret)
fi

export CHAINLIT_PORT=8051
export PYTHONPATH=$(pwd)
python -m sense.main
