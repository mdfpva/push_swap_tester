#!/bin/bash

# ============================================================
#  push_swap tester — 42 Porto
#  Corre de dentro da pasta do tester (clonada no projecto)
# ============================================================

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

PASS=0
FAIL=0

# Pasta do tester e pasta do projecto (pai)
TESTER_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$TESTER_DIR")"

PS="$PROJECT_DIR/push_swap"
CK="$TESTER_DIR/checker_linux"
CKB="$PROJECT_DIR/checker"

ok()  { echo -e "  ${GREEN}[OK]${RESET}  $1"; ((PASS++)); }
ko()  { echo -e "  ${RED}[KO]${RESET}  $1"; ((FAIL++)); }
info(){ echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
note(){ echo -e "  ${YELLOW}NOTE:${RESET} $1"; }

count_ops() {
    "$PS" $1 2>/dev/null | wc -l | tr -d ' '
}

# ============================================================
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       push_swap TESTER — 42 Porto        ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo -e "  ${YELLOW}Projecto:${RESET} $PROJECT_DIR"

# ── BUILD ────────────────────────────────────────────────────
info "BUILD"

if [ ! -f "$PROJECT_DIR/Makefile" ]; then
    echo -e "  ${RED}[KO]${RESET}  Makefile não encontrado em $PROJECT_DIR"
    exit 1
fi

echo -e "  ${YELLOW}»${RESET} A correr 'make'..."
make_out=$(make -C "$PROJECT_DIR" 2>&1)
if [ $? -eq 0 ] && [ -f "$PS" ]; then
    ok "make → push_swap compilado com sucesso"
else
    ko "make → falhou a compilar"
    echo "$make_out" | tail -5 | sed 's/^/       /'
    exit 1
fi

echo -e "  ${YELLOW}»${RESET} A correr 'make bonus'..."
bonus_out=$(make -C "$PROJECT_DIR" bonus 2>&1)
if [ $? -eq 0 ]; then
    ok "make bonus → compilado com sucesso"
    [ -f "$CKB" ] && ok "Executável 'checker' (bonus) gerado" || note "'checker' não gerado pelo bonus"
else
    note "make bonus → falhou ou não implementado (não é obrigatório para mandatório)"
fi

echo -e "  ${YELLOW}»${RESET} A correr 'make clean'..."
clean_out=$(make -C "$PROJECT_DIR" clean 2>&1)
if [ $? -eq 0 ]; then
    ok "make clean → objectos intermédios removidos"
else
    ko "make clean → falhou"
fi

# ── PRÉ-REQUISITOS ───────────────────────────────────────────
info "PRÉ-REQUISITOS"

if [ ! -f "$PS" ]; then
    ko "Executável 'push_swap' não encontrado após compilação"
    exit 1
fi
ok "Executável push_swap presente"

if [ ! -f "$CK" ]; then
    note "checker_linux não encontrado — testes de checker serão ignorados"
    HAS_CHECKER=0
else
    chmod +x "$CK"
    ok "checker_linux encontrado"
    HAS_CHECKER=1
fi

# ── MAKEFILE ────────────────────────────────────────────────
info "COMPILAÇÃO (Makefile)"

for rule in all clean fclean re; do
    if grep -qE "^$rule" "$PROJECT_DIR/Makefile"; then
        ok "Regra '$rule' presente no Makefile"
    else
        ko "Regra '$rule' ausente no Makefile"
    fi
done
if grep -q "\-Wall" "$PROJECT_DIR/Makefile" && grep -q "\-Wextra" "$PROJECT_DIR/Makefile" && grep -q "\-Werror" "$PROJECT_DIR/Makefile"; then
    ok "Flags de compilação (-Wall -Wextra -Werror) presentes"
else
    ko "Flags de compilação (-Wall -Wextra -Werror) em falta"
fi

# ── NORMINETTE ───────────────────────────────────────────────
info "NORMINETTE"

if command -v norminette &>/dev/null; then
    norm_out=$(norminette "$PROJECT_DIR" 2>&1)
    if echo "$norm_out" | grep -q "Error"; then
        ko "Norminette encontrou erros"
        echo "$norm_out" | grep "Error" | head -5 | sed 's/^/       /'
    else
        ok "Norminette: sem erros"
    fi
else
    note "norminette não instalada — saltar teste"
fi

# ── GESTÃO DE ERROS ──────────────────────────────────────────
info "GESTÃO DE ERROS"

err=$("$PS" "abc" 2>&1 >/dev/null)
echo "$err" | grep -q "^Error$" \
    && ok "Parâmetro não numérico → 'Error\\n' no stderr" \
    || ko "Parâmetro não numérico → esperado 'Error\\n' no stderr (obteve: '$err')"

err=$("$PS" "1 2 1" 2>&1 >/dev/null)
echo "$err" | grep -q "^Error$" \
    && ok "Parâmetro duplicado → 'Error\\n' no stderr" \
    || ko "Parâmetro duplicado → esperado 'Error\\n' no stderr (obteve: '$err')"

err=$("$PS" "1 2147483648" 2>&1 >/dev/null)
echo "$err" | grep -q "^Error$" \
    && ok "Valor > MAXINT → 'Error\\n' no stderr" \
    || ko "Valor > MAXINT → esperado 'Error\\n' no stderr (obteve: '$err')"

out=$("$PS" 2>&1)
[ -z "$out" ] \
    && ok "Sem parâmetros → sem output" \
    || ko "Sem parâmetros → esperado sem output (obteve: '$out')"

# ── STRATEGY FLAGS ───────────────────────────────────────────
info "STRATEGY FLAGS (--simple / --medium / --complex / --adaptive)"

for flag in --simple --medium --complex --adaptive; do
    out=$("$PS" $flag 5 4 3 2 1 2>/dev/null)
    if [ -n "$out" ]; then
        if [ $HAS_CHECKER -eq 1 ]; then
            result=$(echo "$out" | "$CK" 5 4 3 2 1 2>/dev/null)
            if [ "$result" = "OK" ]; then
                ops=$(echo "$out" | wc -l | tr -d ' ')
                ok "$flag \"5 4 3 2 1\" → OK ($ops operações)"
            else
                ko "$flag \"5 4 3 2 1\" → checker retornou '$result'"
            fi
        else
            ok "$flag \"5 4 3 2 1\" → produz output (checker não disponível)"
        fi
    else
        ko "$flag → sem output ou erro"
    fi
done

out=$("$PS" 5 4 3 2 1 2>/dev/null)
[ -n "$out" ] \
    && ok "Sem flag → produz output (comportamento adaptive)" \
    || ko "Sem flag → sem output esperado"

# ── IDENTITY TESTS ───────────────────────────────────────────
info "IDENTITY TESTS (já ordenados)"

for args in "42" "2 3" "0 1 2 3" "0 1 2 3 4 5 6 7 8 9"; do
    out=$("$PS" $args 2>/dev/null)
    if [ -z "$out" ]; then
        ok "\"$args\" → sem output (correto)"
    else
        ops=$(echo "$out" | wc -l | tr -d ' ')
        ko "\"$args\" → esperado sem output, obteve $ops operações"
    fi
done

# ── SMALL INPUTS (3 números) ─────────────────────────────────
info "SMALL INPUTS (3 números)"

for args in "2 1 0" "0 2 1" "1 0 2"; do
    if [ $HAS_CHECKER -eq 1 ]; then
        ops=$(count_ops "$args")
        result=$("$PS" $args 2>/dev/null | "$CK" $args 2>/dev/null)
        if [ "$result" = "OK" ]; then
            if [ "$ops" -le 3 ]; then
                ok "\"$args\" → OK ($ops ops — excelente ≤3)"
            elif [ "$ops" -le 5 ]; then
                ok "\"$args\" → OK ($ops ops — aceitável ≤5)"
            else
                ko "\"$args\" → OK mas muitas operações ($ops > 5)"
            fi
        else
            ko "\"$args\" → checker retornou '$result'"
        fi
    else
        out=$("$PS" $args 2>/dev/null)
        [ -n "$out" ] && ok "\"$args\" → produz output" || ko "\"$args\" → sem output"
    fi
done

# ── MEDIUM INPUTS (5 números) ────────────────────────────────
info "MEDIUM INPUTS (5 números)"

for args in "1 5 2 4 3" "5 1 4 2 3" "3 5 1 4 2"; do
    if [ $HAS_CHECKER -eq 1 ]; then
        ops=$(count_ops "$args")
        result=$("$PS" $args 2>/dev/null | "$CK" $args 2>/dev/null)
        if [ "$result" = "OK" ]; then
            if [ "$ops" -le 12 ]; then
                ok "\"$args\" → OK ($ops ops — bom ≤12)"
            elif [ "$ops" -le 15 ]; then
                ok "\"$args\" → OK ($ops ops — aceitável ≤15)"
            else
                ko "\"$args\" → OK mas muitas operações ($ops > 15)"
            fi
        else
            ko "\"$args\" → checker retornou '$result'"
        fi
    else
        out=$("$PS" $args 2>/dev/null)
        [ -n "$out" ] && ok "\"$args\" → produz output" || ko "\"$args\" → sem output"
    fi
done

# ── BENCHMARK MODE ───────────────────────────────────────────
info "BENCHMARK MODE"

bench_out=$("$PS" --bench --simple 5 4 3 2 1 2>/dev/null)
[ -n "$bench_out" ] \
    && ok "--bench --simple → produz output no stdout" \
    || ko "--bench --simple → sem output no stdout"

bench_err=$("$PS" --bench --simple 5 4 3 2 1 2>&1 >/dev/null)
if [ -n "$bench_err" ]; then
    ok "--bench → produz output de benchmark no stderr"
    echo "$bench_err" | grep -iq "disorder\|desordem\|%" \
        && ok "Benchmark contém percentagem de desordem" \
        || note "Percentagem de desordem não detetada no output"
    echo "$bench_err" | grep -iq "operat\|total\|count\|ops" \
        && ok "Benchmark contém contagem de operações" \
        || note "Contagem de operações não detetada"
else
    ko "--bench → sem output de benchmark no stderr"
fi

bench_sorted=$("$PS" --bench --simple 1 2 3 4 5 2>&1 >/dev/null)
bench_reverse=$("$PS" --bench --simple 5 4 3 2 1 2>&1 >/dev/null)
note "Disorder input ordenado:  $(echo "$bench_sorted"  | grep -oE '[0-9]+\.[0-9]+%' | head -1)"
note "Disorder input invertido: $(echo "$bench_reverse" | grep -oE '[0-9]+\.[0-9]+%' | head -1)"

# ── LARGE INPUTS (100 números) ───────────────────────────────
info "LARGE INPUTS (100 números)"

if [ $HAS_CHECKER -eq 1 ]; then
    for i in 1 2; do
        ARG=$(shuf -i 1-500 -n 100 | tr '\n' ' ')
        ops=$(count_ops "$ARG")
        result=$("$PS" $ARG 2>/dev/null | "$CK" $ARG 2>/dev/null)
        if [ "$result" = "OK" ]; then
            if [ "$ops" -lt 700 ]; then
                ok "100 nums (run $i) → OK ($ops ops — excelente <700)"
            elif [ "$ops" -lt 1500 ]; then
                ok "100 nums (run $i) → OK ($ops ops — bom <1500)"
            elif [ "$ops" -lt 2000 ]; then
                ok "100 nums (run $i) → OK ($ops ops — aceitável <2000)"
            else
                ko "100 nums (run $i) → OK mas lento ($ops ops > 2000)"
            fi
        else
            ko "100 nums (run $i) → checker retornou '$result'"
        fi
    done
else
    note "checker_linux não disponível — saltar teste 100 números"
fi

# ── COMPARAÇÃO DE ESTRATÉGIAS (50 números) ───────────────────
info "COMPARAÇÃO DE ESTRATÉGIAS (50 números)"

if [ $HAS_CHECKER -eq 1 ]; then
    ARG50=$(shuf -i 1-200 -n 50 | tr '\n' ' ')
    for flag in --simple --medium --complex; do
        ops=$("$PS" $flag $ARG50 2>/dev/null | wc -l | tr -d ' ')
        result=$("$PS" $flag $ARG50 2>/dev/null | "$CK" $ARG50 2>/dev/null)
        [ "$result" = "OK" ] \
            && ok "$flag 50 nums → OK ($ops ops)" \
            || ko "$flag 50 nums → checker retornou '$result'"
    done
else
    note "checker_linux não disponível — saltar comparação de estratégias"
fi

# ── VERY LARGE INPUTS (500 números) ──────────────────────────
info "VERY LARGE INPUTS (500 números)"

if [ $HAS_CHECKER -eq 1 ]; then
    for i in 1 2; do
        ARG=$(shuf -i 1-1000 -n 500 | tr '\n' ' ')
        ops=$(count_ops "$ARG")
        result=$("$PS" $ARG 2>/dev/null | "$CK" $ARG 2>/dev/null)
        if [ "$result" = "OK" ]; then
            if [ "$ops" -lt 5500 ]; then
                ok "500 nums (run $i) → OK ($ops ops — excelente <5500)"
            elif [ "$ops" -lt 8000 ]; then
                ok "500 nums (run $i) → OK ($ops ops — bom <8000)"
            elif [ "$ops" -lt 12000 ]; then
                ok "500 nums (run $i) → OK ($ops ops — aceitável <12000)"
            else
                ko "500 nums (run $i) → OK mas lento ($ops ops > 12000)"
            fi
        else
            ko "500 nums (run $i) → checker retornou '$result'"
        fi
    done
else
    note "checker_linux não disponível — saltar teste 500 números"
fi

# ── BONUS: CHECKER GESTÃO DE ERROS ───────────────────────────
info "BONUS — CHECKER: GESTÃO DE ERROS"

if [ -f "$CKB" ]; then
    err=$("$CKB" "abc" 2>&1 >/dev/null)
    echo "$err" | grep -q "^Error$" \
        && ok "checker: parâmetro não numérico → Error" \
        || ko "checker: parâmetro não numérico → esperado Error (obteve: '$err')"

    err=$("$CKB" "1 2 1" 2>&1 >/dev/null)
    echo "$err" | grep -q "^Error$" \
        && ok "checker: duplicado → Error" \
        || ko "checker: duplicado → esperado Error (obteve: '$err')"

    err=$("$CKB" "1 2147483648" 2>&1 >/dev/null)
    echo "$err" | grep -q "^Error$" \
        && ok "checker: > MAXINT → Error" \
        || ko "checker: > MAXINT → esperado Error"

    out=$("$CKB" 2>&1)
    [ -z "$out" ] \
        && ok "checker: sem parâmetros → sem output" \
        || ko "checker: sem parâmetros → esperado sem output"

    err=$(echo "zz" | "$CKB" "1 2 3" 2>&1 >/dev/null)
    echo "$err" | grep -q "^Error$" \
        && ok "checker: instrução inválida → Error" \
        || ko "checker: instrução inválida → esperado Error"

    err=$(printf " sa\n" | "$CKB" "1 2 3" 2>&1 >/dev/null)
    echo "$err" | grep -q "^Error$" \
        && ok "checker: instrução com espaço extra → Error" \
        || ko "checker: instrução com espaço extra → esperado Error"

    info "BONUS — CHECKER: TESTES FALSOS"
    result=$(printf "sa\npb\nrrr\n" | "$CKB" 0 9 1 8 2 7 3 6 4 5 2>/dev/null)
    [ "$result" = "KO" ] \
        && ok "checker: [sa, pb, rrr] em \"0 9 1 8 2 7 3 6 4 5\" → KO" \
        || ko "checker: esperado KO (obteve: '$result')"

    info "BONUS — CHECKER: TESTES CORRETOS"
    result=$(printf "" | "$CKB" 0 1 2 2>/dev/null)
    [ "$result" = "OK" ] \
        && ok "checker: \"0 1 2\" sem instruções → OK" \
        || ko "checker: \"0 1 2\" sem instruções → esperado OK (obteve: '$result')"

    result=$(printf "pb\nra\npb\nra\nsa\nra\npa\npa\n" | "$CKB" 0 9 1 8 2 2>/dev/null)
    [ "$result" = "OK" ] \
        && ok "checker: [pb,ra,pb,ra,sa,ra,pa,pa] em \"0 9 1 8 2\" → OK" \
        || ko "checker: esperado OK (obteve: '$result')"
else
    note "Executável 'checker' (bonus) não encontrado — testes de bonus ignorados"
fi

# ── CLEANUP FINAL ────────────────────────────────────────────
info "CLEANUP FINAL"
echo -e "  ${YELLOW}»${RESET} A correr 'make fclean'..."
fclean_out=$(make -C "$PROJECT_DIR" fclean 2>&1)
if [ $? -eq 0 ]; then
    ok "make fclean → projecto limpo"
else
    ko "make fclean → falhou"
fi

# ── SUMÁRIO FINAL ────────────────────────────────────────────
TOTAL=$((PASS + FAIL))
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║              RESULTADO FINAL             ║${RESET}"
echo -e "${BOLD}╠══════════════════════════════════════════╣${RESET}"
echo -e "${BOLD}║${RESET}  ${GREEN}OK: $PASS${RESET} / $TOTAL  |  ${RED}KO: $FAIL${RESET} / $TOTAL              ${BOLD}║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}\n"
