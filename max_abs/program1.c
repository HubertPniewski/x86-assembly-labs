#include <stdio.h>
extern unsigned int max_abs(const int tabl[], unsigned int n);

int main()
{
	int tablica[] = { -4, 0, -53, 9, 12, -9, -43, 0, 0, -1, -37 };

	unsigned int wynik = max_abs(tablica, 11);
	printf("\nnajwieksza: %d", wynik);

	return 0;
}
