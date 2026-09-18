.data
change:.asciz "%ldc%ld\n"
first:.asciz "< %.*s\n" 
separator:.asciz "---\n"
second:.asciz "> %.*s\n" 

file1: .asciz "Hi, this is a testfile.\nTestfile 1 to be precise."
file2: .asciz "Hi, this is a testfile.\nTestfile 2 to be precise.\n\n" #hardcoded files

.text
.global main
.extern printf
.extern exit
    


diff:
    pushq %rbp
    movq  %rsp, %rbp

    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    subq  $64, %rsp      

    movq $1, -8(%rbp)   #file1 line counter
    movq $1, -16(%rbp)  #file2 line counter
    movq %rdi, -24(%rbp) #saving the address of the first file on the stack
    movq %rsi, -32(%rbp) #saving the address of the 2nd file on the stack
    movq %rdx, %r12      #the kind-of-boolean is i?
    movq %rcx, %r13      #the kind-of-boolean is B?

    movq $0, -56(%rbp)   # ► folosit pentru a „îngheța” nr. liniei din dreapta când doar stânga continuă

lines:
    movq -24(%rbp), %rdi #moving the address of the first file into rdi so we can call nextline
    call nextline #the function is scanning the line until \n and \0
    movq %rax,-24(%rbp) #address of the newline
    movq %rcx, %r14 #address of the start (this line)
    movq %rdx, %r10 #numbers of characters of that line

    movq -32(%rbp), %rdi #moving the address of the 2nd file into rdi so we can call nextline
    call nextline #the function is scanning the line until \n and \0
    movq %rax,-32(%rbp) #address of the newline
    movq %rcx, %r15 #address of the start (this line)
    movq %rdx, %r11 #numbers of characters of that line

    movq %r10, -40(%rbp)   # save len1
    movq %r11, -48(%rbp)   # save len2

    # --- EARLY EOF GUARD: dacă ambele fișiere sunt la EOF, terminăm (► NOU)
    cmpq $-1, %r10            # len1 == -1 ?
    jne  1f
    cmpq $-1, %r11            # len2 == -1 ?
    jne  1f
    jmp  done1
1:

    cmpq $0, %r13 #comparing the blank sign, if it s 1, then we need to ignore blanks
    je noblank #if it s 0, then we don t care

blankskip1: #but now we care about blanks, for the first file
    # ► FIX: nu sări blank-uri dacă e EOF (len == -1)
    cmpq $-1, %r10
    je  noblank
    jmp  .Lbs1_check
.Lbs1_check:
    movq %r14, %rdi #putting address of the start of this line in rdi
    movq %r10, %rsi #putting the numbers of characters in this line in rsi
    call blank # returns 1 to rax if it is blank and 0 if it s not
    cmpb $0, %al #is not blank ?
    je  blankskip2 #go see if file 2 is blank
    movq -8(%rbp), %rax
    addq $1, %rax
    movq %rax, -8(%rbp) #incrementing the line counter for file1, because we don t see a difference
    movq -24(%rbp), %rdi #address of the first file line into rdi
    call nextline #calling nextline
    movq %rax, -24(%rbp) #address of the next line
    movq %rcx, %r14 #start of the current line
    movq %rdx, %r10 #length of the current line
    movq %r10, -40(%rbp)    # update len1 saved copy
    jmp blankskip1 #loop again, until we don t fine empty lines

blankskip2: #but now we care about blanks, for the second file
    # ► FIX: nu sări blank-uri dacă e EOF (len == -1)
    cmpq $-1, %r11
    je  noblank
    jmp  .Lbs2_check
.Lbs2_check:
    movq %r15, %rdi #putting address of the start of this line in rdi
    movq %r11, %rsi #putting the numbers of characters in this line in rsi
    call blank # returns 1 to rax if it is blank and 0 if it s not
    cmpb $0, %al #is not blank ?
    je noblank
    movq -16(%rbp), %rax
    addq $1, %rax
    movq %rax, -16(%rbp) #incrementing the line counter for file2, because we don t see a difference
    movq -32(%rbp), %rdi #address of the 2nd file into rdi
    call nextline
    movq %rax, -32(%rbp) #address of the next line
    movq %rcx, %r15 #start of the current line
    movq %rdx, %r11 #length of the current line
    movq %r11, -48(%rbp)    # update len2 saved copy
    jmp blankskip2

noblank:
    # ► NOU: detecție EOF simplă prin len == -1
    xorq %r8, %r8              # end1=0
    cmpq $-1, %r10
    jne  .Lnot_end1_set
    movq $1, %r8               # end1=1
.Lnot_end1_set:

    xorq %r9, %r9              # end2=0
    cmpq $-1, %r11
    jne  .Lnot_end2_set
    movq $1, %r9               # end2=1
.Lnot_end2_set:

    testq %r8, %r8
    jz    .Lnot_end1          
 
    testq %r9, %r9
    jz    tail_right_only      # only file2 continues
    jmp   done1                # both ended

.Lnot_end1:                   
    testq %r9, %r9
    jz    Bcompare             # neither ended -> normal compare

    movq -56(%rbp), %rax
    testq %rax, %rax
    jne   1f
    movq -16(%rbp), %rax       # current file2 line number
    movq %rax, -56(%rbp)       # save it once
1:
    movq -56(%rbp), %rax       # ► NOU: aliniaza și contorul „live” la valoarea înghețată
    movq %rax, -16(%rbp)

    jmp   tail_left_only       # only file1 continues

tail_right_only:
    movq $change, %rdi
    movq -8(%rbp),  %rsi      
    movq -16(%rbp), %rdx       
    xorq %rax, %rax
    call printf

    movq $first, %rdi
    xorl %esi, %esi           # n=0 (l-stânga goală simbolic)
    movq %r14, %rdx        
    xorq %rax, %rax
    call printf

    movq $separator, %rdi
    xorq %rax, %rax
    call printf

    movq $second, %rdi
    movl -48(%rbp), %esi       # n=len2
    movq %r15, %rdx           
    xorq %rax, %rax
    call printf

    movq -16(%rbp), %rax
    incq %rax
    movq %rax, -16(%rbp)

    movq -32(%rbp), %rdi
    call nextline
    movq %rax, -32(%rbp)
    movq %rcx, %r15
    movq %rdx, %r11
    movq %r11, -48(%rbp)      
    jmp noblank

tail_left_only:
    movq $change, %rdi
    movq -8(%rbp),  %rsi      
    movq -56(%rbp), %rdx      # ► FIX: folosim numărul din dreapta „înghețat”
    xorq %rax, %rax
    call printf

    movq $first, %rdi
    movl -40(%rbp), %esi      # n=len1
    movq %r14, %rdx            
    xorq %rax, %rax
    call printf

    movq $separator, %rdi
    xorq %rax, %rax
    call printf

    movq $second, %rdi
    xorl %esi, %esi           # n=0 (dreapta goală simbolic)
    movq %r15, %rdx          
    xorq %rax, %rax
    call printf

    # FIX: bump ONLY file1 line number in the left-tail case
    movq -8(%rbp), %rax
    incq %rax
    movq %rax, -8(%rbp)

    movq -24(%rbp), %rdi
    call nextline
    movq %rax, -24(%rbp)
    movq %rcx, %r14
    movq %rdx, %r10
    movq %r10, -40(%rbp)      
    jmp noblank

Bcompare:
    movq %r10,-40(%rbp) #moving the length of the first line to r10
    movq %r11,-48(%rbp) #moving the length of the second line into r11

    cmpq $0, %r10 #is line 1 empty ? but not the end
    jne check1

    cmpq $0, %r11 #is line 2 empty ? but not the end
    jne line2notblank #then line1 is blank, but line 2 is not

    jmp nodiff

check1:
    cmpq $0, %r11 #one has content, but what about 2?
    jne COMPARE #2 has content as well sad! so we jump to compare

    movq $change, %rdi #if one has content and two doesn t
    movq -8(%rbp), %rsi #file 1 line number
    movq -16(%rbp),%rdx #file 2 line number
    movq $0, %rax
    call printf

    movq $first, %rdi #address of the mainstring1
    movl -40(%rbp), %esi #length of the line
    movq %r14, %rdx #pointer to the start of the string
    movq $0, %rax
    call  printf

    movq $separator, %rdi
    movq $0, %rax
    call printf

    movq $second, %rdi
    movq $0, %rsi
    movq %r15, %rdx #pointer to the start of the string
    movq $0, %rax
    call printf

    jmp nodiff

line2notblank: #line1 is blank but line 2 is not blank
    movq $change, %rdi
    movq -8(%rbp),  %rsi
    movq -16(%rbp), %rdx
    movq $0, %rax
    call printf

    movq $first, %rdi #address of the mainstring1
    movq $0, %rsi
    movq %r14, %rdx
    movq $0, %rax
    call printf

    movq $separator, %rdi
    movq $0, %rax
    call printf

    movq $second, %rdi
    movl -48(%rbp), %esi
    movq %r15, %rdx
    movq $0, %rax
    call printf

    jmp nodiff

COMPARE:
    movq %r14, %rdi #line pointer1  -start
    movq %r10, %rsi #line 1 length
    movq %r15, %rdx #line pointer2  -start
    movq %r11, %rcx #line 2 length
    movq %r12, %r8  #finally our insensitive case
    call comparelines
    cmpq $0, %rax #if rax is 0 then the line have no difference
    je nodiff

    movq $change, %rdi
    movq -8(%rbp),  %rsi
    movq -16(%rbp), %rdx
    movq $0, %rax
    call printf

    movq $first, %rdi
    movl -40(%rbp), %esi
    movq %r14, %rdx
    movq $0, %rax
    call printf

    movq $separator, %rdi
    movq $0, %rax
    call printf

    movq $second, %rdi
    movl -48(%rbp), %esi
    movq %r15, %rdx
    movq $0, %rax
    call printf

nodiff:
    # ► NOU: recalcul end1/end2 pe baza len == -1
    xorq %r8, %r8
    cmpq $-1, %r10
    jne  1f
    movq $1, %r8
1:
    xorq %r9, %r9
    cmpq $-1, %r11
    jne  2f
    movq $1, %r9
2:
    testq %r8, %r8
    jne  3f
    movq -8(%rbp), %rax
    incq %rax
    movq %rax, -8(%rbp)
3:
    testq %r9, %r9
    jne  4f
    movq -16(%rbp), %rax
    incq %rax
    movq %rax, -16(%rbp)
4:
    jmp lines

done1:
    addq  $64, %rsp            # ► FIX: restore stack
    popq  %r15
    popq  %r14
    popq  %r13
    popq  %r12
    movq %rbp, %rsp
    popq %rbp
    ret


# return values : rax=address of the next string, rcx = start of the string, rdx=lenth of the string
# ► FIX INTEGRAL: rdx = -1 la EOF, len=0 pentru linie goală reală
nextline:
    pushq %rbp
    movq  %rsp, %rbp

    movq %rdi, %rcx #this is the address of the string
    movq %rdi, %rax #we will use that to go through the string
    movq $0, %rdx  #the length of the line, that is number of charatcters until \n or \0

    movzbl (%rax), %r8d
    testb %r8b, %r8b
    jne   .Lscan_start
    movq  $-1, %rdx            # ► EOF sentinel când primul char e '\0'
    jmp   .Lret

.Lscan_start:
#lineloop:
.Lscan:
    cmpb $'\n', %r8b
    je  .Lnewline
    cmpb  $0,   %r8b
    je  .Lret                 # sfârșit de string fără '\n' – len rămâne cât s-a acumulat
    addq $1,%rax #nextchar
    addq $1,%rdx #length of the string ++
    movzbl (%rax), %r8d
    jmp .Lscan

.Lnewline:
    addq $1, %rax #so we can jump over the '\n' (linie goală => len=0)

.Lret:
    movq %rbp, %rsp
    popq %rbp
    ret


blank: #verifying if the string contains just blank spaces or \n
    pushq %rbp
    movq %rsp, %rbp

    movq %rdi, %rax #address of the string
    movq %rsi, %rcx #number of characters
    cmpq $0, %rcx #if it has 0 characters then it s null
    je yesblank
loop:
    movq $0, %rdx
    movb (%rax), %dl #is the character from the string a space or a \n
    cmpb $' ', %dl
    je next
    cmpb $'\n', %dl
    je next
    movb $0, %al #if it didn t jump then the character is not an empty space or a new line
    jmp finishline
  next:
    addq $1, %rax #next character
    subq $1, %rcx
    cmpq $0, %rcx #if it s 0 it enters yesblank
    jne loop
yesblank:
    movb   $1, %al
finishline:
    movq  %rbp, %rsp
    popq %rbp
    ret


comparelines:
    pushq %rbp
    movq  %rsp, %rbp

    cmpq  %rsi, %rcx         
    jne lengthdiff
    movq %rsi, %r9
    cmpq $0, %r9
    je equal

comploop:
    movq $0, %r10
    movq $0, %rax
    movb (%rdi), %al          
    movb (%rdx), %r10b        

    cmpq $0, %r8
    je  noi

    cmpb $'A', %al
    jl   i2
    cmpb $'Z', %al
    jg   i2
    addb $32, %al
i2:
    cmpb $'A', %r10b
    jl   noi
    cmpb $'Z', %r10b
    jg   noi
    addb $32, %r10b
noi:
    cmpb %al, %r10b
    jne  lengthdiff
    addq $1, %rdi
    addq $1, %rdx
    subq $1, %r9
    cmpq $0, %r9
    jne  comploop
equal:
    movq  $0, %rax
    movq  %rbp, %rsp
    popq  %rbp
    ret
lengthdiff:
    movq  $1, %rax
    movq  %rbp, %rsp
    popq  %rbp
    ret


main:
    pushq %rbp
    movq  %rsp, %rbp #prologue

 # main ( argument count , argument vector)
    subq $32, %rsp  # e necesar ?
    movq %rdi, %r8  #saving argument count
    movq %rsi, %r9  #saving argument vector
    movq $0, %r12  #for i
    movq $0, %r13  #for B
    movq $1, %rcx  #looking for arguments, the first argument the one on position 0 is the name

argumentsloop:
    cmpq %rcx, %r8 #making the loop for arguments, in r8 we have the number of arguments
    jle argumentsdone #if r8 is less than rc then we are done, rcx >=r8
    movq (%r9,%rcx,8), %rdx #rdx= %r9 + %rcx*8 in r9 we have our vector, one element has 8bytes, so we are going to the address of that argument
    cmpq $0, %rdx #is the address null?
    je nextargument #okay so we have no argument here so go to the next argument
    movq $0, %rax
    movb (%rdx), %al #if it s not null let s see the first bit of rdx which is the address
    cmpb $'-', %al #is that bit a line ?
    jne nextargument #if not let s go to the next argument
    movq $0, %rax #if it is a line then what is after it ?
    movb 1(%rdx), %al #second bit of rdx
    cmpb $'i', %al #is that a i ? we will treat the case insensitive case ?
    jne isb # if not, is it a B? for the not lines, let s find out
    movq $1, %r12 #if it s a i nice ! put 1 in r12 so we can know that
    jmp nextargument #let s repeat this loop
isb:
    cmpb $'B', %al #is it a B?
    jne nextargument #idk what it is if not a B let s see the next argument
    movq  $1, %r13 #wow it s a B! let s put 1 so we can know that
nextargument:
    addq $1, %rcx #incrementing rcx
    jmp argumentsloop #to loooop

argumentsdone:
    movq $file1, %rdi #putting the address of file1 to rdi
    movq $file2, %rsi #putting the address of file2 to rsi
    movq  %r12, %rdx #r12 into rdx, this is the i
    movq  %r13, %rcx  #r13 into rcx, this is the B

    call  diff  #calling diff :(

    addq $32, %rsp
    movq %rbp, %rsp
    popq %rbp
    xorl %edi, %edi  
    call exit
