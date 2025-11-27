#!/bin/bash

QFILE="questions.txt"
HIGHSCORES="highscores.txt"
TIME_LIMIT=10

if [[ "$1" == "highscores" ]]; then
    [[ ! -f "$HIGHSCORES" ]] && echo "No high scores yet!" && exit
    echo "TOP 5 HIGHSCORES"
    sort -t"|" -k2 -nr "$HIGHSCORES" | head -5 | \
    awk -F"|" '{printf "%-10s %5s%%  %s  %s\n",$1,$2,$3,$4}'
    exit
fi

if [[ ! -s "$QFILE" ]]; then
    echo "Error: questions.txt missing or empty."
    exit 1
fi

MODE="normal"
[[ "$1" == "practice" ]] && MODE="practice"

if [[ "$MODE" == "normal" ]]; then
    read -p "Enter your username: " USER
fi

mapfile -t QUESTIONS < <(shuf "$QFILE")

TOTAL=${#QUESTIONS[@]}
CORRECT=0
WRONG=0
STREAK=0
BEST=0
COUNT=0

for LINE in "${QUESTIONS[@]}"; do
    
    IFS="|" read -r Q A B C D ANSWER <<< "$LINE"
    ((COUNT++))

    clear
    echo "Question $COUNT of $TOTAL"
    echo "You have $TIME_LIMIT seconds | Type E to exit"
    echo
    echo "$Q"
    echo "$A"
    echo "$B"
    echo "$C"
    echo "$D"
    echo

    read -t "$TIME_LIMIT" -p "Your answer (A/B/C/D/E): " INPUT
    INPUT=${INPUT^^}

    if [[ $? -ne 0 ]]; then
        echo -e "\n\e[31mTime's up!\e[0m Correct answer: $ANSWER"
        ((WRONG++))
        STREAK=0
        sleep 1.5
        continue
    fi

    if [[ "$INPUT" == "E" ]]; then
        echo "Exiting game..."
        break
    fi

    while [[ ! "$INPUT" =~ ^[ABCD]$ ]]; do
        read -p "Invalid! Enter A, B, C, D, or E: " INPUT
        INPUT=${INPUT^^}
        [[ "$INPUT" == "E" ]] && break 2
    done

    if [[ "$INPUT" == "$ANSWER" ]]; then
        echo -e "\e[32mCorrect!\e[0m"
        ((CORRECT++))
        ((STREAK++))
        ((STREAK > BEST)) && BEST=$STREAK
    else
        echo -e "\e[31mWrong!\e[0m"
        echo "Correct answer was: $ANSWER"
        ((WRONG++))
        STREAK=0
    fi

    [[ "$MODE" == "practice" ]] && sleep 2 || sleep 1

done

TOTAL_ASKED=$((CORRECT + WRONG))
[[ "$TOTAL_ASKED" -eq 0 ]] && exit

SCORE=$(( 100 * CORRECT / TOTAL_ASKED ))

clear
echo "QUIZ COMPLETE!"
echo "--------------------------"
echo "Correct: $CORRECT"
echo "Wrong:   $WRONG"
echo "Score:   $SCORE%"
echo "Best streak: $BEST"
echo "--------------------------"


if [[ "$MODE" == "normal" ]]; then
    DATE=$(date +"%Y-%m-%d %H:%M")
    echo "$USER|$SCORE|$BEST|$DATE" >> "$HIGHSCORES"
    echo "High score saved!"
fi

echo "Thanks for playing!"
