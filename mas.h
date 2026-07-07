#ifndef MAS_H
#define MAS_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    char *m;
    char *k;
} mas_params_t;

int  mas_decode(const char *uri, mas_params_t *out);
void mas_params_free(mas_params_t *p);
char *mas_encode(const char *m, const char *k);
void mas_string_free(char *s);

#ifdef __cplusplus
}
#endif

#endif
