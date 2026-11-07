.686
.model flat 
extern __write : PROC
extern __read : PROC
extern _ExitProcess@4 : PROC
public _main

.data
; dla wyswietl_EAX
znaki	db 12 dup (?)	

; dla wczytaj_do_EAX
obszar  db 12 dup (?) ; tablica do przechowywania wprowadzonych znaków
dziesiec  dd 10 ; mnożnik 

; dla wyswietl_EAX_hex
dekoder db '0123456789ABCDEF' 

; dla komunikatu
za_duza db 'Zbyt duza liczba (musi byc mniejsza od 60000)'
rozmiar = $ - za_duza

; dla pitagorasa
pierwsza db 'Wpisz dlugosc pierwszej przyprostokatnej',10
rozmiar1 = $ - pierwsza
druga db 'Wpisz dlugosc drugiej przyprostokatnej',10
rozmiar2 = $ - druga
suma_kwadratow dd ?

.code 


; wyświetl zawartość rejestru EAX w konsoli
wyswietl_EAX PROC
	pusha
 
	mov  esi, 10  ; indeks w tablicy 'znaki' 
	mov  ebx, 10  ; dzielnik równy 10 
 
konwersja: 
	mov  edx, 0			; zerowanie starszej części dzielnej 
	div  ebx				; dzielenie przez 10, reszta w EDX, iloraz w EAX 
	add  dl, 30H			; zamiana reszty z dzielenia na kod ASCII 
	mov  znaki [esi], dl	; zapisanie cyfry w kodzie ASCII 
	dec  esi				; zmniejszenie indeksu 
	cmp  eax, 0			; sprawdzenie czy iloraz = 0 
	jne  konwersja			; skok, gdy iloraz niezerowy 
 
; wypełnienie pozostałych bajtów spacjami i wpisanie znaków nowego wiersza 
wypeln: 
	or	esi, esi 
	jz wyswietl					; skok, gdy ESI = 0 
	mov byte PTR znaki [esi], 20H	; kod spacji 
	dec esi						; zmniejszenie indeksu 
	jmp wypeln 
  
wyswietl: 
	mov  byte PTR znaki [0], 0AH	; kod nowego wiersza 
	mov  byte PTR znaki [11], 0AH	; kod nowego wiersza 
 
; wyświetlenie cyfr na ekranie 
	push  dword PTR 12				; liczba wyświetlanych znaków 
	push  dword PTR OFFSET znaki	; adres wyśw. obszaru 
	push  dword PTR 1				; numer urządzenia (ekran ma numer 1) 
	call  __write					; wyświetlenie liczby na ekranie 
	add  esp, 12					; usunięcie parametrów ze stosu

	popa
	ret
wyswietl_EAX ENDP



; wczytaj do EAX podprogram
wczytaj_do_EAX PROC
; odłożenie rejestrów ogólnego przeznaczenia wykorzystywanych przez podprogram na stos (poza eax i esp)
	push ebx
	push ecx
	 
; wczytywanie liczby dziesiętnej z klawiatury – po wprowadzeniu cyfr należy nacisnąć klawisz Enter 
; liczba po konwersji na postać binarną zostaje wpisana do rejestru EAX 
	push dword PTR 12 ; max ilość znaków wczytywanej liczby 
	push dword PTR OFFSET obszar ; adres obszaru pamięci 
	push dword PTR 0; numer urządzenia (0 dla klawiatury) 
	call __read ; odczytywanie znaków z klawiatury (dwa znaki podkreślenia przed read) 
	add esp, 12 ; usunięcie parametrów ze stosu 
 
 
; bieżąca wartość przekształcanej liczby przechowywana jest w rejestrze EAX, przyjmujemy 0 jako wartość początkową 
	mov eax, 0   
	mov ebx, OFFSET obszar ; adres obszaru ze znakami 
 
pobieraj_znaki: 
	mov  cl, [ebx]	; pobranie kolejnej cyfry w kodzie ASCII 
	inc  ebx		; zwiększenie indeksu 
	cmp  cl,10		; sprawdzenie czy naciśnięto Enter 
	je  byl_enter	; skok, gdy naciśnięto Enter 
	sub  cl, 30H	; zamiana kodu ASCII na wartość cyfry 
	movzx ecx, cl	; przechowanie wartości cyfry w rejestrze ECX 
 
 
	mul  dword PTR dziesiec	; mnożenie wcześniej obliczonej wartości razy 10 
	add  eax, ecx			; dodanie ostatnio odczytanej cyfry 
	jmp  pobieraj_znaki		; skok na początek pętli 
 
byl_enter: 
; wartość binarna wprowadzonej liczby znajduje się teraz w rejestrze EAX 

; zdjęcie rejestrów ebx i ecx ze stosu i zakończenie podprogramu
	pop ecx
	pop ebx
	ret	; return
wczytaj_do_EAX ENDP


; wyświetlanie zawartości rejestru EAX w postaci liczby szesnastkowej 
wyswietl_EAX_hex PROC 
	pusha  ; przechowanie rejestrów  
	sub  esp, 12 ; rezerwacja 12 bajtów na stosie (poprzez zmniejszenie rejestru ESP) przeznaczonych na tymczasowe przechowanie cyfr szesnastkowych wyświetlanej liczby 
	mov  edi, esp ; adres zarezerwowanego obszaru pamięci 
 
; przygotowanie konwersji            
	mov  ecx, 8 ; liczba obiegów pętli konwersji 
	mov  esi, 1 ; indeks początkowy używany przy zapisie cyfr 
 
; pętla konwersji 
ptl3hex:    
	rol  eax, 4 ; przesunięcie cykliczne (obrót) rejestru EAX o 4 bity w lewo w szczególności, w pierwszym obiegu pętli bity nr 31 - 28 rejestru EAX zostaną przesunięte na pozycje 3 - 0   
 
; wyodrębnienie 4 najmłodszych bitów i odczytanie z tablicy 'dekoder' odpowiadającej im cyfry w zapisie szesnastkowym 
	mov  ebx, eax ; kopiowanie EAX do EBX 
	and  ebx, 0000000FH ; zerowanie bitów 31 - 4  rej.EBX 
	mov  dl, dekoder[ebx] ; pobranie cyfry z tablicy  
	mov  [edi + esi], dl ; przesłanie cyfry do obszaru roboczego 
	inc  esi ; inkrementacja modyfikatora 
	loop  ptl3hex ; sterowanie pętlą 

; zastąpienie początkowych zer spacjami
	mov ecx, 7	; liczba obiegów pętli (ostatniej cyfry nie sprawdzamy)
	mov esi, 1	; indeks początkowy używany przy sprawdzaniu cyfr
	mov bl, 0	; bl = 0 - nie było pierwszej cyfry niebędącej zerem, 1 - była
sprawdz_zero:
	cmp byte PTR [edi + esi], 30h	; sprawdza, czy [edi + esi] ma kod ascii dla '0'
	je is_zero	; skacze, jeśli znak to '0'
	mov bl, 1	; jeśli tu dotarł, to znaczy, że znak to nie '0', więc ustaw, że już było pierwsze nie-zero
is_zero:
	cmp bl, 0	; sprawdź, czy nie było pierwszej cyfry innej niż 0
	jne not_zero	; jeśli była, skocz do "not_zero"
	mov byte PTR [edi + esi], 20h	; jeśli tu dotarł, to znaczy, że obecna cyfra jest '0' i nie było innej niż '0' wcześniej, więc wstawia spację zamiast zera
not_zero:	; jeśli obecna liczba to nie zero nieznaczące, to zwiększ indeks o jeden i przejdź do kolejnej iteracji
	inc esi		; zwiększenie indeksu wskazującego obecny znak w liczbie
	loop sprawdz_zero		; przejście do kolejnej iteracji

            
; wpisanie znaku nowego wiersza przed i po cyfrach 
	mov  byte PTR [edi][0], 10 
	mov  byte PTR [edi][9], 10
 ; wyświetlenie przygotowanych cyfr 
	push 10 ; 8 cyfr + 2 znaki nowego wiersza
	push edi ; adres obszaru roboczego 
	push 1 ; nr urządzenia (tu: ekran) 
	call __write ; wyświetlenie 
	
	add esp, 24 ; usunięcie ze stosu 24 bajtów, w tym 12 bajtów zapisanych przez 3 rozkazy push przed rozkazem call i 12 bajtów zarezerwowanych na początku podprogramu 
	popa ; odtworzenie rejestrów 
	ret ; powrót z podprogramu 
wyswietl_EAX_hex ENDP 


_main PROC
	;polecenie 'Wpisz dlugosc pierwszej przyprostokatnej'
	push rozmiar1			; długość łańcucha znaków do wyświetlenia
	push offset pierwsza	; adres początku łańcucha znaków
	push 1					; urządzenie wyjściowe
	call __write			; wywołanie funkcji __write
	add esp, 12				; usunięcie argumentów wywołania ze stosu (3*4 bajty)

	; wczytanie długości pierwszej przyprostokątnej i zapisanie kwadratu do ebx
	call wczytaj_do_EAX		; wczytanie
	mov ebx, eax			; skopiowanie wartości eax do ebx
	mul	ebx					; eax * ebx (w ebx jest kopia zawartości eax)
	mov ebx, eax			; zapisanie eax^2 do ebx

	;polecenie 'Wpisz dlugosc drugiej przyprostokatnej'
	push rozmiar2			; długość łańcucha znaków do wyświetlenia
	push offset druga		; adres początku łańcucha znaków
	push 1					; urządzenie wyjściowe
	call __write			; wywołanie funkcji __write
	add esp, 12				; usunięcie argumentów wywołania ze stosu (3*4 bajty)

	; wczytanie długości drugiej przyprostokątnej i zapisanie kwadratu do edx
	call wczytaj_do_EAX		; wczytanie
	mov edx, eax			; skopiowanie wartości eax do edx
	mul edx					; eax * edx (w edx jest kopia zawartości eax)

	; teraz w ebx znajduje się kwadrat pierwszej przyprostokątnej, a w eax kwadrat drugiej
	add eax, ebx			; suma kwadratów

	; wstawienie sumy kwadratów (zawartości eax) do pamięci
	mov [suma_kwadratow], eax

	; pierwiastek kwadratowy z eax
	finit							; inicjalizacja stosu zmiennoprzecinkowego
	fild dword ptr [suma_kwadratow]	; włożenie na stos zmiennoprzecinkowy sumy kwadratów
	fsqrt							; pierwiastkowanie 
	fistp dword ptr [suma_kwadratow]; zapisanie wyniku do pamięci zaokrąglonego wyniku w formacie int pod adresem suma_kwadratow (bo już nie jest potrzebna dotychczasowa zawartość)

	; przeniesienie do eax wyniku
	mov eax, [suma_kwadratow]	

	; wyświetlenie wyniku
	call wyswietl_EAX

	push 0
	call _ExitProcess@4
_main ENDP
END