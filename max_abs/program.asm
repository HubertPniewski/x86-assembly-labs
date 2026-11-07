.686
.model flat

public _max_abs

.code

_max_abs PROC
	push ebp ; zapisanie zawartoœci EBP na stosie
	mov ebp, esp ; kopiowanie zawartoœci ESP do EBP

	mov edi, [ebp+8] ; adres tablicy do edi
	mov ecx, [ebp+12] ; iloœæ liczb w tablicy
	mov esi, 0 ; indeks w tablicy
	mov edx, 0 ; najwiêksza dot¹d znaleziona liczba

petla:
	mov eax, [edi+esi] ; za³adowanie liczby do eax
	bt eax, 31 ; sprawdzenie pierwszego bitu (bitu znaku) liczby
	jnc nieujemna ; jeœli bit znaku równy 0 (liczba nieujemna), to skok dalej, inaczej zamiana liczby na nieujemn¹
	neg eax ; zamiana liczby ujemnej na nieujemn¹

nieujemna:
	cmp eax, edx ; porównanie obecnej liczby (eax) z najwiêksz¹ dotychczas znalezion¹ (edx)
	jle bez_zmiany ; skok jeœli eax mniejsze lub równe edx

	mov edx, eax ; jeœli eax wiêksze, to zapisywane jest do edx (staje siê now¹ najwiêksz¹ liczb¹ bezwzglêdn¹)

bez_zmiany:
	add esi, 4 ; zwiêkszenie indesksu esi na kolejn¹ zmienn¹ int (4 bajty)
	loop petla ; kolejna iteracja pêtli

	mov eax, edx ; zapisanie wyniku w eax

	pop ebp
	ret
_max_abs ENDP
END