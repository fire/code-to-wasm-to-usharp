#include <stdio.h>
#include "cst_lexicon.h"

extern cst_lexicon cmu_lex;
void *cmu_lex_init();

char *get_buffer() {
	static char buffer[1024];
	return buffer;
}
void init() {
	cmu_lex_init();
}
void cmu_lex_lookup(const char *word) {
	cst_val *p = lex_lookup(&cmu_lex, word, NULL, NULL);
	val_print(stdout, p);
	delete_val(p);
	fflush(stdout);
}