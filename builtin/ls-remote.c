#include "builtin.h"
#include "cache.h"
#include "transport.h"
#include "ref-filter.h"
#include "remote.h"

static const char * const ls_remote_usage[] = {
	N_("git ls-remote [--heads] [--tags] [--refs] [--upload-pack=<exec>]\n"
	   "                     [-q | --quiet] [--exit-code] [--get-url]\n"
	   "                     [--symref] [<repository> [<refs>...]]"),
	NULL
};

/*
 * Is there one among the list of patterns that match the tail part
 * of the path?
 */
static int tail_match(const char **pattern, const char *path)
{
	const char *p;
	char *pathbuf;

	if (!pattern)
		return 1; /* no restriction */

	pathbuf = xstrfmt("/%s", path);
	while ((p = *(pattern++)) != NULL) {
		if (!wildmatch(p, pathbuf, 0)) {
			free(pathbuf);
			return 1;
		}
	}
	free(pathbuf);
	return 0;
}

static int cmp_ref_versions(const void *_a, const void *_b)
{
	const struct ref *a = *(const struct ref **)_a;
	const struct ref *b = *(const struct ref **)_b;

	return versioncmp(a->name, b->name);
}

int _parse_opt_ref_sorting(const struct option *opt, const char *arg, int unset)
{
	if (strcmp(arg, "version:refname") && strcmp(arg, "v:refname"))
		die("unknown sort option '%s'", arg);
	return parse_opt_ref_sorting(opt, arg, unset);
}

int cmd_ls_remote(int argc, const char **argv, const char *prefix)
{
	const char *dest = NULL;
	unsigned flags = 0;
	int get_url = 0;
	int quiet = 0;
	int status = 0;
	int show_symref_target = 0;
	const char *uploadpack = NULL;
	const char **pattern = NULL;
	struct ref_array array;
	array.items = malloc(0);
	array.nr = 0;

	struct remote *remote;
	struct transport *transport;
	const struct ref *ref;
	const struct ref **refs = NULL;
	static struct ref_sorting *sorting = NULL, **sorting_tail = &sorting;
	int nr = 0;

	struct option options[] = {
		OPT__QUIET(&quiet, N_("do not print remote URL")),
		OPT_STRING(0, "upload-pack", &uploadpack, N_("exec"),
			   N_("path of git-upload-pack on the remote host")),
		{ OPTION_STRING, 0, "exec", &uploadpack, N_("exec"),
			   N_("path of git-upload-pack on the remote host"),
			   PARSE_OPT_HIDDEN },
		OPT_BIT('t', "tags", &flags, N_("limit to tags"), REF_TAGS),
		OPT_BIT('h', "heads", &flags, N_("limit to heads"), REF_HEADS),
		OPT_BIT(0, "refs", &flags, N_("do not show peeled tags"), REF_NORMAL),
		OPT_BOOL(0, "get-url", &get_url,
			 N_("take url.<base>.insteadOf into account")),
		OPT_CALLBACK(0 , "sort", sorting_tail, N_("key"),
			     N_("field name to sort on"), &_parse_opt_ref_sorting),
		OPT_SET_INT_F(0, "exit-code", &status,
			      N_("exit with exit code 2 if no matching refs are found"),
			      2, PARSE_OPT_NOCOMPLETE),
		OPT_BOOL(0, "symref", &show_symref_target,
			 N_("show underlying ref in addition to the object pointed by it")),
		OPT_END()
	};

	argc = parse_options(argc, argv, prefix, options, ls_remote_usage,
			     PARSE_OPT_STOP_AT_NON_OPTION);
	dest = argv[0];

	if (argc > 1) {
		int i;
		pattern = xcalloc(argc, sizeof(const char *));
		for (i = 1; i < argc; i++)
			pattern[i - 1] = xstrfmt("*/%s", argv[i]);
	}

	remote = remote_get(dest);
	if (!remote) {
		if (dest)
			die("bad repository '%s'", dest);
		die("No remote configured to list refs from.");
	}
	if (!remote->url_nr)
		die("remote %s has no configured URL", dest);

	if (get_url) {
		printf("%s\n", *remote->url);
		return 0;
	}

	transport = transport_get(remote, NULL);
	if (uploadpack != NULL)
		transport_set_option(transport, TRANS_OPT_UPLOADPACK, uploadpack);

	ref = transport_get_remote_refs(transport);
	if (transport_disconnect(transport))
		return 1;

	if (!dest && !quiet)
		fprintf(stderr, "From %s\n", *remote->url);
	for ( ; ref; ref = ref->next) {
		if (!check_ref_type(ref, flags))
			continue;
		if (!tail_match(pattern, ref->name))
			continue;

		//REALLOC_ARRAY(refs, nr + 1);
		//refs[nr++] = ref;

        /*
		struct ref_array_item item = {
			//.refname = ref->name,
			.symref = ref->symref,
			.objectname = ref->old_oid
		};
		*/

        struct ref_array_item *item;
        FLEX_ALLOC_MEM(item, refname, ref->name, strlen(ref->name));
        item->symref = ref->symref;
        item->objectname = ref->old_oid;

        //strcpy(item.refname, s);
        //size_t len = strlen(ref->name);
        //item.refname = malloc(0);
        //memcpy(item.refname, ref->name, len);
		//printf("array.nr: %s\n", item.refname);

        //strncpy(item.refname, "hej", 2);
        //item.refname = (char *)malloc(strlen(ref->name)+1);
		//strcpy(item.refname, "hej");

		//item.symref = ref->symref;
		//item.objectname = ref->old_oid;
		REALLOC_ARRAY(array.items, array.nr + 1);
		array.items[array.nr] = item;
		array.nr = array.nr + 1;
	}

	if (sorting) {
		//QSORT(refs, nr, cmp_ref_versions);
    	ref_array_sort(sorting, &array);
		//QSORT_S(refs, nr, cmp_ref_versions, sorting);
	}

	for (int i = 0; i < array.nr; i++) {
		const struct ref_array_item *ref = array.items[i];
		if (show_symref_target && ref->symref)
			printf("ref: %s\t%s\n", ref->symref, ref->refname);
		printf("%s\t%s\n", oid_to_hex(&ref->objectname), ref->refname);
		status = 0; /* we found something */
	}
	return status;
}
