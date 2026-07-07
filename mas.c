#include "mas.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

static int hex_val(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return 0;
}

static char *decode(const char *s) {
    size_t len = strlen(s);
    char *out = malloc(len + 1);
    if (!out) return NULL;
    size_t j = 0;
    for (size_t i = 0; i < len; i++) {
        if (s[i] == '%' && i + 2 < len &&
            isxdigit((unsigned char)s[i + 1]) &&
            isxdigit((unsigned char)s[i + 2])) {
            out[j++] = (hex_val(s[i + 1]) << 4) | hex_val(s[i + 2]);
            i += 2;
        } else {
            out[j++] = s[i];
        }
    }
    out[j] = '\0';
    return out;
}

static int is_unreserved(char c) {
    return isalnum((unsigned char)c) || c == '-' || c == '_' || c == '.'
        || c == '~';
}

static char *encode(const char *s) {
    size_t len = strlen(s);
    char *out = malloc(len * 3 + 1);
    if (!out) return NULL;
    size_t j = 0;
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char)s[i];
        if (is_unreserved(c)) {
            out[j++] = c;
        } else {
            j += sprintf(out + j, "%%%02X", c);
        }
    }
    out[j] = '\0';
    return out;
}

int mas_decode(const char *uri, mas_params_t *out) {
    out->m = NULL;
    out->k = NULL;

    const char *frag = strchr(uri, '#');
    if (!frag || !*(++frag)) return -1;

    char *copy = strdup(frag);
    if (!copy) return -1;

    int found_m = 0;
    char *part = copy;
    while (part) {
        char *next = strchr(part, '&');
        if (next) *next++ = '\0';

        char *eq = strchr(part, '=');
        char *key = part;
        char *val = eq ? eq + 1 : "";
        if (eq) *eq = '\0';

        char *dk = decode(key);
        if (!dk) { free(copy); return -1; }
        char *dv = decode(val);
        if (!dv) { free(dk); free(copy); return -1; }

        if (strcmp(dk, "m") == 0) {
            if (*dv == '\0') { free(dk); free(dv); free(copy); return -1; }
            out->m = strdup(dv);
            found_m = 1;
        } else if (strcmp(dk, "k") == 0 && *dv) {
            out->k = strdup(dv);
        }

        free(dk);
        free(dv);
        part = next;
    }

    free(copy);
    return found_m ? 0 : -1;
}

void mas_params_free(mas_params_t *p) {
    if (p) {
        free(p->m);
        free(p->k);
        p->m = NULL;
        p->k = NULL;
    }
}

char *mas_encode(const char *m, const char *k) {
    if (!m || !*m) return NULL;

    char *em = encode(m);
    if (!em) return NULL;

    size_t len = 1 + 2 + strlen(em);
    if (k && *k) {
        char *ek = encode(k);
        if (!ek) { free(em); return NULL; }
        len += 2 + strlen(ek);
        char *out = malloc(len + 1);
        if (!out) { free(em); free(ek); return NULL; }
        sprintf(out, "#m=%s&k=%s", em, ek);
        free(em);
        free(ek);
        return out;
    }

    char *out = malloc(len + 1);
    if (!out) { free(em); return NULL; }
    sprintf(out, "#m=%s", em);
    free(em);
    return out;
}

void mas_string_free(char *s) { free(s); }
