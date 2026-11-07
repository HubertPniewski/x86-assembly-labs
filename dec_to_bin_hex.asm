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
dziesiec  dd 10 ; mno¿nik 

; dla wyswietl_EAX_hex
dekoder db '0123456789ABCDEF' 

; dla komunikatu
za_duza db 'Zbyt duza liczba (musi byc mniejsza od 60000)'
rozmiar = $ - za_duza

; dla bin
dekoder_bin db '01'
do_wyswietlenia db '0000000000', 10


.code 


; wyœwietl zawartoœæ rejestru EAX w konsoli
wyswietl_EAX PROC
	pusha
 
	mov  esi, 10  ; indeks w tablicy 'znaki' 
	mov  ebx, 10  ; dzielnik równy 10 
 
konwersja: 
	mov  edx, 0			; zerowanie starszej czêœci dzielnej 
	div  ebx				; dzielenie przez 10, reszta w EDX, iloraz w EAX 
	add  dl, 30H			; zamiana reszty z dzielenia na kod ASCII 
	mov  znaki [esi], dl	; zapisanie cyfry w kodzie ASCII 
	dec  esi				; zmniejszenie indeksu 
	cmp  eax, 0			; sprawdzenie czy iloraz = 0 
	jne  konwersja			; skok, gdy iloraz niezerowy 
 
; wype³nienie pozosta³ych bajtów spacjami i wpisanie znaków nowego wiersza 
wypeln: 
	or	esi, esi 
	jz wyswietl					; skok, gdy ESI = 0 
	mov byte PTR znaki [esi], 20H	; kod spacji 
	dec esi						; zmniejszenie indeksu 
	jmp wypeln 
  
wyswietl: 
	mov  byte PTR znaki [0], 0AH	; kod nowego wiersza 
	mov  byte PTR znaki [11], 0AH	; kod nowego wiersza 
 
; wyœwietlenie cyfr na ekranie 
	push  dword PTR 12				; liczba wyœwietlanych znaków 
	push  dword PTR OFFSET znaki	; adres wyœw. obszaru 
	push  dword PTR 1				; numer urz¹dzenia (ekran ma numer 1) 
	call  __write					; wyœwietlenie liczby na ekranie 
	add  esp, 12					; usuniêcie parametrów ze stosu

	popa
	ret
wyswietl_EAX ENDP



; wczytaj do EAX podprogram
wczytaj_do_EAX PROC
; od³o¿enie rejestrów ogólnego przeznaczenia wykorzystywanych przez podprogram na stos (poza eax i esp)
	push ebx
	push ecx
	 
; wczytywanie liczby dziesiêtnej z klawiatury – po wprowadzeniu cyfr nale¿y nacisn¹æ klawisz Enter 
; liczba po konwersji na postaæ binarn¹ zostaje wpisana do rejestru EAX 
	push dword PTR 12 ; max iloœæ znaków wczytywanej liczby 
	push dword PTR OFFSET obszar ; adres obszaru pamiêci 
	push dword PTR 0; numer urz¹dzenia (0 dla klawiatury) 
	call __read ; odczytywanie znaków z klawiatury (dwa znaki podkreœlenia przed read) 
	add esp, 12 ; usuniêcie parametrów ze stosu 
 
 
; bie¿¹ca wartoœæ przekszta³canej liczby przechowywana jest w rejestrze EAX, przyjmujemy 0 jako wartoœæ pocz¹tkow¹ 
	mov eax, 0   
	mov ebx, OFFSET obszar ; adres obszaru ze znakami 
 
pobieraj_znaki: 
	mov  cl, [ebx]	; pobranie kolejnej cyfry w kodzie ASCII 
	inc  ebx		; zwiêkszenie indeksu 
	cmp  cl,10		; sprawdzenie czy naciœniêto Enter 
	je  byl_enter	; skok, gdy naciœniêto Enter 
	sub  cl, 30H	; zamiana kodu ASCII na wartoœæ cyfry 
	movzx ecx, cl	; przechowanie wartoœci cyfry w rejestrze ECX 
 
 
	mul  dword PTR dziesiec	; mno¿enie wczeœniej obliczonej wartoœci razy 10 
	add  eax, ecx			; dodanie ostatnio odczytanej cyfry 
	jmp  pobieraj_znaki		; skok na pocz¹tek pêtli 
 
byl_enter: 
; wartoœæ binarna wprowadzonej liczby znajduje siê teraz w rejestrze EAX 

; zdjêcie rejestrów ebx i ecx ze stosu i zakoñczenie podprogramu
	pop ecx
	pop ebx
	ret	; return
wczytaj_do_EAX ENDP


; wyœwietlanie zawartoœci rejestru EAX w postaci liczby szesnastkowej 
wyswietl_EAX_hex PROC 
	pusha  ; przechowanie rejestrów  
	sub  esp, 12 ; rezerwacja 12 bajtów na stosie (poprzez zmniejszenie rejestru ESP) przeznaczonych na tymczasowe przechowanie cyfr szesnastkowych wyœwietlanej liczby 
	mov  edi, esp ; adres zarezerwowanego obszaru pamiêci 
 
; przygotowanie konwersji            
	mov  ecx, 8 ; liczba obiegów pêtli konwersji 
	mov  esi, 1 ; indeks pocz¹tkowy u¿ywany przy zapisie cyfr 
 
; pêtla konwersji 
ptl3hex:    
	rol  eax, 4 ; przesuniêcie cykliczne (obrót) rejestru EAX o 4 bity w lewo w szczególnoœci, w pierwszym obiegu pêtli bity nr 31 - 28 rejestru EAX zostan¹ przesuniête na pozycje 3 - 0   
 
; wyodrêbnienie 4 najm³odszych bitów i odczytanie z tablicy 'dekoder' odpowiadaj¹cej im cyfry w zapisie szesnastkowym 
	mov  ebx, eax ; kopiowanie EAX do EBX 
	and  ebx, 0000000FH ; zerowanie bitów 31 - 4  rej.EBX 
	mov  dl, dekoder[ebx] ; pobranie cyfry z tablicy  
	mov  [edi][esi], dl ; przes³anie cyfry do obszaru roboczego 
	inc  esi ; inkrementacja modyfikatora 
	loop  ptl3hex ; sterowanie pêtl¹ 
            
; wpisanie znaku nowego wiersza przed i po cyfrach 
	 mov  byte PTR [edi][0], 10 
	 mov  byte PTR [edi][9], 10
 ; wyœwietlenie przygotowanych cyfr 
	push 10 ; 8 cyfr + 2 znaki nowego wiersza
	push edi ; adres obszaru roboczego 
	push 1 ; nr urz¹dzenia (tu: ekran) 
	call __write ; wyœwietlenie 
	
	add esp, 24 ; usuniêcie ze stosu 24 bajtów, w tym 12 bajtów zapisanych przez 3 rozkazy push przed rozkazem call i 12 bajtów zarezerwowanych na pocz¹tku podprogramu 
	popa ; odtworzenie rejestrów 
	ret ; powrót z podprogramu 
wyswietl_EAX_hex ENDP 

wyswietl_EAX_bin PROC
	pusha
	mov ecx, 10 ; licznik pêtli, 10 bo maksymalnie 10 cyfr
	mov edi, offset do_wyswietlenia
	mov esi, 0 ; indeks w liczbie binarnej


ptl_bin:
	mov edx, ecx
	dec edx
	bt eax, edx ; zapisuje do cf wartoœæ bitu o indeksie ecx
	jnc jest_zero
	mov ebx, [edi + esi]
	add ebx, 1 ; dodaje 1 do kodu znaku
	mov [edi + esi], ebx
jest_zero:
	inc esi
	loop ptl_bin
	
; wypisanie znaku
	push 12 ; iloœæ znaków
	push edi ; adres znaku
	push 1 ; urz¹dzenie wyjœciowe
	call __write
	add esp, 12 ; zdjêcie argumentów ze stosu


	popa
	ret
wyswietl_EAX_bin ENDP


_main PROC
	
	call wczytaj_do_EAX	; wczytanie liczby do EAX
	call wyswietl_EAX_hex ; wypisanie do konsoli liczby w systemie hex
	call wyswietl_EAX_bin ; wypisanie liczby binarnie

	push 0
	call _ExitProcess@4
_main ENDP
END