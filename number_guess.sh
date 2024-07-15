#!/bin/bash
# Number guessing game

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

WELCOME() {
  echo Enter your username:
  read USERNAME

  # query db
  USER_QUERY_RESULT=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username = '$USERNAME'")
  # if username not found
  if [[ -z $USER_QUERY_RESULT ]]
  then
    # add to db
    USER_INSERT_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
    echo Welcome, $USERNAME! It looks like this is your first time here.
  else
    # if username found continue to game
    echo $USER_QUERY_RESULT | while IFS="|" read USERNAME GAMES_PLAYED BEST_GAME
    do
      echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    done
  fi
  # Generate random number
  NUMBER=$((1 + $RANDOM % 1000))
  
  # get user guess
  echo -e "\nGuess the secret number between 1 and 1000:"
  read GUESS
  COUNT=1
  echo GUESS is $GUESS. RANDOM_NUMBER is $NUMBER
}

CHECK_GUESS() {
  until [[ $GUESS =~ [0-9]+ ]]
  do
    echo That is not an integer, guess again:
    read GUESS
  done
}

MAIN() {
  case $(( 
    ($GUESS > $NUMBER) * 1 +
    ($GUESS < $NUMBER ) * 2 + 
    ($GUESS == $NUMBER) * 3 )) in
    (1) echo -e "\nIt's lower than that, guess again:"
        read GUESS
        CHECK_GUESS
        # update count
        ((COUNT+=1))
        MAIN ;;
    (2) echo -e "\nIt's higher than that, guess again:"
        read GUESS
        CHECK_GUESS
        # update count
        ((COUNT+=1))
        MAIN ;;
    (3) echo -e "\nYou guessed it in $COUNT tries. The secret number was $NUMBER. Nice job!" ;;
  esac
}

UPDATE_USER_INFO() {
  # Update user info
  UPDATE_NUM_GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE username = '$USERNAME'")
  BEST_GAME_QY_RESULT=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME'")
  # if first game, always update
  if (( $BEST_GAME_QY_RESULT == 0))
  then
    UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game = $COUNT WHERE username = '$USERNAME'")
  else  
    if (( $COUNT <= $BEST_GAME_QY_RESULT ))
    then
      UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game = $COUNT WHERE username = '$USERNAME'")
    fi
  fi
}

# Main program
WELCOME
CHECK_GUESS
MAIN
UPDATE_USER_INFO