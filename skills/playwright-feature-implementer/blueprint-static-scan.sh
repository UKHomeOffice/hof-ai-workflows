#!/usr/bin/env bash
# Blueprint static scan for Playwright BDD implementations.
# Rule IDs map to playwright-blueprint.md / compliance-checklist.md.
#
# Usage:
#   blueprint-static-scan.sh [--strict] [FILE...]
#
# With no FILE arguments, scans files changed relative to HEAD (staged, unstaged
# and untracked, excluding deletions) in the current git repository.
#
# Output: one finding per line, "<SEVERITY> <file>:<line> <RULE-ID> <message>".
# Exit codes: 0 = no errors (warnings allowed unless --strict), 1 = errors found,
# 2 = usage error.

set -u

strict=0
files=()

while [ $# -gt 0 ]; do
  case "$1" in
    --strict) strict=1 ;;
    -h|--help)
      sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --) shift; while [ $# -gt 0 ]; do files+=("$1"); shift; done; break ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *) files+=("$1") ;;
  esac
  shift
done

if [ ${#files[@]} -eq 0 ]; then
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "No files given and not inside a git repository." >&2
    exit 2
  fi
  root=$(git rev-parse --show-toplevel)
  cd "$root" || exit 2
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    changed=$(git diff --name-only --diff-filter=d HEAD; git ls-files --others --exclude-standard)
  else
    changed=$(git ls-files; git ls-files --others --exclude-standard)
  fi
  while IFS= read -r f; do
    [ -n "$f" ] && files+=("$f")
  done <<EOF
$(printf '%s\n' "$changed" | sort -u)
EOF
fi

if [ ${#files[@]} -eq 0 ]; then
  echo "blueprint-static-scan: no files to scan."
  exit 0
fi

errors=0
warnings=0
scanned=0

report() {
  # report <ERROR|WARN> <file> <line> <id> <message>
  printf '%s %s:%s %s %s\n' "$1" "$2" "$3" "$4" "$5"
  if [ "$1" = "ERROR" ]; then
    errors=$((errors + 1))
  else
    warnings=$((warnings + 1))
  fi
}

comment_re='^[[:space:]]*(//|/\*|\*)'

check() {
  # check <ERROR|WARN> <id> <ere> <message> <file> <skip_comments:0|1>
  local sev=$1 id=$2 re=$3 msg=$4 file=$5 skip=$6 hit lineno content
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    lineno=${hit%%:*}
    content=${hit#*:}
    if [ "$skip" = "1" ] && printf '%s\n' "$content" | grep -Eq "$comment_re"; then
      continue
    fi
    report "$sev" "$file" "$lineno" "$id" "$msg"
  done < <(grep -nE -- "$re" "$file" 2>/dev/null)
}

nb='(^|[^A-Za-z0-9_$])' # identifier boundary (portable replacement for \b)

for file in "${files[@]}"; do
  base=$(basename "$file")

  case "$file" in
    .features-gen/*|*/.features-gen/*|playwright-report/*|*/playwright-report/*|test-results/*|*/test-results/*)
      report ERROR "$file" 0 ARCH-02 "Generated output must not be edited or committed"
      continue
      ;;
  esac

  case "$base" in
    .env.example|.env.sample|.env.template) ;;
    .env|.env.*)
      report ERROR "$file" 0 DATA-04 ".env files must not be committed"
      continue
      ;;
  esac

  if [ ! -f "$file" ]; then
    echo "Cannot scan $file (not a regular file)" >&2
    exit 2
  fi

  is_code=0; is_step=0; is_page=0; is_feature=0
  case "$base" in
    *.ts|*.tsx|*.js|*.mjs|*.cjs) is_code=1 ;;
    *.feature) is_feature=1 ;;
  esac
  if [ $is_code -eq 1 ]; then
    case "$file" in
      *.step.ts|*/steps/*) is_step=1 ;;
    esac
    case "$file" in
      */pages/*) is_page=1 ;;
    esac
  fi

  scanned=$((scanned + 1))

  # DATA-01: real-looking emails and secret-like literals (all text files, comments included).
  check WARN DATA-01 '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}' \
    "Email-like literal; confirm it is synthetic or an approved test recipient" "$file" 0
  check ERROR DATA-01 '(-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16})' \
    "Private key or cloud credential literal" "$file" 0
  check WARN DATA-01 "([Aa][Pp][Ii][_-]?[Kk][Ee][Yy]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss][Ww]([Oo][Rr])?[Dd]|[Tt][Oo][Kk][Ee][Nn])[\"']?[[:space:]]*[:=][[:space:]]*[\"'][^\"'\$<{]{6,}[\"']" \
    "Secret-like literal; read it from the environment instead" "$file" 0

  if [ $is_feature -eq 1 ]; then
    check ERROR ASSERT-05 '(^|[[:space:]])@only([[:space:]]|$)' "@only tag must not be committed" "$file" 0
    continue
  fi

  [ $is_code -eq 1 ] || continue

  # CODE-01: file naming.
  if ! printf '%s\n' "$base" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*(\.[a-z0-9]+)*\.(ts|tsx|js|mjs|cjs)$'; then
    report WARN "$file" 0 CODE-01 "File name is not kebab-case"
  fi
  if [ $is_step -eq 1 ]; then
    case "$base" in
      *.step.ts) ;;
      *) report WARN "$file" 0 CODE-01 "Step definition files should be named *.step.ts" ;;
    esac
  fi

  # ARCH-04: second test style.
  case "$base" in
    *.spec.ts|*.test.ts)
      report WARN "$file" 0 ARCH-04 "Plain spec/test file; BDD features must not gain a parallel test style"
      ;;
  esac

  # ASSERT-03: fixed sleeps.
  check ERROR ASSERT-03 '\.waitForTimeout[[:space:]]*\(' "Fixed sleep (waitForTimeout); use retrying assertions or a meaningful wait" "$file" 1
  check ERROR ASSERT-03 'new[[:space:]]+Promise[^;]*setTimeout' "Sleep promise; use retrying assertions or a meaningful wait" "$file" 1

  # ASSERT-02: snapshot assertions.
  check ERROR ASSERT-02 'expect(\.soft)?[[:space:]]*\([[:space:]]*await[^;]*\.(isVisible|isHidden|isEnabled|isDisabled|isChecked|isEditable|textContent|innerText|innerHTML|inputValue|getAttribute|count)[[:space:]]*\(' \
    "Snapshot assertion; use a retrying locator assertion (toBeVisible/toHaveText/...)" "$file" 1

  # ASSERT-05: focused or skipped tests.
  check ERROR ASSERT-05 '\.only[[:space:]]*\(' ".only must not be committed" "$file" 1
  check WARN ASSERT-05 "${nb}(test|it|describe)\\.(skip|fixme)[[:space:]]*\\(" "Skipped/fixme test; report the reason" "$file" 1

  # LOC-03: brittle selectors.
  check ERROR LOC-03 "(xpath=|locator[[:space:]]*\\([[:space:]]*[\"'\`][[:space:]]*\\(?//)" "XPath selector" "$file" 1
  check ERROR LOC-03 '(:nth-child|:nth-of-type|:has-text[[:space:]]*\(|\[class[[:space:]]*=)' \
    "Position, class-attribute or incidental-text CSS selector" "$file" 1
  check WARN LOC-03W "locator[[:space:]]*\\([[:space:]]*[\"'\`][^\"'\`]*\\.[A-Za-z_-][A-Za-z0-9_-]*\\.[A-Za-z_-]" \
    "Class-chained CSS selector; prefer role/label or a stable id" "$file" 1
  check WARN LOC-03W '\.(nth[[:space:]]*\([^)]*\)|first[[:space:]]*\([[:space:]]*\)|last[[:space:]]*\([[:space:]]*\))' \
    "Position-based locator; scope to a component or justify" "$file" 1

  # POM-06: swallowed failures.
  check ERROR POM-06 '\.catch[[:space:]]*\([[:space:]]*(async[[:space:]]*)?\(?[A-Za-z0-9_]*\)?[[:space:]]*=>[[:space:]]*(\{[[:space:]]*\}|undefined|null|void 0|false)[[:space:]]*\)' \
    "Swallowed failure (.catch with empty handler)" "$file" 1
  check ERROR POM-06 'catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*\}' "Empty catch block" "$file" 1

  if [ $is_step -eq 1 ]; then
    # STEP-01: steps must use the extended fixture test.
    check ERROR STEP-01 "import[[:space:]]*\\{[^}]*${nb}test([^A-Za-z0-9_\$][^}]*)?\\}[[:space:]]*from[[:space:]]*[\"'](@playwright/test|playwright-bdd)[\"']" \
      "Steps must import test from the extended fixture, not @playwright/test or playwright-bdd" "$file" 1
    # STEP-07: no selectors or raw page interaction in steps.
    check ERROR STEP-07 '\.(getBy(Role|Label|Text|TestId|Placeholder|AltText|Title)|locator|\$\$?)[[:space:]]*\(' \
      "Selector in step definition; move it to a page object" "$file" 1
    check ERROR STEP-07 "${nb}page\\.(goto|click|fill|type|press|check|uncheck|selectOption|hover|dblclick|keyboard|mouse|waitForSelector)" \
      "Raw page interaction in step definition; call a page-object method" "$file" 1
  fi

  if [ $is_page -eq 1 ]; then
    # POM-04: page objects must not create or import other page objects.
    check ERROR POM-04 'new[[:space:]]+[A-Za-z0-9_]*[Pp]age[[:space:]]*\(' "Page object instantiates another page object" "$file" 1
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      report WARN "$file" "${hit%%:*}" POM-04 "Page object imports another page object; keep cross-page flow in steps"
    done < <(grep -nE "from[[:space:]]*[\"'][^\"']*-page[\"']" "$file" 2>/dev/null | grep -vE "base-page[\"']")
  fi
done

printf 'blueprint-static-scan: %d file(s) scanned, %d error(s), %d warning(s)\n' "$scanned" "$errors" "$warnings"

if [ $errors -gt 0 ]; then
  exit 1
fi
if [ $strict -eq 1 ] && [ $warnings -gt 0 ]; then
  exit 1
fi
exit 0
