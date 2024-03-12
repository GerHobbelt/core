/* encoding: cp850 */

#pragma DebugInfo=On

/*
* No Harbour, foi preciso criar nova classe, herdada da TBrowse(), 
* para poder acessar informa��es do objeto TBrowse() necess�rias � CUA.
*  
* A forma geral foi (no Harbour somente):
*    - Criar subclasse da classe TBrowse()
*    - Criar novos m�todos nesta subclasse, que podem enxergar as
*      vari�veis de inst�ncia privadas da TBrowse() e retorn�-las.
*    - Usar esta subclasse na CUA, e n�o a TBrowse() padr�o
*/

* 
* Esta subclasse teve de ser criado porque, no Harbour, 
* as colunas inicial e final do Browse() n�o s�o limpas corretamente ap�s rolamento horizontal,
* caso a largura das colunas siga um padr�o espec�fico (este padr�o que causa o problema 
* existe programado no programa exemplo da CUA).
*
* A origem deste bug � o fato da TBrowse() usar a DispBox() / HB_DispBox(),
* a qual tem um BUG, seja na GTWIN ou na GTWVW. A TBrowse() usar esta rotina para
* "limpar" a �rea da coluna, e a limpeza n�o ocorre corretamente (vide "z:\f\cua\demo_dispbox.prg").
* 
#include "hbclass.ch"
*
CREATE CLASS TBrowseSubClass FROM TBrowse
   METHOD aColumnsSep
   METHOD LimparColunasInicialFinal_do_BugDispBox
   METHOD dispRow( nRow )
END CLASS

* 1) "aColumnSep" (separador de colunas)
*
*    No Harbour, foi preciso criar manualmente o m�todo "aColumnsSep()",
*    com retorno equivalente.
*
*    Foi preciso fazer esta forma porque a vari�vel de inst�ncia "aColData" 
*    do Harbour � "protected", n�o sendo poss�vel acess�-la de fora do
*    c�digo da classe.
*
* Copiado do tbrowse.prg do Harbour
#define _TBC_CLR_STANDARD     1

#define _TBCI_COLWIDTH        2   // width fo the column
#define _TBCI_COLPOS          3   // column position on screen
#define _TBCI_CELLPOS         5   // cell position in column
#define _TBCI_COLSEP          6   // column separator
#define _TBCI_SEPWIDTH        7   // width of the separator
#define _TBCI_FROZENSPACE    13   // space after frozen columns
#define _TBCI_LASTSPACE      14   // space after last visible column

****************************************
METHOD aColumnsSep CLASS TBrowseSubClass
****************************************
LOCAL N_CT, aColumnsSep := {}
LOCAL aColData, nColumnSepPos
LOCAL L_FirstViewedColumn := .T.
*
FOR N_CT := 1 to LEN(::aColData)
    aColData := ::aColData[N_CT]
    nColumnSepPos := aColData[_TBCI_COLPOS]
    *
    IF nColumnSepPos == NIL
       * Column is not displayed right now
    ELSE
       IF L_FirstViewedColumn
          L_FirstViewedColumn := .F. 
          * There is not separator before first column
       ELSE
          AADD(aColumnsSep,nColumnSepPos)
       ENDIF 
    ENDIF
NEXT
*
RETURN aColumnsSep
*
* 2) Coluna inicial e final do Browse() n�o limpo corretamente ap�s rolamento horizontal.
*
*    A DispBox() / HB_DispBox() da GTWVW tem bug quando a linha inicial � igual
*    � linha final, detalhadamente descrita no fonte demo_dispbox.prg.
*
*    O TBrowse() do Harbour usar a DispBox() / HB_DispBox() para limpar colunas.
*    Isto causa a n�o limpeza de colunas do Tbrowse(), aparentemente sempre a coluna inicial e final.
*
*    A solu��o para este problema ser� limpar "na m�o", ap�s a estabiliza��o da janela, e quanto tiver
*    tido rolamento horizontal. Somente deve ser limpos se n�o tiver conte�do efetivo na posi��o.
*
*********************************************************************************
METHOD LimparColunasInicialFinal_do_BugDispBox (L_MostraGrade) CLASS TBrowseSubClass
*********************************************************************************
LOCAL N_CT
LOCAL aColData, nColumnSepPos, nWidth
LOCAL L_PrimeiraColunaSemDados := .T.
LOCAL L_UltimaColunaSemDados   := .T.
LOCAL N_Cursor_Row := ROW(), N_Cursor_Col := COL()
LOCAL C_SetColor_Ant := SETCOLOR()
*
FOR N_CT := 1 to LEN(::aColData)
    aColData := ::aColData[N_CT]
    nColumnSepPos := aColData[_TBCI_COLPOS]  
    nWidth        := aColData[_TBCI_COLWIDTH]
    *
    IF nColumnSepPos == NIL
       * Column is not displayed right now
    ELSE
       IF nColumnSepPos == ::nLeft
          * Tem coluna que inicia exatamente na coluna inicial do TBrowse()
          L_PrimeiraColunaSemDados := .F.
       ENDIF   
       IF nColumnSepPos+nWidth == ::nRight
          * Tem coluna que termina exatamente na coluna final do TBrowse()
          L_UltimaColunaSemDados := .F.
       ENDIF   
    ENDIF
NEXT
*
IF L_PrimeiraColunaSemDados
   * Limpar manualmente eventual "sujeira" deixada pela HB_DispBox / DispBox()
   * na coluna inicial. Neste caso, a DispBox() n�o exibir� BUG pois � coluna vertical.
   IF L_MostraGrade
      SETCOLOR("N+/W*,N/W*,N/BG*")
   ENDIF   
   @ ::nTop,::nLeft CLEAR TO ::nBottom,::nLeft
   SETCOLOR(C_SetColor_Ant)
   SETPOS(N_Cursor_Row,N_Cursor_Col)
ENDIF
*
IF L_UltimaColunaSemDados
   * Limpar manualmente eventual "sujeira" deixada pela HB_DispBox / DispBox()
   * na coluna final. Neste caso, a DispBox() n�o exibir� BUG pois � coluna vertical.
   IF L_MostraGrade
      SETCOLOR("N+/W*,N/W*,N/BG*")
   ENDIF   
   @ ::nTop,::nRight CLEAR TO ::nBottom,::nRight
   SETCOLOR(C_SetColor_Ant)
   SETPOS(N_Cursor_Row,N_Cursor_Col)
ENDIF
*
RETURN NIL
*
* 3) Da primeira � quarta posi��o (da segunda coluna em diante) sendo limpo indevidamente.
*
*    A hb_DispOutAtBox() da GTWVW tem bug QUE N�O OCORRE SEMPRE, que imprime o 
*    conte�do do separador de coluna deslocado de 1 a 4 posi��es � frente.
*    
*    O mais estranho � que isto ocorre em uma linhas e noutras n�o, mudando-se
*    APENAS o n�mero da linha que est� sendo impresso !
*
*    Foi feito extenso debug da tbrowse.prg e visto que os par�metros passados � 
*    hb_DispOutAtBox() est�o CORRETOS, n�o sendo provavelmente um problema da TBrowse()
*    em si. Inclusive a WVW_PAINT() foi desativada, para ter certeza que n�o era problema
*    em alguma rotina de "callback".
*
*    Vide o programa exemplo\demo_dispoutatbox.prg para maiores informa��es.
*    Vide o programa exemplo\demo_dispoutatbox_1.png para exemplo do problema deslocando 1 posi��o.
*    Vide o programa exemplo\demo_dispoutatbox_4.png para exemplo do problema deslocando 4 posi��es.
*
*    A solu��o para este problema fazer o "overwrite" do m�todo, de forma
*    a usar a hb_DispOutAt(), quando rodando sob a GTWVW !
*    O m�todo abaixo foi um copiar/colar no fonte do Harbour liberado no GIT
*    em 16/03/2018 !  
*
*    ATEN��O: Toda vez que fizer um novo BUILD do compilador, fazer este  
*             copiar/colar novamamente !
*
********************************************
METHOD dispRow( nRow ) CLASS TBrowseSubClass     // Method overloading !
********************************************

   LOCAL nRowPos, nColPos
   LOCAL aCol
   LOCAL lFirst
   LOCAL cValue, cColor, cStdColor
   LOCAL aColors

   IF nRow >= 1 .AND. nRow <= ::rowCount

      DispBegin()

      nRowPos := ::n_Top + ::nHeadHeight + iif( ::lHeadSep, 1, 0 ) + nRow - 1
      cStdColor := ::colorValue( _TBC_CLR_STANDARD )

      hb_DispBox( nRowPos, ::n_Left, nRowPos, ::n_Right, Space( 9 ), cStdColor )

      lFirst := .T.
      FOR EACH aCol, cValue, aColors IN ::aColData, ::aCellValues[ nRow ], ::aCellColors[ nRow ]
         IF aCol[ _TBCI_COLPOS ] != NIL
            nColPos := aCol[ _TBCI_COLPOS ]
            IF lFirst
               lFirst := .F.
            ELSEIF aCol[ _TBCI_SEPWIDTH ] > 0
            
               //!! In�cio do ajuste feito pela Aspec
               IF HB_GTVERSION()=="WVW"
                  hb_DispOutAt( nRowPos, aCol[ _TBCI_COLPOS ] - aCol[ _TBCI_FROZENSPACE ], ;
                                aCol[ _TBCI_COLSEP ], cStdColor )
               ELSE
                  hb_DispOutAtBox( nRowPos, aCol[ _TBCI_COLPOS ] - aCol[ _TBCI_FROZENSPACE ], ;
                                   aCol[ _TBCI_COLSEP ], cStdColor )
               ENDIF                 
               //!! Fim do ajuste feito pela Aspec
               
               nColPos += aCol[ _TBCI_SEPWIDTH ]
            ENDIF
            nColPos += aCol[ _TBCI_CELLPOS ]
            cColor := ::colorValue( aColors[ _TBC_CLR_STANDARD ] )
            IF aCol[ _TBCI_LASTSPACE ] < 0
               hb_DispOutAt( nRowPos, nColPos, ;
                             Left( cValue, ::n_Right - nColPos + 1 ), cColor )
            ELSE
#ifdef HB_CLP_STRICT
               hb_DispOutAt( nRowPos, nColPos, ;
                             Left( cValue, aCol[ _TBCI_COLWIDTH ] - aCol[ _TBCI_CELLPOS ] ), cColor )
#else
               hb_DispOutAt( nRowPos, nColPos, cValue, cColor )
#endif
            ENDIF
         ENDIF
      NEXT

      ::aDispStatus[ nRow ] := .F.

      DispEnd()
   ENDIF

   RETURN Self
*
***********************************************
