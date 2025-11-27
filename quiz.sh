#!/bin/bash
QFILE="questions.txt"
HIGHSCORES="highscores.txt"
TIME_LIMIT=20

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

LIMIT=10
MODE="normal"
invalid_input=false

for arg in "$@"; do
    case "$arg" in
        highscores)
            if [[ ! -f "$HIGHSCORES" ]]; then
                echo "No high scores yet!"
                exit 0
            fi
            echo "TOP 5 HIGHSCORES"
            sort -t "|" -k2,2nr "$HIGHSCORES" | head -5 |
                awk -F "|" '{printf "%-10s %5s%%  %s  %s\n",$1,$2,$3,$4}'
            exit 0
            ;;
        practice)
            MODE="practice"
            ;;
        --limit=*)
            LIMIT="${arg#*=}"
            ;;
        *)
            invalid_input=true
            ;;
    esac
done

if [[ "$invalid_input" == true ]]; then
    echo "Unknown argument."
    exit 1
fi


if [[ ! -s "$QFILE" ]]; then
    echo "Error: questions.txt missing or empty."
    exit 1
fi

USER=""
if [[ "$MODE" == "normal" ]]; then
    while true; do
        read -r -p "Enter your username: " USER
        if [[ -n "$USER" ]]; then
            break
        fi
        echo -e "${RED}Username cannot be empty.${RESET}"
    done
fi


clear
echo -e "${CYAN}WELCOME TO THE QUIZ GAME!${RESET}"
echo "Time limit: $TIME_LIMIT seconds per question"
echo "Mode: $MODE"

if [[ "$LIMIT" -gt 0 ]]; then
    echo "Question limit: $LIMIT"
fi

echo
read -r -p "Press ENTER to start..."

if command -v shuf >/dev/null 2>&1; then
    mapfile -t ALLQUESTIONS < <(shuf "$QFILE")
else
    mapfile -t ALLQUESTIONS < <(sort -R "$QFILE")
fi

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

exit_requested=false

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

    INPUT=""
    if ! read -r -t "$TIME_LIMIT" -p "Your answer (A/B/C/D/E): " INPUT; then
        echo -e "\n${RED}Time's up!${RESET} Correct answer: $ANSWER"
        ((WRONG++))
        STREAK=0
        sleep 2
        continue
    fi

    INPUT=${INPUT^^}

    if [[ "$INPUT" == "E" ]]; then
        echo "Exiting game..."
        exit_requested=true
        break
    fi

    
    while true; do
        case "$INPUT" in
            A|B|C|D)
                break
                ;;
            E)
                exit_requested=true
                break 2
                ;;
            *)
                read -r -p "Invalid! Enter A, B, C, D, or E: " INPUT
                INPUT=${INPUT^^}
                ;;
        esac
    done

    
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

if [ "$MODE" = "practice" ]; then
sleep 2
else
sleep 1
fi
done

if [[ "$exit_requested" == true ]]; then
    exit 0
fi

TOTAL_ASKED=$((CORRECT + WRONG))

if [[ "$TOTAL_ASKED" -eq 0 ]]; then
    exit 0
fi

SCORE=$((100 * CORRECT / TOTAL_ASKED))

clear
echo -e "${CYAN}QUIZ COMPLETE!${RESET}"
echo "--------------------------"
echo "Correct:     $CORRECT"
echo "Wrong:       $WRONG"
echo "Score:       $SCORE%"
echo "Best streak: $BEST"
echo "--------------------------"

if [[ "$MODE" == "normal" ]]; then
    DATE=$(date "+%Y-%m-%d %H:%M")
    echo "$USER|$SCORE|$BEST|$DATE" >> "$HIGHSCORES"
    echo "High score saved!"
fi

echo "Thanks for playing!"
