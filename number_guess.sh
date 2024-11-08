#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))
# echo "$SECRET_NUMBER"

ASK_USERNAME() {
  while true; do
    echo -e "\nEnter your username:"
    read USERNAME

    USERNAME_CHARACTERS=$(echo $USERNAME | wc -c)
    if [[ $USERNAME_CHARACTERS -le 22 ]]; then
      break
    else
      echo "Username must be 22 characters or fewer. Try again."
    fi
  done
}

ASK_USERNAME
RETURNING_USER=$($PSQL "SELECT username FROM users WHERE username = '$USERNAME'")

if [[ -z $RETURNING_USER ]]; then
  # Insert new user
  INSERTED_USER=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME')")
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  # Fetch game data for returning user
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games INNER JOIN users USING(user_id) WHERE username = '$USERNAME'")
  BEST_GAME=$($PSQL "SELECT MIN(guesses) FROM games INNER JOIN users USING(user_id) WHERE username = '$USERNAME'")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Get user_id
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")

TRIES=1
GUESS=0

GUESSING_MACHINE() {
  while true; do
    read GUESS

    if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
      echo -e "\nThat is not an integer, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
      TRIES=$((TRIES + 1))
      echo -e "\nIt's lower than that, guess again:"
    elif [[ $GUESS -lt $SECRET_NUMBER ]]; then
      TRIES=$((TRIES + 1))
      echo -e "\nIt's higher than that, guess again:"
    else
      echo -e "\nYou guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
      return  # Salimos de la función GUESSING_MACHINE cuando el número es adivinado correctamente
    fi
  done
}

echo -e "\nGuess the secret number between 1 and 1000:"
GUESSING_MACHINE

# Insert game record
INSERTED_GAME=$($PSQL "INSERT INTO games (user_id, guesses) VALUES ($USER_ID, $TRIES)")

# Fin del script
exit 0
