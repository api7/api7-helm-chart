{{/*
Refuse api.corsAllowedOrigins entries cp-api would refuse at startup.
Context: the list itself. Emits nothing.
*/}}
{{- define "aisix-cp.validateCorsOrigins" -}}
{{- /* cp-api refuses these at startup, which an operator meets as a
       CrashLoopBackOff and a log line rather than as a failed
       upgrade. Fail the render instead, where the message lands
       next to the value that caused it.

       These rules are cors.ValidateOrigin's, and they are only
       worth having if they are the SAME rules: a shape this
       template waves through and cp-api then refuses turns the
       crash loop it exists to prevent back on. Compared
       lowercased, because that is what cp-api normalizes to
       before deciding. */ -}}
{{- range . }}
{{- $entry := lower (trim .) }}
{{- if eq $entry "*" }}
{{- fail "api.corsAllowedOrigins must name explicit origins, not \"*\": it is a blanket grant, and cp-api refuses to start with one." }}
{{- end }}
{{- if hasPrefix "https://*" $entry }}
{{- /* A wildcard suffix has to begin at a label separator, or it
       also matches a longer label: https://*api7ai.vercel.app
       would admit evilapi7ai.vercel.app. */ -}}
{{- $suffix := trimPrefix "https://*" $entry }}
{{- if not (or (hasPrefix "-" $suffix) (hasPrefix "." $suffix)) }}
{{- fail (printf "api.corsAllowedOrigins entry %q: a wildcard suffix must start with \"-\" or \".\" so it cannot match a longer label." .) }}
{{- end }}
{{- if or (not (regexMatch "^[a-z0-9._-]+$" $suffix)) (hasSuffix "." $suffix) }}
{{- fail (printf "api.corsAllowedOrigins entry %q: a wildcard suffix must be a bare host suffix of ASCII letters, digits, dot, hyphen and underscore — a path, query, fragment, userinfo, port, trailing dot or non-ASCII name never matches a browser's Origin." .) }}
{{- end }}
{{- /* Every leading separator goes, not one of each: cp-api
       trims the whole run (`strings.TrimLeft(suffix, "-.")`)
       before counting labels, so `https://*..a.b` counted three
       labels here and two there — rendered, then refused at
       startup. */ -}}
{{- $body := regexReplaceAll "^[-.]+" $suffix "" }}
{{- if lt (len (splitList "." $body)) 3 }}
{{- fail (printf "api.corsAllowedOrigins entry %q: a wildcard suffix must name at least three labels, or it covers a whole public suffix (https://*.vercel.app would admit every project on that host)." .) }}
{{- end }}
{{- else }}
{{- /* Exact origin. https is required, with the same loopback
       exception cp-api makes so a port-forwarded dev console can
       be listed. */ -}}
{{- $loopback := or (hasPrefix "http://localhost:" $entry) (hasPrefix "http://127.0.0.1:" $entry) (hasPrefix "http://[::1]:" $entry) (eq $entry "http://localhost") (eq $entry "http://127.0.0.1") (eq $entry "http://[::1]") }}
{{- if not (or (hasPrefix "https://" $entry) $loopback) }}
{{- fail (printf "api.corsAllowedOrigins entry %q must use https:// (loopback may use http)." .) }}
{{- end }}
{{- /* A positive shape check, not a blacklist of bad characters.
       Blacklisting let `https://host:abc`, `https://`, an
       unbalanced `[::1` and a percent-escape through — each of
       which cp-api then refuses at startup, which is the crash
       loop this whole block exists to convert into a message.

       Underscores and edge hyphens are admitted because a browser
       admits them: refusing one here blocked an upgrade over a
       value cp-api accepts. */ -}}
{{- $rest := trimPrefix "http://" (trimPrefix "https://" $entry) }}
{{- if not (regexMatch "^(\\[[0-9a-f:]+\\]|[a-z0-9_.-]+)(:[0-9]{1,5})?$" $rest) }}
{{- fail (printf "api.corsAllowedOrigins entry %q must be a bare origin like https://host[:port] — a path, query, fragment, userinfo, trailing dot, empty or non-numeric port, or a non-ASCII host (write its punycode form) never matches a browser's Origin header." .) }}
{{- end }}
{{- $hostOnly := regexReplaceAll ":[0-9]+$" $rest "" }}
{{- if hasSuffix "." $hostOnly }}
{{- fail (printf "api.corsAllowedOrigins entry %q must be a bare origin like https://host[:port] — a trailing dot never matches a browser's Origin header." .) }}
{{- end }}
{{- if hasPrefix "[" $hostOnly }}
{{- /* An IPv6 address has many spellings and a browser sends
       exactly one: the URL standard's serializer. This block
       reproduces it, so the render refuses precisely the entries
       cp-api refuses at startup.

       A zero hextet is NOT simply forbidden. The serializer
       compresses the first-longest run of at least TWO zero
       hextets and writes a lone one out, so `1:0:2:3:4:5:6:7` and
       `1::1:0` are the canonical spellings of their addresses —
       and the rule that refused every written-out `0` rejected
       1409 addresses a browser sends exactly as typed. */ -}}
{{- $inner := trimSuffix "]" (trimPrefix "[" $hostOnly) }}
{{- if regexMatch "(^|:)0[0-9a-f]" $inner }}
{{- fail (printf "api.corsAllowedOrigins entry %q: an IPv6 origin must be written the way a browser sends it — drop the leading zeros from each hextet." .) }}
{{- end }}
{{- /* Counting groups alone is not enough to tell an address from
       a typo: `without … ""` drops the empty components a doubled
       or misplaced colon produces, so `1::2::3`, `:::`, `1:::2`,
       `12345::1`, `1:2:3:4:5:6:7:8:`, `:1:2:3:4:5:6:7:8`, `1::2:`
       and `:1::2` all reached the count as if well formed, and
       cp-api refused every one of them at startup.

       The three rules below refuse a spelling that is not an
       address at all: more than one `::`, a group that is not one
       to four hex digits, and a colon on either end that is not
       part of the `::`.

       They do NOT establish that what survives is a spelling
       cp-api takes. That test is `ip.String() == host` — the
       canonical form, which is stricter than parsing — and only
       the shared case list decides whether the two agree. Add a
       case to internal/cpapi/cors/testdata/origin-cases.txt; the
       parity step in .github/workflows/ci-helm.yml runs the whole
       list through this template and through cp-api and fails on
       any entry they answer differently. */ -}}
{{- $groups := without (splitList ":" $inner) "" }}
{{- if or (contains ":::" $inner) (gt (len (splitList "::" $inner)) 2) }}
{{- fail (printf "api.corsAllowedOrigins entry %q is not an IPv6 address — `::` may appear once, and stands for the omitted groups." .) }}
{{- end }}
{{- range $groups }}
{{- if not (regexMatch "^[0-9a-f]{1,4}$" .) }}
{{- fail (printf "api.corsAllowedOrigins entry %q is not an IPv6 address — %q is not a group of one to four hex digits." $entry .) }}
{{- end }}
{{- end }}
{{- /* A colon on either end belongs to a `::`. On its own it is an
       empty group, which `$groups` has already dropped. */ -}}
{{- if or (and (hasPrefix ":" $inner) (not (hasPrefix "::" $inner))) (and (hasSuffix ":" $inner) (not (hasSuffix "::" $inner))) }}
{{- fail (printf "api.corsAllowedOrigins entry %q is not an IPv6 address — a leading or trailing colon has no group in front of it." .) }}
{{- end }}
{{- /* `::` stands for at least one omitted group, so a spelling
       that also writes all eight is not an address at all. */ -}}
{{- if contains "::" $inner }}
{{- if gt (len $groups) 6 }}
{{- fail (printf "api.corsAllowedOrigins entry %q is not an IPv6 address — `::` stands for at least two omitted groups — a single zero group is written out." .) }}
{{- end }}
{{- else if ne (len $groups) 8 }}
{{- fail (printf "api.corsAllowedOrigins entry %q is not an IPv6 address — it needs eight groups, or `::` where they are omitted." .) }}
{{- end }}
{{- /* The address is well formed here, so expand it to its eight
       hextets and re-serialize it the way the URL standard does:
       the first-longest run of two or more zero hextets becomes
       `::`, everything else is written out. Any spelling other
       than that one is an entry no Origin header can equal.

       An IPv4-mapped address keeps its hex spelling through this,
       which is what a browser sends: `[::ffff:c0a8:1]`, never
       `[::ffff:192.168.0.1]`. */ -}}
{{- $halves := splitList "::" $inner }}
{{- $lead := without (splitList ":" (index $halves 0)) "" }}
{{- $tail := list }}
{{- if contains "::" $inner }}
{{- $tail = without (splitList ":" (index $halves 1)) "" }}
{{- end }}
{{- $hextets := $lead }}
{{- range until (int (sub 8 (add (len $lead) (len $tail)))) }}
{{- $hextets = append $hextets "0" }}
{{- end }}
{{- range $tail }}
{{- $hextets = append $hextets . }}
{{- end }}
{{- /* First-longest run of two or more zero hextets. */ -}}
{{- $compress := -1 }}
{{- $best := 1 }}
{{- $run := 0 }}
{{- $runStart := 0 }}
{{- range $i, $h := $hextets }}
{{- if eq $h "0" }}
{{- if eq $run 0 }}{{- $runStart = $i }}{{- end }}
{{- $run = add1 $run }}
{{- if gt $run $best }}{{- $best = $run }}{{- $compress = $runStart }}{{- end }}
{{- else }}
{{- $run = 0 }}
{{- end }}
{{- end }}
{{- $canonical := "" }}
{{- $skipZeros := false }}
{{- range $i, $h := $hextets }}
{{- if and $skipZeros (eq $h "0") }}
{{- else }}
{{- $skipZeros = false }}
{{- if eq $i $compress }}
{{- if eq $i 0 }}
{{- $canonical = printf "%s::" $canonical }}
{{- else }}
{{- $canonical = printf "%s:" $canonical }}
{{- end }}
{{- $skipZeros = true }}
{{- else }}
{{- $canonical = printf "%s%s" $canonical $h }}
{{- if ne $i 7 }}{{- $canonical = printf "%s:" $canonical }}{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if ne $canonical $inner }}
{{- fail (printf "api.corsAllowedOrigins entry %q: an IPv6 origin must be written the way a browser sends it, which for this address is `[%s]`." $entry $canonical) }}
{{- end }}
{{- else }}
{{- /* A browser re-reads a host whose last label is numeric as an
       IPv4 address and rewrites it: `https://2130706433` is sent as
       `https://127.0.0.1`. Such an entry can only match if it
       already is a dotted quad. */ -}}
{{- $lastLabel := last (splitList "." $hostOnly) }}
{{- if regexMatch "^(0[xX][0-9a-fA-F]*|[0-9]+)$" $lastLabel }}
{{- if not (regexMatch "^([1-9]?[0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\\.([1-9]?[0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$" $hostOnly) }}
{{- fail (printf "api.corsAllowedOrigins entry %q: a host whose last label is numeric is read as an IPv4 address and rewritten — write the dotted-quad form a browser sends." .) }}
{{- end }}
{{- end }}
{{- end }}
{{- /* A port has one spelling. Five digits is a shape, not a port:
       a browser refuses a URL above 65535, strips leading zeros,
       and omits the scheme's default port when it serializes an
       origin — so `:0080` and `:443` on https parse fine here and
       then match nothing. Port 0 is legal and simply dead. */ -}}
{{- $port := regexFind ":[0-9]+$" $rest }}
{{- if $port }}
{{- $digits := trimPrefix ":" $port }}
{{- $n := atoi $digits }}
{{- if gt $n 65535 }}
{{- fail (printf "api.corsAllowedOrigins entry %q: %s is not a port — a browser refuses a URL above 65535." . $port) }}
{{- end }}
{{- if ne (printf "%d" $n) $digits }}
{{- fail (printf "api.corsAllowedOrigins entry %q: a browser writes the port as %q, not %q." . (printf "%d" $n) $digits) }}
{{- end }}
{{- if or (and (hasPrefix "https://" $entry) (eq $n 443)) (and (hasPrefix "http://" $entry) (eq $n 80)) }}
{{- fail (printf "api.corsAllowedOrigins entry %q: a browser omits the scheme's default port — drop the %q." . $port) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
