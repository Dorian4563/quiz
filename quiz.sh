#!/bin/bash

QFILE="questions.txt"
HIGHSCORES="highscores.txt"
TIME_LIMIT=20

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

LIMIT=0   # number of questions to ask, 0 = all

# -------------------------------
# Parse argument: highscores / practice / limit
# -------------------------------
for arg in "$@"; do
    case "$arg" in
        highscores)
            if [[ ! -f "$HIGHSCORES" ]]; then
                echo "No high scores yet!"
                exit
            fi
            echo "TOP 5 HIGHSCORES"
            sort -t"|" -k2,2nr "$HIGHSCORES" | head -5 | \
            awk -F"|" '{printf "%-10s %5s%%  %s  %s\n",$1,$2,$3,$4}'
            exit
        ;;
        practice)
            MODE="practice"
        ;;
        --limit=*)
            LIMIT="${arg#*=}"
        ;;
    esac
done

[[ -z "$MODE" ]] && MODE="normal"

# -------------------------------
# Check questions file
# -------------------------------
if [[ ! -s "$QFILE" ]]; then
    echo "Error: questions.txt missing or empty."
    exit 1
fi

# -------------------------------
# Username (normal mode only)
# -------------------------------
if [[ "$MODE" == "normal" ]]; then
    while true; do
        read -p "Enter your username: " USER
        [[ -n "$USER" ]] && break
        echo -e "${RED}Username cannot be empty.${RESET}"
    done
fi

clear
echo -e "${CYAN}WELCOME TO THE QUIZ GAME!${RESET}"
echo "Time limit: $TIME_LIMIT seconds per question"
echo "Mode: $MODE"
[[ "$LIMIT" -gt 0 ]] && echo "Question limit: $LIMIT"
echo
read -p "Press ENTER to start..."

# -------------------------------
# Load and shuffle questions
# -------------------------------
mapfile -t ALLQUESTIONS < <(shuf "$QFILE")

if [[ "$LIMIT" -gt 0 ]]; then
    mapfile -t QUESTIONS < <(printf "%s\n" "${ALLQUESTIONS[@]:0:LIMIT}")
else
    mapfile -t QUESTIONS < <(printf "%s\n" "${ALLQUESTIONS[@]}")
fi

TOTAL=${#QUESTIONS[@]}
CORRECT=0
WRONG=0
STREAK=0
BEST=0
COUNT=0

# -------------------------------
# Main Question Loop
# -------------------------------
for LINE in "${QUESTIONS[@]}"; do
    
    IFS="|" read -r Q A B C D ANSWER <<< "$LINE"
    ((COUNT++))

    clear
    echo -e "${YELLOW}Question $COUNT of $TOTAL${RESET}"
    echo "You have $TIME_LIMIT seconds | Type E to exit"
    echo

    echo "$Q"
    echo "$A"
    echo "$B"
    echo "$C"
    echo "$D"
    echo

    # Timed input with fallback
    INPUT=""
    SECONDS=0
    read -t "$TIME_LIMIT" -p "Your answer (A/B/C/D/E): " INPUT
    INPUT=${INPUT^^}

    # Time out
    if [[ $? -ne 0 ]]; then
        echo -e "\n${RED}Time's up!${RESET} Correct answer: $ANSWER"
        ((WRONG++))
        STREAK=0
        [[ -x /usr/bin/play ]] && play -q /usr/share/sounds/warning.wav 2>/dev/null
        sleep 2
        continue
    fi

    # Exit the quiz
    if [[ "$INPUT" == "E" ]]; then
        echo "Exiting game..."
        break
    fi

    # Validate input
    while [[ ! "$INPUT" =~ ^[ABCD]$ ]]; do
        read -p "Invalid! Enter A, B, C, D, or E: " INPUT
        INPUT=${INPUT^^}
        [[ "$INPUT" == "E" ]] && break 2
    done

    # Correct / Wrong
    if [[ "$INPUT" == "$ANSWER" ]]; then
        echo -e "${GREEN}Correct!${RESET}"
        ((CORRECT++))
        ((STREAK++))
        ((STREAK > BEST)) && BEST=$STREAK
    else
        echo -e "${RED}Wrong!${RESET}"
        echo "Correct answer was: $ANSWER"
        ((WRONG++))
        STREAK=0
    fi

    [[ "$MODE" == "practice" ]] && sleep 2 || sleep 1

done

# -------------------------------
# Final results
# -------------------------------
TOTAL_ASKED=$((CORRECT + WRONG))
[[ "$TOTAL_ASKED" -eq 0 ]] && exit

SCORE=$(( 100 * CORRECT / TOTAL_ASKED ))

clear
echo -e "${CYAN}QUIZ COMPLETE!${RESET}"
echo "--------------------------"
echo "Correct:     $CORRECT"
echo "Wrong:       $WRONG"
echo "Score:       $SCORE%"
echo "Best streak: $BEST"
echo "--------------------------"

# -------------------------------
# Save highscore
# -------------------------------
if [[ "$MODE" == "normal" ]]; then
    DATE=$(date +"%Y-%m-%d %H:%M")
    echo "$USER|$SCORE|$BEST|$DATE" >> "$HIGHSCORES"
    echo "High score saved!"
fi

echo "Thanks for playing!"
