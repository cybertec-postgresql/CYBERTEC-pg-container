#include <sys/types.h>

int setuid(uid_t euid)
{
	return 0;
}

int seteuid(uid_t euid)
{
	return 0;
}

int initgroups(const char *user, gid_t group)
{
	return 0;
}
