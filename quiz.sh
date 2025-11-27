#!/usr/bin/env bash
set -euo pipefail

QFILE="questions.txt"
HIGHSCORES="highscores.txt"
TIME_LIMIT=20

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

LIMIT=0
MODE="normal"

invalid_input=false


for arg in "$@"; do
    case "$arg" in
        highscores)
            if [ ! -f "$HIGHSCORES" ]; then
                printf "No high scores yet!\n"
                exit 0
            fi
            printf "TOP 5 HIGHSCORES\n"
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

if [ "$invalid_input" = true ]; then
    printf "Unknown argument.\n"
    exit 1
fi


if [ ! -s "$QFILE" ]; then
    printf "Error: questions.txt missing or empty.\n"
    exit 1
fi


USER=""
if [ "$MODE" = "normal" ]; then
    while true; do
        read -r -p "Enter your username: " USER
        if [ -n "$USER" ]; then
            break
        fi
        printf "%bUsername cannot be empty.%b\n" "$RED" "$RESET"
    done
fi

clear
printf "%bWELCOME TO THE QUIZ GAME!%b\n" "$CYAN" "$RESET"
printf "Time limit: %s seconds per question\n" "$TIME_LIMIT"
printf "Mode: %s\n" "$MODE"

if [ "$LIMIT" -gt 0 ]; then
    printf "Question limit: %s\n" "$LIMIT"
fi

printf "\nPress ENTER to start..."
read -r


if command -v shuf >/dev/null 2>&1; then
    mapfile -t ALLQUESTIONS < <(shuf "$QFILE")
else
    mapfile -t ALLQUESTIONS < <(sort -R "$QFILE")
fi

if [ "$LIMIT" -gt 0 ]; then
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
    COUNT=$((COUNT + 1))

    clear
    printf "%bQuestion %s of %s%b\n" "$YELLOW" "$COUNT" "$TOTAL" "$RESET"
    printf "You have %s seconds | Type E to exit\n\n" "$TIME_LIMIT"

    printf "%s\n%s\n%s\n%s\n%s\n\n" "$Q" "$A" "$B" "$C" "$D"

    INPUT=""
    if ! read -r -t "$TIME_LIMIT" -p "Your answer (A/B/C/D/E): " INPUT; then
        printf "\n%bTime's up!%b Correct answer: %s\n" "$RED" "$RESET" "$ANSWER"
        WRONG=$((WRONG + 1))
        STREAK=0
        sleep 2
        continue
    fi

    
    INPUT=$(printf "%s" "$INPUT" | tr '[:lower:]' '[:upper:]')

    
    if [ "$INPUT" = "E" ]; then
        printf "Exiting game...\n"
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
                INPUT=$(printf "%s" "$INPUT" | tr '[:lower:]' '[:upper:]')
                ;;
        esac
    done


    if [ "$INPUT" = "$ANSWER" ]; then
        printf "%bCorrect!%b\n" "$GREEN" "$RESET"
        CORRECT=$((CORRECT + 1))
        STREAK=$((STREAK + 1))
        if [ "$STREAK" -gt "$BEST" ]; then
            BEST="$STREAK"
        fi
    else
        printf "%bWrong!%b\n" "$RED" "$RESET"
        printf "Correct answer was: %s\n" "$ANSWER"
        WRONG=$((WRONG + 1))
        STREAK=0
    fi

    if [ "$MODE" = "practice" ]; then
        sleep 2
    else
        sleep 1
    fi
done

if [ "$exit_requested" = true ]; then
    exit 0
fi


TOTAL_ASKED=$((CORRECT + WRONG))
if [ "$TOTAL_ASKED" -eq 0 ]; then
    exit 0
fi

SCORE=$((100 * CORRECT / TOTAL_ASKED))

clear
printf "%bQUIZ COMPLETE!%b\n" "$CYAN" "$RESET"
printf "--------------------------\n"
printf "Correct:     %s\n" "$CORRECT"
printf "Wrong:       %s\n" "$WRONG"
printf "Score:       %s%%\n" "$SCORE"
printf "Best streak: %s\n" "$BEST"
printf "--------------------------\n"

if [ "$MODE" = "normal" ]; then
    DATE=$(date "+%Y-%m-%d %H:%M")
    printf "%s|%s|%s|%s\n" "$USER" "$SCORE" "$BEST" "$DATE" >> "$HIGHSCORES"
    printf "High score saved!\n"
fi

printf "Thanks for playing!\n"
