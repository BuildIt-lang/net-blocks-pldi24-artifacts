#ifndef UTILS_H
#define UTILS_H
#include <sys/time.h>
#include <time.h>

static long long get_time_in_us(void) {
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return tv.tv_sec * 1000000 + tv.tv_usec;
}


static long long get_time_in_ns(void) {
	struct timespec tv;
	clock_gettime(CLOCK_MONOTONIC, &tv);
	return tv.tv_sec * 1000000000 + tv.tv_nsec;
}

static void sort_time_array(long long *time_log, int TOTAL_REQUESTS) {
	int i, j;
	if (time_log == NULL)
		return;
	for (i = 0; i < TOTAL_REQUESTS; i++) {
		for (j = i+1; j < TOTAL_REQUESTS; j++) {
			if (time_log[i] > time_log[j]) {
				long long temp = time_log[i];
				time_log[i] = time_log[j];
				time_log[j] = temp;
			}
		}
	}
}
#endif
