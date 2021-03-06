75200 #include "rundecs.h"
75210     (*  COPYRIGHT 1983 C.H.LINDSEY, UNIVERSITY OF MANCHESTER  *)
75220  (**)
75230 PROCEDURE CL68(PB: ASNAKED; RF: OBJECTP); EXTERN ;
75240 PROCEDURE GARBAGE (ANOBJECT: OBJECTP); EXTERN ;
75250 PROCEDURE FORMPDESC(OLDESC: OBJECTP; VAR PDESC1: PDESC); EXTERN ;
75260 FUNCTION NEXTEL(I: INTEGER; VAR PDESC1: PDESC): BOOLEAN; EXTERN ;
75270 PROCEDURE ERRORR(N :INTEGER); EXTERN ;
75280 FUNCTION SAFEACCESS(LOCATION: OBJECTP): UNDRESSP; EXTERN;
75290 PROCEDURE TESTCC (TARGET: OBJECTP); EXTERN ;
75300 PROCEDURE TESTSS (REFSTRUCT: OBJECTP); EXTERN ;
75310 FUNCTION CRSTRING(LENGTH: OFFSETRANGE): OBJECTP; EXTERN ;
75320 FUNCTION GETPROC(RN: OBJECTP): ASNAKED; EXTERN ;
75330 PROCEDURE CLPASC1(P1: IPOINT; PROC: ASPROC); EXTERN;
75340 PROCEDURE CLRDSTR(PCOV: OBJECTP; VAR CHARS: GETBUFTYPE; TERM (*+01() , TERM1 ()+01*) : TERMSET;
75350                   VAR I: INTEGER; BOOK: FETROOMP; PROC: ASPROC); EXTERN;
75360 FUNCTION FUNC68(PB: ASNAKED; RF: OBJECTP): BOOLEAN; EXTERN;
75370 PROCEDURE TESTF(RF:OBJECTP;VAR F:OBJECTP); EXTERN;
75380 PROCEDURE ENSSTATE(RF:OBJECTP;VAR F:OBJECTP;READING:STATUSSET); EXTERN;
75390 FUNCTION ENSPAGE(RF:OBJECTP;VAR F:OBJECTP):BOOLEAN; EXTERN;
75400 FUNCTION ENSLINE(RF:OBJECTP;VAR F:OBJECTP):BOOLEAN; EXTERN;
75410 (**)
75420 (**)
75430 PROCEDURE GETT(RF: OBJECTP);
75440 (*+02() LABEL 1; ()+02*)
75450   VAR COUNT, XMODE, XSIZE, SIZE, I, J: INTEGER;
75460       Q:INTPOINT;
75470       PVAL,F:OBJECTP;
75480       P: UNDRESSP;
75490       TEMP: REALTEGER;
75500       TEMPLATE:DPOINT;
75510       WASSTRING:BOOLEAN;
75520       BUFFER:RECORD CASE SEVERAL OF
75530       1:     (CHARS: GETBUFTYPE);
75540       2:     (INTS :ARRAY [1..20] OF INTEGER);
75550       0, 3, 4, 5, 6, 7, 8, 9, 10: () ;
75560              END;
75570       PDESC1: PDESC;
75580 (**)
75590 (*+02() PROCEDURE DUMMYG; (*JUST HERE TO MAKE 1 GLOBAL, NOT CALLED*)
75600         BEGIN GOTO 1 END;     ()+02*)
75610 (**)
75620   PROCEDURE SKIPSPACES(RF:OBJECTP;VAR F:OBJECTP);
75630    (*SKIP INITIAL SPACES,++ENSSPOSN OF NEXT NON SPACE CHAR++*)
75640     VAR CA:CHAR;
75650         I: INTEGER;
75660     BEGIN
75670     REPEAT
75680       IF [LINEOVERFLOW]<=F^.PCOVER^.STATUS
75690       THEN IF NOT ENSLINE(RF,F) THEN ERRORR(NOLOGICAL);
75700       I := 0;
75710       WITH F^ DO
75720         CLRDSTR(PCOVER, BUFFER.CHARS, ALLCHAR-[' '] (*+01() , ALLCHAR1 ()+01*) , I, PCOVER^.BOOK, PCOVER^.DOGETS)
75730     UNTIL NOT(LINEOVERFLOW IN F^.PCOVER^.STATUS)
75740     END;   (*SKIPSPACES*)
75750 (**)
75760   PROCEDURE VALUEREAD(RF:OBJECTP;VAR F:OBJECTP);
75770 (*+01() LABEL 111,222,77; ()+01*)
75780     VAR PTR: UNDRESSP;
75790         C,CC:CHAR;
75800         CARRYON, ISEEN: BOOLEAN;
75810         I,J,K:INTEGER;
75820         OLD:STATUSSET;
75830     PROCEDURE READNUM;
75840     CONST MAXINTDIV10 = (*+11() 28147497671065 ()+11*) (*+12() 3276 ()+12*) (*+13() 214748364 ()+13*) ;
75850           MAXINTMOD10 = (*+11() 5 ()+11*) (*+12() 7 ()+12*) (*+13() 7 ()+13*) ;
75860       VAR PM, DIGITS, I, VALDIG: INTEGER;
75870           NEG: BOOLEAN;
75880         BEGIN WITH F^, TEMP, BUFFER DO
75890           BEGIN
75900           PM := 0;
75910           CLRDSTR(PCOVER,CHARS,ALLCHAR-['+','-'] (*+01() , ALLCHAR1 ()+01*) ,PM,PCOVER^.BOOK,PCOVER^.DOGETS);
75920           NEG := (PM=1) AND (CHARS[0]='-');
75930           I := 0;
75940           CLRDSTR(PCOVER,CHARS,ALLCHAR-[' '] (*+01() , ALLCHAR1 ()+01*) ,I,PCOVER^.BOOK,PCOVER^.DOGETS);
75950           DIGITS := 0;
75960           CLRDSTR(PCOVER,CHARS,ALLCHAR-['0'..'9'] (*+01() , ALLCHAR1 ()+01*) ,DIGITS,PCOVER^.BOOK,PCOVER^.DOGETS);
75970           IF (PM>1) OR (DIGITS=0) THEN ERRORR(NODIGIT);
75980           INT := 0;
75990           FOR I := 0 TO DIGITS-1 DO
76000             BEGIN
76010               VALDIG := ORD( CHARS[I] ) - ORD( '0' ) ;
76020               IF ( INT > MAXINTDIV10 ) OR ( ( INT = MAXINTDIV10 ) AND ( VALDIG > MAXINTMOD10 ) ) THEN
76030                 ERRORR( WRONGVAL ) ;
76040               INT := INT * 10 + VALDIG
76050             END;
76060           IF NEG THEN INT := - INT
76070           END
76080         END;
76090 (**)
76100     PROCEDURE READREAL;
76110 (*+01()
76120       CONST TML=10000000000000000B;
76130             LIMIT=14631463146314631B; (*16*TML/10*)
76140 ()+01*)
76150       VAR RINT: MINT ;
76160           PM, BEFORE, AFTER, E, I, RINTEXP: INTEGER;
76170           NEG: BOOLEAN;
76180         BEGIN WITH F^, TEMP, BUFFER DO
76190           BEGIN
76200           PM := 0;
76210           CLRDSTR(PCOVER,CHARS,ALLCHAR-['+','-'] (*+01() , ALLCHAR1 ()+01*) ,PM,PCOVER^.BOOK,PCOVER^.DOGETS);
76220           NEG := (PM=1) AND (CHARS[0]='-');
76230           I := 0;
76240           CLRDSTR(PCOVER,CHARS,ALLCHAR-[' '] (*+01() , ALLCHAR1 ()+01*) ,I,PCOVER^.BOOK,PCOVER^.DOGETS);
76250           BEFORE := 0; AFTER := 0; E := 0;
76260           CLRDSTR(PCOVER,CHARS,ALLCHAR-['0'..'9'] (*+01() , ALLCHAR1 ()+01*) ,BEFORE,PCOVER^.BOOK,PCOVER^.DOGETS);
76270           RINT := 0;
76280           FOR I := 0 TO BEFORE-1 DO
76290             (*+01() IF RINT<LIMIT THEN ()+01*)
76300               RINT := RINT*10+(ORD(CHARS[I])-ORD('0'))
76310             (*+01() ELSE E := E+1 ()+01*) ;
76320           I := 0;
76330           CLRDSTR(PCOVER,CHARS,ALLCHAR-['.','E'(*-50(),CHR(ORD('E')+32)()-50*)](*+01(),ALLCHAR1()+01*),
76340                        I,PCOVER^.BOOK,PCOVER^.DOGETS);
76350           IF (I>0) AND (CHARS[0]='.') THEN
76360             BEGIN
76370             CLRDSTR (
76380               PCOVER,CHARS,ALLCHAR-['0'..'9'] (*+01() , ALLCHAR1 ()+01*) ,AFTER,PCOVER^.BOOK,PCOVER^.DOGETS
76390                     ) ;
76400             FOR I := 0 TO AFTER-1 DO
76410               (*+01() IF RINT<LIMIT THEN ()+01*)
76420                 RINT := RINT*10+(ORD(CHARS[I])-ORD('0'))
76430               (*+01() ELSE E := E+1 ()+01*) ;
76440             RINTEXP := BEFORE + AFTER - E ;
76450             I := 0;
76460             CLRDSTR(PCOVER,CHARS,ALLCHAR-['E'(*-50(),CHR(ORD('E')+32)()-50*)](*+01(),ALLCHAR1()+01*),
76470                     I,PCOVER^.BOOK,PCOVER^.DOGETS);
76480             IF (PM>1) OR (AFTER=0) THEN ERRORR(NODIGIT);
76490             E := E-AFTER;
76500             END
76510           ELSE IF (PM>1) OR (BEFORE=0) THEN ERRORR(NODIGIT);
76520           IF (I>0) AND ((CHARS[0]='E') (*-50()OR (CHARS[0]=CHR(ORD('E')+32))()-50*)) THEN
76530             BEGIN
76540             I := 0;
76550             CLRDSTR(PCOVER,CHARS,ALLCHAR-[' '] (*+01() , ALLCHAR1 ()+01*) ,I,PCOVER^.BOOK,PCOVER^.DOGETS);
76560             READNUM;
76570             E := E+INT;
76580             END;
76590           IF ( E + RINTEXP <= MINREALEXP ) OR ( RINT = 0 ) THEN REA := 0.0
76600           ELSE IF E>=323 THEN ERRORR(WRONGVAL)
76610           ELSE
76620             BEGIN
76630    (*-02()  REA := TIMESTEN(RINT, E); ()-02*)
76640    (*+02()  REA := TIMESTE(RINT, E); ()+02*)
76650             IF INT=INTUNDEF THEN ERRORR(WRONGVAL);
76660             END;
76670           IF NEG THEN REA := -REA;
76680           END
76690         END;
76700 (**)
76710     BEGIN WITH TEMP DO
76720       BEGIN
76730       IF NOT([OPENED,READMOOD,CHARMOOD]<=F^.PCOVER^.STATUS) THEN
76740         ENSSTATE(RF, F, [OPENED,READMOOD,CHARMOOD]);
76750       XSIZE := SZINT;
76760       CASE XMODE OF
76770    -1:    (*FILLER*) XSIZE := 0;
76780 (*+61() 1,3,5: (*LONG MODES*)
76790           BEGIN XSIZE := SZLONG; DUMMY END; ()+61*)
76800     0:    (*INT*)
76810           BEGIN SKIPSPACES(RF,F); READNUM; P^.FIRSTINT := INT END;
76820     2:    (*REAL*)
76830           BEGIN XSIZE := SZREAL; SKIPSPACES(RF,F); READREAL; P^.FIRSTREAL := REA END;
76840     4:    (*COMPL*)
76850           BEGIN
76860           XSIZE := SZADDR;
76870           SKIPSPACES(RF,F);
76880           READREAL;
76890           P^.FIRSTREAL := REA;
76900           I := 0;
76910           WITH F^ DO
76920             CLRDSTR (
76930               PCOVER,BUFFER.CHARS,ALLCHAR-[' ','I'] (*+01() , ALLCHAR1 ()+01*) ,I,PCOVER^.BOOK,PCOVER^.DOGETS
76940                     ) ;
76950           ISEEN := FALSE;
76960           FOR K := 0 TO I-1 DO
76970             ISEEN := ISEEN OR (BUFFER.CHARS[K]='I');
76980           IF NOT ISEEN THEN ERRORR(WRONGCHAR);
76990           READREAL;
77000           P := INCPTR(P, SZREAL);
77010           P^.FIRSTREAL := REA;
77020           END;
77030     6:    (*CHAR*)
77040           BEGIN IF [LINEOVERFLOW]<=F^.PCOVER^.STATUS
77050             THEN IF NOT ENSLINE(RF,F) THEN ERRORR(NOLOGICAL);
77060             I := -1;
77070             WITH F^ DO
77080               CLRDSTR(PCOVER, BUFFER.CHARS, ALLCHAR (*+01() , ALLCHAR ()+01*) , I, PCOVER^.BOOK, PCOVER^.DOGETS);
77090             P^.FIRSTWORD := I
77100           END;
77110     7:    (*STRING*)
77120           WITH BUFFER DO
77130             BEGIN
77140             XSIZE := SZADDR;
77150             I:=0;
77160             REPEAT
77170               IF [PAGEOVERFLOW]<=F^.PCOVER^.STATUS
77180               THEN CARRYON:=ENSPAGE(RF,F)
77190               ELSE CARRYON:=TRUE;
77200               IF CARRYON THEN
77210                 IF [LINEOVERFLOW]<=F^.PCOVER^.STATUS
77220                 THEN BEGIN OLD:=F^.PCOVER^.STATUS;
77230                   IF F^.LINEMENDED=UNDEFIN THEN CARRYON := FALSE
77240                   ELSE CARRYON:=FUNC68(GETPROC(F^.LINEMENDED),RF);
77250                   ENSSTATE(RF,F,OLD)
77260                   END
77270                 ELSE
77280                   WITH F^ DO
77290                     BEGIN
77300                     CLRDSTR(PCOVER, CHARS, TERM (*+01() , TERM1 ()+01*) , I, PCOVER^.BOOK, PCOVER^.DOGETS);
77310                     CARRYON := LINEOVERFLOW IN PCOVER^.STATUS
77320                     END
77330             UNTIL NOT CARRYON;
77340             WITH P^ DO
77350               BEGIN FPDEC(FIRSTPTR^);
77360               IF FPTST(FIRSTPTR^) THEN GARBAGE(FIRSTPTR);
77370               FIRSTPTR:=CRSTRING(I);
77380               FPINC(FIRSTPTR^);
77390               PTR := INCPTR(FIRSTPTR, STRINGCONST);
77400               END;
77410             WHILE I <> (I DIV CHARPERWORD) * CHARPERWORD DO
77420               BEGIN CHARS[I]:=CHR(0);
77430               I:=I+1
77440               END;
77450             J:=I DIV CHARPERWORD ;
77460             FOR I:=1 TO J DO
77470               BEGIN PTR^.FIRSTWORD := INTS[I]; PTR := INCPTR(PTR, SZWORD) END;
77480             END;    (*STRING*)
77490     8:    (*BOOL*)
77500           BEGIN IF [LINEOVERFLOW]<=F^.PCOVER^.STATUS
77510             THEN IF NOT ENSLINE(RF,F) THEN ERRORR(NOLOGICAL);
77520           I := -1;
77530           WITH F^ DO
77540             CLRDSTR(PCOVER, BUFFER.CHARS, ALLCHAR (*+01() , ALLCHAR ()+01*) , I, PCOVER^.BOOK, PCOVER^.DOGETS);
77550           IF CHR(I)='T' THEN INT := TRUEVAL
77560           ELSE IF CHR(I)='F' THEN INT := 0
77570           ELSE ERRORR(WRONGCHAR) ;
77580           P^.FIRSTWORD := INT
77590           END;      (*BOOL*)
77600     9:    (*BITS*)
77610           BEGIN K:=0;
77620           FOR J:=1 TO BITSWIDTH DO
77630             BEGIN SKIPSPACES(RF,F);
77640             I := -1;
77650             WITH F^ DO
77660               CLRDSTR(PCOVER, BUFFER.CHARS, ALLCHAR (*+01() , ALLCHAR ()+01*) , I, PCOVER^.BOOK, PCOVER^.DOGETS);
77670             IF CHR(I) IN ['T','F'] THEN K := K*2+ORD(CHR(I)='T')
77680             ELSE ERRORR(WRONGCHAR)
77690             END;
77700           P^.FIRSTWORD := K
77710           END;
77720    10:    (*BYTES*)
77730           FOR J:=1 TO BYTESWIDTH DO
77740             BEGIN
77750             IF LINEOVERFLOW IN F^.PCOVER^.STATUS THEN
77760               IF NOT ENSLINE(RF, F) THEN ERRORR(NOLOGICAL);
77770             I := -1;
77780             WITH F^ DO
77790               CLRDSTR(PCOVER, BUFFER.CHARS, ALLCHAR (*+01() , ALLCHAR ()+01*) , I, PCOVER^.BOOK, PCOVER^.DOGETS);
77800             ALF[J] := CHR(I);
77810             P^.FIRSTWORD := INT
77820             END;
77830    11:    (*PROC*)
77840           CL68(GETPROC(PVAL), RF);
77850    12:    (*STRUCT*)
77860           BEGIN J:=0;
77870           REPEAT J:=J+1 UNTIL TEMPLATE^[J]<0;
77880           I:=ORD(P);
77890           WHILE ORD(P)-I<TEMPLATE^[0] DO
77900             BEGIN J:=J+1;
77910             XMODE:=TEMPLATE^[J]-1;
77920             VALUEREAD(RF,F);
77930             P:=INCPTR(P, XSIZE)
77940             END;
77950           XMODE:=12;
77960           END;      (*STRUCT*)
77970    14:    (*CODE(REF FILE)VOID*)
77980           CLPASC1( ORD(RF), PROCC );
77990         END;   (*CASE*)
78000       END    (*WITH*)
78010     END;     (*VALUEREAD*)
78020 (**)
78030     BEGIN   (*GET*)
78040 (*+02() 1: ()+02*) COUNT := GETSTKTOP(SZWORD, 0);
78050     FPINC(RF^);
78060     J := COUNT+SZWORD; WHILE J>SZWORD DO
78070       BEGIN
78080       J := J-SZWORD;
78090       XMODE := GETSTKTOP(SZWORD, J);
78100       IF XMODE IN [0..13,15..31] THEN
78110         BEGIN
78120         J := J - SZADDR;
78130         PVAL := ASPTR(GETSTKTOP(SZADDR, J));
78140         FPINC(PVAL^);
78150         END
78160       ELSE IF XMODE=14 THEN J := J-SZPROC
78170       END;
78180     TESTF(RF,F);
78190     J := COUNT+SZWORD; WHILE J>SZWORD DO
78200       BEGIN
78210       J := J-SZWORD;
78220       XMODE:=GETSTKTOP(SZWORD, J);
78230       IF XMODE>=16 THEN   (*ROW*)
78240         BEGIN XMODE:=XMODE-16;
78250         J := J-SZADDR;
78260         PVAL:=ASPTR(GETSTKTOP(SZADDR, J));
78270         WITH PVAL^ DO
78280           BEGIN
78290            IF FPTWO(ANCESTOR^.PVALUE^) THEN
78300             TESTCC(PVAL);
78310           FORMPDESC(PVAL,PDESC1);
78320           TEMPLATE:=MDBLOCK;
78330           WITH ANCESTOR^ DO
78340             BEGIN
78350             IF ORD(TEMPLATE)=0 THEN SIZE:=1
78360             ELSE IF ORD(TEMPLATE)<=MAXSIZE THEN SIZE:=ORD(TEMPLATE)
78370             ELSE SIZE:=TEMPLATE^[0];
78380             WHILE NEXTEL(0,PDESC1) DO WITH PDESC1 DO WITH PDESCVEC[0] DO
78390               BEGIN I:=PP;
78400               WHILE I<PP+PSIZE DO
78410                 BEGIN
78420                 P:=INCPTR(PVALUE, I);
78430                 VALUEREAD(RF,F); I:=I+SIZE
78440                 END
78450               END
78460             END
78470           END
78480         END
78490       ELSE IF XMODE>=0 THEN
78500         BEGIN WASSTRING:=FALSE;
78510         IF XMODE = 14 THEN
78520           BEGIN
78530           J := J - SZPROC ;
78540           TEMP.PROCC := GETSTKTOP( SZPROC , J )
78550           END
78560         ELSE
78570           BEGIN
78580           J := J - SZADDR ;
78590           PVAL:=ASPTR(GETSTKTOP(SZADDR, J));
78600           IF XMODE <> 11 THEN WITH PVAL^ DO
78610             IF SORT IN [RECN, REFN] THEN
78620               IF XMODE<>7 THEN  (*NOT STRING*)
78630                 BEGIN
78640                 TEMPLATE:=PVALUE^.DBLOCK;
78650                 IF FPTWO(PVALUE^) THEN
78660                       TESTSS(PVAL);
78670                 P := INCPTR(PVALUE, STRUCTCONST)
78680                 END
78690               ELSE
78700                 BEGIN ENEW(P,1); P^.FIRSTPTR:=PVALUE;WASSTRING:=TRUE END
78710             ELSE
78720               BEGIN
78730               TEMPLATE := DBLOCK;
78740               WITH ANCESTOR^ DO
78750                 IF FPTWO(PVALUE^) THEN
78760                   P := SAFEACCESS(PVAL)
78770                 ELSE
78780                   BEGIN
78790                   PVALUE^.OSCOPE := 0;
78800                   P := INCPTR(PVALUE,PVAL^.OFFSET)
78810                   END
78820               END
78830           END;
78840         VALUEREAD(RF,F);
78850         IF WASSTRING THEN
78860           BEGIN PVAL^.PVALUE := P^.FIRSTPTR; EDISPOSE(P, 1) END;
78870         END;
78880       END;
78890     J := COUNT+SZWORD; WHILE J>SZWORD DO
78900       BEGIN
78910       J := J-SZWORD;
78920       XMODE := GETSTKTOP(SZWORD, J);
78930       IF XMODE IN [0..13,15..31] THEN
78940         BEGIN
78950         J := J - SZADDR;
78960         PVAL := ASPTR(GETSTKTOP(SZADDR, J)); WITH PVAL^ DO
78970           BEGIN FDEC; IF FTST THEN GARBAGE(PVAL) END;
78980         END
78990       ELSE IF XMODE = 14 THEN J := J - SZPROC
79000       END;
79010     WITH RF^ DO
79020       BEGIN FDEC; IF FTST THEN GARBAGE(RF) END;
79030     END;     (*GET*)
79040 (**)
79050 (**)
79060 (*+01() (*$X4*) ()+01*)
79070 (**)
79080 (**)
79090 (*-02()
79100 BEGIN (*OF A68*)
79110 END; (*OF A68*)
79120 ()-02*)
79130 (*+01()
79140 BEGIN (*OF MAIN PROGRAM*)
79150 END (* OF EVERYTHING *).
79160 ()+01*)
