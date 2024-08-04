#!/bin/sh
# SPDX-License-Identifier: 0BSD
################################################################################
## @file
## @date 31.12.2023
## @license
## BSD Zero Clause License
##
## Copyright (c) 2023 by the spm authors
##
## Permission to use, copy, modify, and/or distribute this software for any
## purpose with or without fee is hereby granted.
##
## THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
## REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
## AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
## INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
## LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
## OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
## PERFORMANCE OF THIS SOFTWARE.
##
## @brief
## This shell script provides some wrappers around `curl` to make it a bit
## easier to deal with HTTP requests and responses.
##
## @see
## HTTP Semantics: https://www.rfc-editor.org/rfc/rfc9110
## HTTP/1.1: https://www.rfc-editor.org/rfc/rfc9112
## ABNF:
##  https://www.rfc-editor.org/rfc/rfc5234
##  https://www.rfc-editor.org/rfc/rfc7405
################################################################################
# Exit script on error
set -e
# Exit on variable not set
set -u
# Set locale to C/POSIX
LC_ALL=C
export LC_ALL
################################################################################
## List of status code
##
## @see
## 1xx: https://www.rfc-editor.org/rfc/rfc9110#name-informational-1xx
## 2xx: https://www.rfc-editor.org/rfc/rfc9110#name-successful-2xx
## 3xx: https://www.rfc-editor.org/rfc/rfc9110#name-redirection-3xx
## 4xx: https://www.rfc-editor.org/rfc/rfc9110#name-client-error-4xx
## 5xx: https://www.rfc-editor.org/rfc/rfc9110#name-server-error-5xx
## 428, 429, 431, 511: https://www.rfc-editor.org/rfc/rfc6585
readonly HTTP_100_CONTINUE=100; export HTTP_100_CONTINUE
readonly HTTP_101_SWITCHING_PROTOCOLS=101; export HTTP_101_SWITCHING_PROTOCOLS
readonly HTTP_200_OK=200; export HTTP_200_OK
readonly HTTP_201_CREATED=201; export HTTP_201_CREATED
readonly HTTP_202_ACCEPTED=202; export HTTP_202_ACCEPTED
readonly HTTP_203_NON_AUTHORITATIVE_INFORMATION=203; export HTTP_203_NON_AUTHORITATIVE_INFORMATION
readonly HTTP_204_NO_CONTENT=204; export HTTP_204_NO_CONTENT
readonly HTTP_205_RESET_CONTENT=205; export HTTP_205_RESET_CONTENT
readonly HTTP_206_PARTIAL_CONTENT=206; export HTTP_206_PARTIAL_CONTENT
readonly HTTP_300_MULTIPLE_CHOICES=300; export HTTP_300_MULTIPLE_CHOICES
readonly HTTP_301_MOVED_PERMANENTLY=301; export HTTP_301_MOVED_PERMANENTLY
readonly HTTP_302_FOUND=302; export HTTP_302_FOUND
readonly HTTP_303_SEE_OTHER=303; export HTTP_303_SEE_OTHER
readonly HTTP_304_NOT_MODIFIED=304; export HTTP_304_NOT_MODIFIED
readonly HTTP_305_USE_PROXY=305; export HTTP_305_USE_PROXY
readonly HTTP_307_TEMPORARY_REDIRECT=307; export HTTP_307_TEMPORARY_REDIRECT
readonly HTTP_308_PERMANENT_REDIRECT=308; export HTTP_308_PERMANENT_REDIRECT
readonly HTTP_400_BAD_REQUEST=400; export HTTP_400_BAD_REQUEST
readonly HTTP_401_UNAUTHORIZED=401; export HTTP_401_UNAUTHORIZED
readonly HTTP_403_FORBIDDEN=403; export HTTP_403_FORBIDDEN
readonly HTTP_404_NOT_FOUND=404; export HTTP_404_NOT_FOUND
readonly HTTP_405_METHOD_NOT_ALLOWED=405; export HTTP_405_METHOD_NOT_ALLOWED
readonly HTTP_406_NOT_ACCEPTABLE=406; export HTTP_406_NOT_ACCEPTABLE
readonly HTTP_407_PROXY_AUTHENTICATION_REQUIRED=407; export HTTP_407_PROXY_AUTHENTICATION_REQUIRED
readonly HTTP_408_REQUEST_TIMEOUT=408; export HTTP_408_REQUEST_TIMEOUT
readonly HTTP_409_CONFLICT=409; export HTTP_409_CONFLICT
readonly HTTP_410_GONE=410; export HTTP_410_GONE
readonly HTTP_411_LENGTH_REQUIRED=411; export HTTP_411_LENGTH_REQUIRED
readonly HTTP_412_PRECONDITION_FAILED=412; export HTTP_412_PRECONDITION_FAILED
readonly HTTP_413_CONTENT_TOO_LARGE=413; export HTTP_413_CONTENT_TOO_LARGE
readonly HTTP_414_URI_TOO_LONG=414; export HTTP_414_URI_TOO_LONG
readonly HTTP_415_UNSUPPORTED_MEDIA_TYPE=415; export HTTP_415_UNSUPPORTED_MEDIA_TYPE
readonly HTTP_416_RANGE_NOT_SATISFIABLE=416; export HTTP_416_RANGE_NOT_SATISFIABLE
readonly HTTP_417_EXPECTATION_FAILED=417; export HTTP_417_EXPECTATION_FAILED
readonly HTTP_418_IM_A_TEAPOT=418; export HTTP_418_IM_A_TEAPOT
readonly HTTP_421_MISDIRECTED_REQUEST=421; export HTTP_421_MISDIRECTED_REQUEST
readonly HTTP_422_UNPROCESSABLE_CONTENT=422; export HTTP_422_UNPROCESSABLE_CONTENT
readonly HTTP_426_UPGRADE_REQUIRED=426; export HTTP_426_UPGRADE_REQUIRED
readonly HTTP_428_PRECONDITION_REQUIRED=428; export HTTP_428_PRECONDITION_REQUIRED
readonly HTTP_429_TOO_MANY_REQUESTS=429; export HTTP_429_TOO_MANY_REQUESTS
readonly HTTP_431_REQUEST_HEADER_FIELDS_TOO_LARGE=431; export HTTP_431_REQUEST_HEADER_FIELDS_TOO_LARGE
readonly HTTP_500_INTERNAL_SERVER_ERROR=500; export HTTP_500_INTERNAL_SERVER_ERROR
readonly HTTP_501_NOT_IMPLEMENTED=501; export HTTP_501_NOT_IMPLEMENTED
readonly HTTP_502_BAD_GATEWAY=502; export HTTP_502_BAD_GATEWAY
readonly HTTP_503_SERVICE_UNAVAILABLE=503; export HTTP_503_SERVICE_UNAVAILABLE
readonly HTTP_504_GATEWAY_TIMEOUT=504; export HTTP_504_GATEWAY_TIMEOUT
readonly HTTP_505_HTTP_VERSION_NOT_SUPPORTED=505; export HTTP_505_HTTP_VERSION_NOT_SUPPORTED
readonly HTTP_511_NETWORK_AUTHENTICATION_REQUIRED=511; export HTTP_511_NETWORK_AUTHENTICATION_REQUIRED
################################################################################
## http_get() <url> [<...>]
##
## Send a `GET` request to `<url>` and return the response.
##
## @args
## $1 <url> [REQ]: URL to the desired resource.
## $@ <...> [OPT]: Any additional `curl` parameters needed.
http_get() {
  _url="$1"
  shift 1
  curl \
    --request 'GET' \
    --url "$_url" \
    --location \
    --include \
    --silent \
    "$@"
}
################################################################################
## http_get_binary() <url> [<...>]
##
## Send a `GET` request to `<url>` with a `Accept: application/octet-stream`
## header and return the response.
##
## @args
## $1 <url> [REQ]: URL to the desired binary.
## $@ <...> [OPT]: Any additional `curl` parameters needed.
http_get_binary() {
  curl \
    --request 'GET' \
    --url "$1" \
    --header 'Accept: application/octet-stream' \
    --location \
    --include \
    --silent \
    "$@"
}
################################################################################
## http_response_get_body() <response>
##
## Parse a `<response>` received by a `http_get*()` function and return its
## body.
##
## @args
## $1 <response> [REQ]: Response message.
http_response_get_body() {
  printf '%s' "$1" | sed -e '1,/^[[:space:]]*$/d'
}
################################################################################
## http_response_get_status_code() <response>
##
## Parse a `<response>` received by a `http_get*()` function and return its
## status code.
##
## @args
## $1 <response> [REQ]: Response message.
##
## @detail
## status-line  = HTTP-version SP status-code SP [ reason-phrase ]
## status-code  = 3DIGIT
## HTTP-version = HTTP-name "/" DIGIT "." DIGIT
## HTTP-name    = %s"HTTP"
## DIGIT        = %x30-39
## SP           = %x20
##
## - The HTTP version is not needed so it's skipped until a space is found.
## - The status-line is the first line of the response so `sed` is made to quit
##   with `;q` immediately after processing it.
##
## @see
## status-line, status-code:
##  https://www.rfc-editor.org/rfc/rfc9112#name-status-line
## HTTP-version, HTTP-name:
##  https://www.rfc-editor.org/rfc/rfc9112#name-http-version
## DIGIT, SP: https://www.rfc-editor.org/rfc/rfc5234#appendix-B.1
## %s: https://www.rfc-editor.org/rfc/rfc7405#section-2.1
http_response_get_status_code() {
  printf '%s' "$1" | sed -ne 's/^HTTP\/.\{1,\}\x20\([0-9]\{3\}\).*$/\1/p;q'
}
################################################################################
## http_response_get_field_value() <response> <field-name>
##
## Parse a `<response>` received by a `http_get*()` function and return the
## value of the `<field-name>` found in the header.
##
## @args
## $1 <response>   [REQ]: Response message.
## $2 <field-name> [REQ]: Name of the field containing the wanted value.
##
## @detail
## field-line    = field-name ":" OWS field-value OWS
## field-value   = *field-content
## field-content = field-vchar
##                 [ 1*( SP / HTAB / field-vchar ) field-vchar ]
## field-vchar   = VCHAR / obs-text
## VCHAR         = %x21-7E
## OWS           = *( SP / HTAB )
## SP            = %x20
## HTAB          = %x09
##
## - There is no check that `<field-name>` is a valid `field-name`.
## - Lines containing `obs-text` won't match.
##
## @see
## field-line: https://www.rfc-editor.org/rfc/rfc9112#name-field-syntax
## field-name: https://www.rfc-editor.org/rfc/rfc9110#name-field-names
## token: https://www.rfc-editor.org/rfc/rfc9110#name-tokens
## field-value, field-content, field-vchar, obs-text:
##             https://www.rfc-editor.org/rfc/rfc9110#name-field-values
## OWS: https://www.rfc-editor.org/rfc/rfc9110#section-5.6.3
## HTAB, SP, VCHAR: https://www.rfc-editor.org/rfc/rfc5234#appendix-B.1
http_response_get_field_value()  {
  printf '%s' "$1" | sed -ne \
    "s/^$2:[[:blank:]]*\([[:graph:][:blank:]]*\)[[:blank:]]*$/\1/p"
}
