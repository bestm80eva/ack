50300 #include "rundecs.h"
50310     (*  COPYRIGHT 1983 C.H.LINDSEY, UNIVERSITY OF MANCHESTER  *)
50320 (**)
50330 PROCEDURE PCINCR (STRUCTPTR: UNDRESSP; TEMPLATE: DPOINT; INCREMENT: INTEGER); EXTERN;
50340 PROCEDURE GARBAGE(ANOBJECT:OBJECTP); EXTERN;
50350 PROCEDURE ERRORR(N :INTEGER); EXTERN;
50360 FUNCTION STRUCTSCOPE(STRUCTPTR: UNDRESSP; TEMPLATE: DPOINT):DEPTHRANGE; EXTERN;
50370 FUNCTION SAFEACCESS(LOCATION: OBJECTP): UNDRESSP; EXTERN;
50380 (**)
50390 (**)
50400 FUNCTION DRESSN(CONTENTS: UNDRESSP; TEMPLATE: DPOINT): OBJECTP;
50410 (*CRS A DRESSED VALUE FROM THE UNDRESSED CONTENTS*)
50420 VAR NEWSTRUCT: OBJECTP;
50430      SIZEOF: INTEGER;
50440 BEGIN
50450      SIZEOF:= TEMPLATE^[0];
50460      ENEW(NEWSTRUCT, SIZEOF+STRUCTCONST);
50470      WITH NEWSTRUCT^ DO
50480        BEGIN
50490 (*-02()FIRSTWORD := SORTSHIFT*ORD(STRUCT);()-02*)
50500 (*+02() PCOUNT:=0; SORT:=STRUCT; ()+02*)
50510        LENGTH := SIZEOF+STRUCTCONST;
50520        DBLOCK:= TEMPLATE;
50530        END;
50540      MOVELEFT(CONTENTS, INCPTR(NEWSTRUCT, STRUCTCONST), SIZEOF);
50550      PCINCR(INCPTR(NEWSTRUCT, STRUCTCONST), TEMPLATE, +INCRF);
50560      DRESSN:= NEWSTRUCT;
50570 END;
50580 (**)
50590 (**)
50600 FUNCTION GTOTN(NAK: NAKED; TEMPLATE: DPOINT): OBJECTP;
50610 (*PGETTOTAL+3*)
50620     BEGIN WITH NAK DO
50630       BEGIN
50640       GTOTN := DRESSN(POINTER, TEMPLATE);
50650       IF FPTST(STOWEDVAL^) THEN GARBAGE(STOWEDVAL);
50660       END
50670     END;
50680 (**)
50690 (**)
50700 PROCEDURE UNDRESSN (COLLECTOR, STRUCTPTR: UNDRESSP; TEMPLATE: DPOINT; SOURCEP: OBJECTP);
50710 (*ASSIGNS THE (UN)DRESSED STRUCTPTR TO THE UNDRESSED COLLECTOR; SOURCEP MAY BE GARBAGE*)
50720 BEGIN
50730     IF ORD(TEMPLATE)<=MAXSIZE THEN (*NOT STRUCT*)
50740       MOVELEFT(STRUCTPTR, COLLECTOR, ORD(TEMPLATE))
50750     ELSE (*STRUCT*)
50760       BEGIN
50770      PCINCR(STRUCTPTR, TEMPLATE, +INCRF);
50780      PCINCR(COLLECTOR, TEMPLATE, -INCRF);
50790     MOVELEFT(STRUCTPTR, COLLECTOR, TEMPLATE^[0]);
50800     IF FPTST(SOURCEP^) THEN GARBAGE(SOURCEP);
50810       END
50820 END;
50830 (**)
50840 (**)
50850 FUNCTION TASSNP(DESTINATION: OBJECTP; TEMP: NAKEGER; TEMPLATE: DPOINT): OBJECTP;
50860 (*PASSIGNTN*)
50870   VAR LSOURCE, PIL: OBJECTP;
50880       PTR: OBJECTP;
50890     BEGIN
50900     WITH TEMP, DESTINATION^ DO
50910       IF SORT IN [RECN, REFN] THEN
50920         BEGIN LSOURCE := GTOTN(NAK, TEMPLATE); LSOURCE^.PCOUNT := 1;
50930         FPDEC(PVALUE^); IF FPTST(PVALUE^) THEN GARBAGE(PVALUE);
50940         PVALUE := LSOURCE END
50950 (*CASE CAN'T HAPPEN ??
50960         CREF:
50970           BEGIN PIL := IPTR^.FIRSTPTR;
50980           FPDEC(PIL^); IF FPTST(PIL^) THEN GARBAGE(PIL);
50990           LSOURCE := GTOTN(NAK, PTR, TEMPLATE);
51000           LSOURCE^.PCOUNT := 1; IPTR^.FIRSTPTR := LSOURCE END;
51010 *)
51020       ELSE
51030         WITH ANCESTOR^ DO
51040           IF FPTWO(PVALUE^) THEN 
51050             UNDRESSN(SAFEACCESS(DESTINATION), NAK.POINTER, TEMPLATE, NAK.STOWEDVAL)
51060           ELSE
51070             BEGIN
51080             PVALUE^.OSCOPE := 0;
51090             UNDRESSN(INCPTR(PVALUE, DESTINATION^.OFFSET), NAK.POINTER, TEMPLATE, NAK.STOWEDVAL)
51100             END;
51110     TASSNP := DESTINATION;
51120     END;
51130 (**)
51140 (**)
51150 FUNCTION TASSTP(DESTINATION, SOURCE: OBJECTP): OBJECTP;
51160 (*PASSIGNTT+3*)
51170   VAR PIL: OBJECTP;
51180     BEGIN
51190     WITH DESTINATION^ DO
51200       IF SORT IN [RECN, REFN] THEN
51210         BEGIN WITH SOURCE^ DO FINC;
51220         FPDEC(PVALUE^); IF FPTST(PVALUE^) THEN GARBAGE(PVALUE);
51230         PVALUE := SOURCE;
51240         END
51250 (*CASE CAN'T HAPPEN ??
51260       ELSE IF SORT = CREF THEN
51270           BEGIN PIL := IPTR^.FIRSTPTR;
51280           FPDEC(PIL^); IF FPTST(PIL^) THEN GARBAGE(PIL);
51290           IPTR^.FIRSTPTR := SOURCE; WITH SOURCE^ DO FINC END
51300 *)
51310       ELSE
51320         WITH ANCESTOR^ DO
51330           IF FPTWO(PVALUE^) THEN 
51340             UNDRESSN(SAFEACCESS(DESTINATION), INCPTR(SOURCE, STRUCTCONST), SOURCE^.DBLOCK, SOURCE)
51350           ELSE
51360             BEGIN
51370             PVALUE^.OSCOPE := 0;
51380             UNDRESSN(INCPTR(PVALUE, DESTINATION^.OFFSET), INCPTR(SOURCE, STRUCTCONST), SOURCE^.DBLOCK, SOURCE)
51390             END;
51400     TASSTP := DESTINATION;
51410 END;
51420 (**)
51430 (**)
51440 FUNCTION SCPTNP(DESTINATION: OBJECTP; TEMP: NAKEGER; TEMPLATE: DPOINT): OBJECTP;
51450 (*PSCOPETN*)
51460     BEGIN
51470     IF DESTINATION^.OSCOPE<STRUCTSCOPE(TEMP.NAK.POINTER, TEMPLATE) THEN ERRORR(RSCOPE);
51480     SCPTNP := TASSNP(DESTINATION, TEMP, TEMPLATE);
51490     END;
51500 (**)
51510 (**)
51520 FUNCTION SCPTTP(DESTINATION, SOURCE: OBJECTP): OBJECTP;
51530 (*PSCOPETT+3*)
51540     BEGIN
51550     WITH SOURCE^ DO
51560       BEGIN
51570       IF OSCOPE=0 THEN OSCOPE := STRUCTSCOPE(INCPTR(SOURCE, STRUCTCONST), DBLOCK);
51580       IF DESTINATION^.OSCOPE<OSCOPE THEN ERRORR(RSCOPE);
51590       END;
51600     SCPTTP := TASSTP(DESTINATION, SOURCE);
51610     END;
51620 (**)
51630 (**)
51640 FUNCTION DREFN(REFER: OBJECTP): OBJECTP;
51650 (*PDEREF+3*)
51660     BEGIN
51670     WITH REFER^ DO
51680       BEGIN
51690       CASE SORT OF
51700         RECN, REFN:
51710           BEGIN DREFN :=PVALUE; WITH PVALUE^ DO FINC END;
51720         CREF: DREFN := IPTR^.FIRSTPTR;
51730         REFSL1: DREFN :=DRESSN(INCPTR(ANCESTOR^.PVALUE, OFFSET), DBLOCK);
51740         UNDEF: ERRORR(RDEREF);
51750         NILL: ERRORR(RDEREFNIL);
51760       END;
51770       IF FPTST(REFER^) THEN GARBAGE(REFER);
51780       IF SORT IN [RECN,REFN] THEN WITH PVALUE^ DO FDEC
51790       END
51800     END;
51810 (**)
51820 (**)
51830 (*-02()
51840   BEGIN
51850   END;
51860 ()-02*)
51870 (*+01()
51880 BEGIN (*OF MAIN PROGRAM*)
51890 END  (*OF EVERYTHING*).
51900 ()+01*)
