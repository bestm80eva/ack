#include <sys/types.h>
#include <sys/stat.h>

static	Xcvt();

int
stat(path, buf)
	char *path;
	struct stat *buf;
{
	char Xbuf[100];
	int retval;

	retval = _stat(path, Xbuf);
	Xcvt(Xbuf, (char *)buf);
	return retval;
}

int
lstat(path, buf)
	char *path;
	struct stat *buf;
{
	char Xbuf[100];
	int retval;

	retval = _lstat(path, Xbuf);
	Xcvt(Xbuf, (char *)buf);
	return retval;
}

int
fstat(fd, buf)
	int fd;
	struct stat *buf;
{
	char Xbuf[100];
	int retval;

	retval = _fstat(fd, Xbuf);
	Xcvt(Xbuf, (char *)buf);
	return retval;
}

static
Xcvt(buf, statbuf)
	char *buf, *statbuf;
{
	register char *s, *t;
	register int i;

	s = buf; t = statbuf;
	*t++ = *s++; *t++ = *s++;
	*t++ = 0; *t++ = 0;
	for (i = 14; i; i--) *t++ = *s++;
	*t++ = 0; *t++ = 0;
	for (i = 44; i; i--) *t++ = *s++;
}
