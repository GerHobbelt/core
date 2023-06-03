/* encoding: cp850 */

#pragma DebugInfo=On

* Rotina para edi��o/exibi��o de textos em mem�ria no  padr�o SAA/CUA
*
* Autor: Marcos Augusto   Data: 28/12/91
*
* NOTA 1: Esta fun��o utiliza-se de vari�veis da classe MEMVAR em virtude das
*         mesmas serem utilizadas na fun��o de configura��o da MEMOEDIT(), n�o
*         podendo serem passadas como par�metros formais
*/

#INCLUDE "inkey.ch"
#INCLUDE "common.ch"
#INCLUDE "setcurs.ch"
#INCLUDE "define_cua.ch"
#INCLUDE "janela.ch"
#INCLUDE "gtnap.ch"

MEMVAR L_ReadInsert_Ativado_Automaticamente
MEMVAR L_Converter_Tecla_ANSI_para_OEM
*
*****************
FUNCTION EspTexto ( VX_Janela, B_Texto, VN_TeclaGravar, N_TamLinha,;
                    N_Tab, B_Valid, B_Edita, B_Confirma, B_Desiste,;
                    B_FiltroTec,L_NaoRolaVertical, L_RolaHorizontal,;
                    L_SemToolBar  )
*
DEFAULT L_NaoRolaVertical TO .F.
DEFAULT L_RolaHorizontal  TO .F.
DEFAULT L_SemToolBar      TO .F.
*
NAP_LOG("EspTexto -- 1")

IF .NOT. L_SemToolBar
   SETA_PARA_TER_TOOLBAR(VX_Janela) // ajusta N_LinIni e N_LinLivre
ENDIF
*
AJUSTA_BOTOES(VX_Janela)  // ajusta Lin2Livre � quantidade de bot�es de fun��o
*
IF .NOT. L_NaoRolaVertical
   * prever espa�o para scroll bar vertical
   Col2Livre(VX_Janela)--
   Col2Livre(VX_Janela)--
   L_ScrollVertical := .T.
ELSE
   ? MEMVAR->NAO_IMPLEMENTADO    // nao implementado ainda - falar com Marcos
ENDIF
*
IF L_RolaHorizontal
   ? MEMVAR->NAO_IMPLEMENTADO    // nao implementado ainda - falar com Marcos
   * prever espa�o para scroll bar horizontal
   Lin2Livre(VX_Janela)--
   Lin2Livre(VX_Janela)--
   L_ScrollHorizontal := .T.
ENDIF
*
DEFAULT VN_TeclaGravar TO {}
DEFAULT N_TamLinha     TO Col2Livre(VX_Janela) - Col1Livre(VX_Janela)
DEFAULT N_Tab          TO 4
DEFAULT B_Valid        TO {||.T.}
DEFAULT B_Edita        TO {||.T.}
DEFAULT B_Confirma     TO {||.T.}
DEFAULT B_Desiste      TO {||.T.}
DEFAULT B_FiltroTec    TO {||ACENTUA()}
*
IF EVAL(B_Edita)
   B_Edita := INABILITA_EDICAO_TEXTO()
ENDIF
*
#DEFINE   N_Linha     1
#DEFINE   N_Coluna    0
#DEFINE   N_LinhaRel  0       // linha relativa
#DEFINE   N_ColunaRel 0
#DEFINE   L_PrimAtivacao .T.    // indica que � primeira ativa��o da janela
*
N_TP_Jan  := _JAN_TEXTO_10
VX_SubObj := { B_Texto, VN_TeclaGravar, N_TamLinha, N_Tab, N_Linha, N_Coluna,;
               N_LinhaRel, N_ColunaRel, B_Valid, B_Edita,;
               B_Confirma, B_Desiste, B_FiltroTec, L_PrimAtivacao,;
                L_NaoRolaVertical, L_RolaHorizontal }
B_Metodo  := {||Texto(VX_Janela)}
*
#UNDEF   N_Linha
#UNDEF   N_Coluna
#UNDEF   N_LinhaRel
#UNDEF   N_ColunaRel
#UNDEF   L_PrimAtivacao
*
RETURN NIL
*
*
*********************
STATIC FUNCTION Texto
*
LOCAL L_ScorAnt, N_Tab , N_CursorAnt, L_Finaliza
LOCAL C_CorAnt, N_RowAnt, N_ColAnt
*
PARAMETERS VX_Janela
LOCAL N_TextId
LOCAL N_Cont
LOCAL X_Retorno

PRIVATE N_CtInic, N_TotLinhas, N_Tecla_Ant := 0
PRIVATE C_Texto, C_Texto_Original  // para permitir o "undo"
PRIVATE L_FimOK := .F.  // Informa se edi��o do texto terminou com sucesso
PRIVATE C_AcaoForaDaMemoEdit := ""  // A��o que deve ser executada fora da MEMOEDIT(), e em seguida voltar para a MEMOEDIT()
PRIVATE L_ReadInsert_Ativado_Automaticamente := .F.
*

#DEFINE B_Texto        MEMVAR->VX_SubObj[01]
#DEFINE VN_TeclaGravar MEMVAR->VX_SubObj[02]
#DEFINE N_TamLinha     MEMVAR->VX_SubObj[03]
#DEFINE N_Tab          MEMVAR->VX_SubObj[04]
#DEFINE N_Linha        MEMVAR->VX_SubObj[05]
#DEFINE N_LinhaRel     MEMVAR->VX_SubObj[06]
#DEFINE N_Coluna       MEMVAR->VX_SubObj[07]
#DEFINE N_ColunaRel    MEMVAR->VX_SubObj[08]
#DEFINE B_Valid        MEMVAR->VX_SubObj[09]
#DEFINE B_Edita        MEMVAR->VX_SubObj[10]
#DEFINE B_Confirma     MEMVAR->VX_SubObj[11]
#DEFINE B_Desiste      MEMVAR->VX_SubObj[12]
#DEFINE B_FiltroTec    MEMVAR->VX_SubObj[13]
#DEFINE L_PrimAtivacao MEMVAR->VX_SubObj[14]
#DEFINE L_NaoRolaVertical MEMVAR->VX_SubObj[15]
#DEFINE L_RolaHorizontal MEMVAR->VX_SubObj[16]

*
IF EVAL(B_Edita)
   * Como a memoedit do Harbour � cheia de bugs, evitar a todo custo
   * existir rolamento horizontal em vari�vel memo (d� problema no Harbour...).
   IF N_TamLinha > Col2Livre(VX_Janela) - Col1Livre(VX_Janela)
      * causar erro, para que o programa seja corrigido
      ? MEMVAR->TAMLINHA
   ENDIF
ENDIF

IF SOB_MODO_GRAFICO()

    IF L_PrimAtivacao

        // Set window global functions
        NAP_WINDOW_EDITABLE(N_WindowNum, B_Edita)
        NAP_WINDOW_CONFIRM(N_WindowNum, B_Confirma)
        NAP_WINDOW_DESIST(N_WindowNum, B_Desiste)

        // Create the textview
        N_TextId := NAP_TEXTVIEW(N_WindowNum, Lin1Livre(VX_Janela), Col1Livre(VX_Janela), Lin2Livre(VX_Janela), Col2Livre(VX_Janela), B_Texto, B_Valid, .F.)
        // Show/hide scrollbars
        NAP_TEXTVIEW_SCROLL(N_WindowNum, N_TextId, L_RolaHorizontal, IIF(L_NaoRolaVertical==.F.,.T.,.F.))
        // Set the caret at position 0 (beginning)
        NAP_TEXTVIEW_CARET(N_WindowNum, N_TextId, 0)

        // Set "end editing" buttons
        FOR N_Cont := 1 TO LEN(V_RegiaoBotoes)
            NAP_TEXTVIEW_BUTTON(N_WindowNum, N_TextId, V_RegiaoBotoes[N_Cont,_BOTAO_HANDLE_PUSHBUTTON])
        NEXT

        // Set "end editing" hotkeys
        FOR N_Cont := 1 TO LEN(VN_TeclaGravar)
            NAP_TEXTVIEW_HOTKEY(N_WindowNum, N_TextId, VN_TeclaGravar[N_Cont])
        NEXT

        L_PrimAtivacao := .F.
    ENDIF

    IF .NOT. L_Embutida
        X_Retorno := NAP_WINDOW_MODAL(N_WindowNum)
        IF X_Retorno == NAP_MODAL_TEXT_CONFIRM
            L_FimOK := .T.
        ELSEIF X_Retorno == NAP_MODAL_ESC .OR. X_Retorno == NAP_MODAL_X_BUTTON
            L_FimOK := .F.
        ELSE
            ? MEMVAR->ERR_NAP_MODAL_RETURN
        ENDIF
    ELSE
        L_FimOK := .T.
    ENDIF

ELSE   // NOT SOB_MODO_GRAFICO

C_Texto     := EVAL(B_Texto)
C_Texto_Original := C_Texto

L_ScorAnt   := SET(_SET_SCOREBOARD,.F.)
N_CursorAnt := SET(_SET_CURSOR)
*
N_TotLinhas := MLCOUNT(C_Texto,N_TamLinha,N_Tab)
N_CtInic := 1
*
IF EVAL(B_Edita)
   SET(_SET_CURSOR,IIF(READINSERT(),SC_INSERT,SC_NORMAL))  // escolher tipo
ELSE
   SET(_SET_CURSOR,SC_NONE)           // n�o tem cursor
ENDIF
*
EXTERNAL _CuaTexto_     && declara que esta fun��o � usada nesta procedure
*
*
L_Finaliza := .F.
DO WHILE .NOT. L_Finaliza
   * a vari�vel C_Texto sempre ser� atualizada
   *
   C_CorAnt := SETCOLOR()

   // FRAN: NEVER SOB_MODO_GRAFICO  here
//    IF SOB_MODO_GRAFICO()
//       SETCOLOR("N/W*")   // letra preta com fundo branco
//    ENDIF
   *
   * Em qual p�gina de c�digo vem a tecla

   // FRAN: REVIEW
   IF Version()=="Harbour 3.2.0dev (r1703241902)"
      * J� vem na PC850
      L_Converter_Tecla_ANSI_para_OEM := .F.
   ELSEIF Version()=="Harbour 3.2.0dev (r2011030937)" .OR. Version()=="Harbour 3.2.0dev (r1704061005)" // PENDENTE_LINUX
      * J� vem na WIN1252
      L_Converter_Tecla_ANSI_para_OEM := .T.
   ELSE
      L_Converter_Tecla_ANSI_para_OEM := .T.
   ENDIF //ERRO
   *
   C_Texto := MEMOEDIT(C_Texto,Lin1Livre(MEMVAR->VX_Janela),;
                               Col1Livre(MEMVAR->VX_Janela),;
                               Lin2Livre(MEMVAR->VX_Janela),;
                               Col2Livre(MEMVAR->VX_Janela),EVAL(B_Edita),;
                               "_CuaTexto_",N_TamLinha,N_Tab,;
                               N_Linha,N_Coluna,N_LinhaRel,N_ColunaRel)
   *
   SETCOLOR(C_CorAnt)
   *
   IF .NOT. EMPTY(C_AcaoForaDaMemoEdit)
      * MEMOEDIT() foi encerrada automaticamente, pelo pr�prio sistema, com �nico objetivo
      * de atualizar o conte�do da v�ri�vel C_Texto, permitindo realizar as a��es necessitam
      * ter acesso ao conte�do atualizado do texto.
      *
      IF C_AcaoForaDaMemoEdit=="copiar_via_teclado" .OR. ;
         C_AcaoForaDaMemoEdit=="copiar_via_toolbar"
         * No xHarbour 1.2.1, existe:
         *       - marca��o parcial do texto, suportada diretamente pela MEMOEDIT()
         *       - o texto marcado vai diretamente para ClipBoard do Windows
         * Mas no Harbour n�o existe isto, nem se tem acesso direto ao texto sendo editado.
         *
         * Para resolver esta incompatibilidade, que apareceu no momento de adapta��o ao Harbour,
         * resolveu-se desativar a op��o de c�pia "s� do que foi marcado",
         * existindo sempre uma sobreposi��o do ClipBoard com todo o texto editado.
         SETCLIPBOARD_ASPEC(ALLTRIM(C_Texto))
      ELSEIF C_AcaoForaDaMemoEdit=="colar_via_teclado" .OR. ;
             C_AcaoForaDaMemoEdit=="colar_via_toolbar"
         IF EVAL(B_Edita)
            * Tentar inserir o texto do ClipBoard "dentro" do texto a ser editado.
            IF .NOT. EMPTY(GETCLIPBOARD_ASPEC())
               *
               * No Harbour, o colar via teclado e via toolbar deve ser tratamento via programa��o.
               * O comportamento �:
               *    A rotina leva em considera��o se est� no "modo de inser��o" ou
               *    "modo de sobreposi��o", conforme esperado.
               *    Ajustar para o colar sempre ser feito no "modo de inser��o",
               *    para minimizar possibilidade de perda de dados.
               IF READINSERT()  // "modo de inser��o" est� ativo
                   IF Version()=="Harbour 3.2.0dev (r1703241902)"
                      KEYBOARD GETCLIPBOARD_ASPEC()
                   ELSEIF Version()=="Harbour 3.2.0dev (r2011030937)" .OR. Version()=="Harbour 3.2.0dev (r1704061005)" // ADAPTACAO_LINUX
                      * Em uma sequencia de carecteres, caso o �ltimo seja um caractere acentuado,
                      * o conjunto de comandos da linha abaixo n�o apresentando o caractere correto.
                      * Huove a necessidade de incluir um caractera a mais no final e foi escolhido o "BRNACO".
                      KEYBOARD GETCLIPBOARD_ASPEC() + CHR(32)
                   ENDIF
               ELSE             // "modo de sobreposi��o" est� ativo
                  * Neste ponto, no Harbour o texto estava sendo colado dezenas de vezes
                  * enquanto se segurasse a tecla "Control" pressionada. O motivo � que,
                  * por azar, o c�digo do K_CTRL_V � exatamente o mesmo do K_INS.
                  * Ao tentar ativar o modo de insert colocando no teclado CHR(K_INS),
                  * isto � interpretado como sendo um novo colar K_CTRL_V.
                  //KEYBOARD CHR(K_INS)+GETCLIPBOARD_ASPEC()+CHR(K_INS)
                  *
                  * A solu��o foi ativar o "modo de inser��o" via rotina READINSERT(.T.),
                  * colocar no teclado somente o texto a colar, e
                  * setar vari�vel para indicar que o "modo de inser��o" deve
                  * ser desativado automaticamente dentro da MemoEdit(), ap�s
                  * o texto colocado no teclado ter sido "consumido".
                  READINSERT(.T.)
                  IF Version()=="Harbour 3.2.0dev (r1703241902)"
                     KEYBOARD GETCLIPBOARD_ASPEC()
                  ELSEIF Version()=="Harbour 3.2.0dev (r2011030937)" .OR. Version()=="Harbour 3.2.0dev (r1704061005)" // ADAPTACAO_LINUX
                     * Em uma sequencia de carecteres, caso o �ltimo seja um caractere acentuado,
                     * o conjunto de comandos da linha abaixo n�o apresentando o caractere correto.
                     * Huove a necessidade de incluir um caractera a mais no final e foi escolhido o "BRNACO".
                     KEYBOARD GETCLIPBOARD_ASPEC() + CHR(32)
                  ENDIF
                  *
                  L_ReadInsert_Ativado_Automaticamente := .T.
               ENDIF
            ENDIF
         ENDIF
      ELSEIF C_AcaoForaDaMemoEdit=="recortar_via_teclado" .OR. ;
             C_AcaoForaDaMemoEdit=="recortar_via_toolbar"
         * No xHarbour 1.2.1, existe:
         *       - marca��o parcial do texto, suportada diretamente pela MEMOEDIT()
         *       - o texto marcado vai diretamente para ClipBoard do Windows
         * Mas no Harbour n�o existe isto, nem se tem acesso direto ao texto sendo editado.
         *
         * Para resolver esta incompatibilidade, que apareceu no momento de adapta��o ao Harbour,
         * resolveu-se desativar a op��o de recortar "s� do que foi marcado",
         * existindo sempre uma sobreposi��o do ClipBoard com todo o texto editado.
         SETCLIPBOARD_ASPEC(ALLTRIM(C_Texto))
         *
         IF EVAL(B_Edita)
            C_Texto := ""
         ENDIF
      ELSEIF C_AcaoForaDaMemoEdit=="undo_via_teclado" .OR. ;
             C_AcaoForaDaMemoEdit=="undo_via_toolbar"
         IF EVAL(B_Edita)
            C_Texto := C_Texto_Original  // texto original na in�cio da ativacao da janela de edi��o
         ENDIF
      ENDIF ERRO
      *
      C_AcaoForaDaMemoEdit := ""
   ELSE
      * MEMOEDIT() foi encerrada "pra valer", pelo usu�rio final.
      *
      EVAL(B_Texto,C_Texto)    // atualiza a c�pia do texto contido no objeto VX_Janela, para possibilitar a cr�tica (VALID()).
      *
      N_RowAnt := ROW()
      N_ColAnt := COL()
      IF .NOT. L_FimOK
         IF EVAL(B_Desiste)
            L_Finaliza := .T.
         ENDIF
      ELSE
         IF EVAL(B_Valid)     // se cr�tica OK, pedir confirma��o
            L_Finaliza := EVAL(B_Confirma)
         ENDIF
      ENDIF
      SETPOS(N_RowAnt,N_ColAnt)
   ENDIF
   *
ENDDO
*
SET(_SET_SCOREBOARD,L_ScorAnt)
SET(_SET_CURSOR,N_CursorAnt)
*
IF L_PrimAtivacao
   LOGA_AJTELAT(C_CdTela,C_Cabec,NIL)  // LOGAR conte�do de telas
ENDIF
*
L_PrimAtivacao := .F.

ENDIF // IF SOB_MODO_GRAFICO()

RETURN L_FimOK

*******************
FUNCTION _CuaTexto_ ( N_Modo , N_Lin , N_Col, O_Edicao )     // n�o pode ser est�tica
*
#INCLUDE "memoedit.ch"
*
LOCAL N_Retorno , N_Tecla, L_MontarRolamento, N_SEGUNDOS, N_TIMEOUT
LOCAL C_CorAnt
LOCAL N_mRow, N_mCol, N_RegiaoMouse
LOCAL N_Keyboard
LOCAL N_Desloca_Vertical, N_Desloca_Horizontal, C_BufferTeclado
LOCAL C_String, L_PodeExecutar
MEMVAR C_Texto, N_CtInic, N_TotLinhas, N_Tecla_Ant
MEMVAR L_FimOK, C_AcaoForaDaMemoEdit
*
* Voltar a cor normal da janela, que foi mudada pela WVW
C_CorAnt := SETCOLOR(CorJanela(MEMVAR->VX_Janela))
*
L_MontarRolamento := .T.   // indica se deve ser montado o indicativo de rolamento
*
N_Retorno := 0
*
IF N_Modo == ME_INIT
   *
   * No Harbour, � necess�rio usar este comando para ativar o SCROLL
   IF N_CtInic == 1 .AND. .NOT. EVAL(B_Edita)
      N_Retorno := ME_TOGGLESCROLL
   ENDIF
   *
   N_CtInic := N_CtInic + 1
   *
   * posicionar o cursor na primeira posi��o livre do BOX
   *   ( necess�rio para que a 1� impress�o de rolamento seja correta )
   *
   SETPOS(Lin1Livre(MEMVAR->VX_Janela),Col1Livre(MEMVAR->VX_Janela))
   *
ELSE
   *
   N_Linha      := N_Lin
   N_LinhaRel   := ROW() - Lin1Livre(MEMVAR->VX_Janela)
   N_Coluna     := N_Col
   N_ColunaRel  := COL() - Col1Livre(MEMVAR->VX_Janela)
   *
   N_Tecla := LASTKEY()
   *
   * Em qual p�gina de c�digo vem a tecla
   IF Version()=="Harbour 3.2.0dev (r1703241902)"
      * J� vem na PC850
   ELSEIF Version()=="Harbour 3.2.0dev (r2011030937)" .OR. Version()=="Harbour 3.2.0dev (r1704061005)" // PENDENTE_LINUX

    // FRAN NEVER     SOB_MODO_GRAFICO here
    //   IF SOB_MODO_GRAFICO()
    //      * Vem na ANSI.
    //      IF N_Tecla >= 128 .AND. N_Tecla <= 255  // Faixa diferente entre ANSI e OEM
    //         *
    //         IF L_Converter_Tecla_ANSI_para_OEM
    //            * Ao passar aqui, est� sendo processada a tecla original ANSI,
    //            * que ser� substituida pela tecla OEM,
    //            * devendo ser desativada a convers�o de ANSI para OEM.
    //            L_Converter_Tecla_ANSI_para_OEM := .F.
    //            *
    //            * A tecla digitada, por estar na p�gina de c�digo ANSI (e n�o OEM)
    //            * ser� exibida errada na MEMOEDIT().
    //            *
    //            * Colocar no "buffer" do teclado a tecla equivalente na p�gina de c�digo OEM:
    //            KEYBOARD IIF(SET(_SET_INSERT),CHR(K_BS),CHR(K_LEFT))+;  // Apaga a caractere errado (ANSI)
    //                         HB_ANSItoOEM(CHR(N_Tecla))  // Coloca o caracte certo (OEM), tamb�m entre 128 e 255
    //            *
    //            * Documenta��o de tentativa que n�o funcionou:
    //            * ============================================
    //            * Tentou-se simplemente descartar a tecla do ANSI e colocar
    //            * no teclado a tecla OEM, mas n�o funcionou, pois a MEMOEDIT()
    //            * n�o aceita "descartar" teclas comuns.
    //            *    N_Retorno := ME_IGNORE   // ignorar a tecla ANSI (atual)
    //            *    KEYBOARD HB_ANSItoOEM(CHR(N_Tecla))  // Acrescentar a tecla OEM (futura), tamb�m entre 128 e 255
    //            *
    //         ELSE
    //            * Ao passar aqui, est� sendo processada a tecla j� convertida para OEM,
    //            * que foi colocada no "buffer" do teclado,
    //            * devendo ser reativada a convers�o de ANSI para OEM.
    //            L_Converter_Tecla_ANSI_para_OEM := .T.
    //         ENDIF
    //         *
    //         * Documenta��o de tentativa que n�o funcionou:
    //         * ============================================
    //         * Tentou-se simplemente converter a tecla do ANSI para OEM,
    //         * mudar o LasstKey() e e instruir a MEMOREAD() a considerar a nova tecla.
    //         * Mas a MEMOREAD() n�o funciona assim, pois teclas comuns n�o podem ser
    //         * "trocadas" via retorno da fun��o (N_Retorno).
    //         *    N_Tecla := ASC(HB_ANSItoOEM(CHR(N_Tecla)))
    //         *    hb_SetLastKey(N_Tecla)
    //         *    N_Retorno := N_Tecla // Trocar a tecla a ser considerada pela MEMOEDIT()
    //         *
    //      ENDIF
    //   ELSE
    //      * J� vem na PC850
    //   ENDIF
   ENDIF //ERRO
   *
   * Teclas combinadas precisam de tratamento especial de "desempate" (ex: CTRL-C).
   N_Tecla := AjustaTecla(N_Tecla)
   *
   DO CASE
      CASE N_Tecla == K_CTRL_END .OR. ;
           N_Tecla == K_CTRL_W_ARBITRADO_TECLADO
           * N�o d� para diferenciar entre o uso da K_CTRL_END e da K_CTRL_W,
           * pois ambas exigem que se pressione a tecla "Ctrl".
           N_Retorno := ME_IGNORE        // desativando tecla
      CASE N_Tecla == K_ESC
           * ATEN��O: Vari�vel � SEMPRE atualizada, mesmo quando se tecla K_ESC
           L_FimOK   := .F.
           N_Retorno := K_CTRL_W       // sempre salva ao terminar
      CASE N_Tecla   == K_CTRL_C_ARBITRADO_TECLADO  // Copiar - N�o d� certo usar a K_CTRL_C diretamente
           * Quando o usu�rio teclar CTRL-C, sair da MEMOEDIT() silenciosamente
           * fazer o colar "l� fora", para se ter acesso ao conte�do atualizado do texto.
           * Em seguida, chamar automaticamente a MEMOEDIT() novamente, para continuar edi��o.
           C_AcaoForaDaMemoEdit := "copiar_via_teclado"
           *
           * ATEN��O: O c�digo abaixo seguiu o padr�o normal da MEMOEDIT(),
           *          tentando "trocar" a tecla K_CTRL_C_ARBITRADO_TECLADO pela K_CTRL_W,
           *          de forma a ENCERRAR, mesmo que tempor�riamente, a MEMOEDIT().
           *          Mas isto N�O funcionou neste trecho do c�digo, muito embora
           *          exatamente o mesmo c�digo funciona em outros locais desta MESMA rotina.
           *          Acho que o CTRL-C � tecla cujo conte�do n�o pode ser reconfigurado pela
           *          fun��o do usu�rio.
           *          A sa�da foi sair da MEMOEDIT() na MARRA, atrav�s de um HB_KeyPut().
           /*
           C�DIGO QUE N�O FUNCIONOU !
           N_Retorno := K_CTRL_W       // sempre salva ao terminar
           */
           HB_KeyPut(K_ESC) // Mesmo colocando K_ESC no teclado, mas conte�do da vari�vel � ATUALIZADO !
           *
      CASE N_Tecla   == K_CTRL_C_ARBITRADO_TOOLBAR  // Copiar - N�o d� certo usar a K_CTRL_C diretamente
           * Vide coment�rio extenso mais acima !
           C_AcaoForaDaMemoEdit := "copiar_via_toolbar"
           *
           HB_KeyPut(K_ESC) // Mesmo colocando K_ESC no teclado, mas conte�do da vari�vel � ATUALIZADO !
           *
      CASE N_Tecla   == K_CTRL_X_ARBITRADO_TECLADO  // Recortar - N�o d� certo usar a K_CTRL_X diretamente
           * Vide coment�rio extenso mais acima !
           C_AcaoForaDaMemoEdit := "recortar_via_teclado"
           *
           HB_KeyPut(K_ESC) // Mesmo colocando K_ESC no teclado, mas conte�do da vari�vel � ATUALIZADO !
           *
      CASE N_Tecla   == K_CTRL_X_ARBITRADO_TOOLBAR  // Recortar - N�o d� certo usar a K_CTRL_X diretamente
           * Vide coment�rio extenso mais acima !
           C_AcaoForaDaMemoEdit := "recortar_via_toolbar"
           *
           HB_KeyPut(K_ESC) // Mesmo colocando K_ESC no teclado, mas conte�do da vari�vel � ATUALIZADO !
           *
      CASE N_Tecla   == K_CTRL_V_ARBITRADO_TECLADO   // Colar - N�o d� certo usar a K_CTRL_V diretamente
           * Vide coment�rio extenso mais acima !
           C_AcaoForaDaMemoEdit := "colar_via_teclado"
           *
           HB_KeyPut(K_ESC) // Mesmo colocando K_ESC no teclado, mas conte�do da vari�vel � ATUALIZADO !
           *
      CASE N_Tecla   == K_CTRL_V_ARBITRADO_TOOLBAR   // Colar - N�o d� certo usar a K_CTRL_V diretamente
           * Vide coment�rio extenso mais acima !
           C_AcaoForaDaMemoEdit := "colar_via_toolbar"
           *
           HB_KeyPut(K_ESC) // Mesmo colocando K_ESC no teclado, mas conte�do da vari�vel � ATUALIZADO !
           *
      CASE N_Tecla   == K_CTRL_Z_ARBITRADO_TECLADO  // "Undo" - N�o d� certo usar a K_CTRL_Z diretamente
           * Vide coment�rio extenso mais acima !
           C_AcaoForaDaMemoEdit := "undo_via_teclado"
           *
           HB_KeyPut(K_ESC) // Mesmo colocando K_ESC no teclado, mas conte�do da vari�vel � ATUALIZADO !
           *
      CASE N_Tecla   == K_CTRL_Z_ARBITRADO_TOOLBAR  // "Undo" - N�o d� certo usar a K_CTRL_Z diretamente
           * Vide coment�rio extenso mais acima !
           C_AcaoForaDaMemoEdit := "undo_via_toolbar"
           *
           HB_KeyPut(K_ESC) // Mesmo colocando K_ESC no teclado, mas conte�do da vari�vel � ATUALIZADO !
           *
      CASE N_Tecla == K_MWBACKWARD
           * No Harbour, o cursor n�o desce automaticamente, sendo preciso programar a descida.
           N_Retorno := ME_IGNORE    // ignorar o INKEY() gerado pelo Mouse
           HB_KeyPut(K_DOWN)
      CASE N_Tecla == K_MWFORWARD
           * No Harbour, o cursor n�o sobe automaticamente, sendo preciso programar a subida.
           N_Retorno := ME_IGNORE    // ignorar o INKEY() gerado pelo Mouse
           HB_KeyPut(K_UP)
      CASE N_Tecla   == K_LBUTTONDOWN .OR. N_Tecla == K_LDBLCLK
           *
           N_Retorno := ME_IGNORE    // ignorar o INKEY() gerado pelo Mouse
           *
           N_mRow := mRow()
           N_mCol := mCol()
           N_RegiaoMouse := RegiaoJanela_(MEMVAR->VX_Janela,N_mRow,N_mCol,;
                                          Lin1Livre(MEMVAR->VX_Janela),;
                                          Col1Livre(MEMVAR->VX_Janela),;
                                          Lin2Livre(MEMVAR->VX_Janela),;
                                          Col2Livre(MEMVAR->VX_Janela),;
                                          @N_Keyboard)
           #INCLUDE "mousecua.ch"
           *
           IF N_RegiaoMouse == AREA_UTIL
              C_BufferTeclado := ""
              *
              N_Desloca_Vertical := N_mRow - ROW()
              IF N_Desloca_Vertical < 0
                 C_BufferTeclado := C_BufferTeclado + ;
                                    REPL(CHR(K_UP),-N_Desloca_Vertical)
              ELSEIF N_Desloca_Vertical > 0
                 C_BufferTeclado := C_BufferTeclado + ;
                                    REPL(CHR(K_DOWN),+N_Desloca_Vertical)
              ENDIF
              *
              N_Desloca_Horizontal := N_mCol - COL()
              IF N_Desloca_Horizontal < 0
                 C_BufferTeclado := C_BufferTeclado + ;
                                    REPL(CHR(K_LEFT),-N_Desloca_Horizontal)
              ELSEIF N_Desloca_Horizontal > 0
                 C_BufferTeclado := C_BufferTeclado + ;
                                    REPL(CHR(K_RIGHT),+N_Desloca_Horizontal)
              ENDIF
              *
              IF LEN(C_BufferTeclado) # 0 .AND. EVAL(B_Edita)
                 KEYBOARD C_BufferTeclado
              ENDIF
              *
           ELSEIF N_Keyboard # NIL
              *
              IF .NOT. EVAL(B_Edita)
                 IF ASCAN(VN_TeclaGravar,N_Keyboard) # 0
                    L_FimOK   := .T.
                    N_Retorno := K_ESC     // n�o � necess�rio salvar (n�o teve edi��o)
                 ELSE
                    HB_KeyPut(N_Keyboard)
                 ENDIF
              ELSE
                 IF ASCAN(VN_TeclaGravar,N_Keyboard) # 0
                    L_FimOK   := .T.
                    N_Retorno := K_CTRL_W       // sempre salva ao terminar
                 ELSE
                    HB_KeyPut(N_Keyboard)
                 ENDIF
              ENDIF
              *
           ENDIF
           *
      CASE .NOT. EVAL(B_Edita)
           *
           L_PodeExecutar := INABILITA_TECLA_F9(N_Tecla)
           *
           IF L_PodeExecutar
              *
              * implementar o SCROLL horizontal ( executar a rolamento somente
              * se houver rolamento efetivo )
              *
              DO CASE
                 * No Harbour o rolamento horizontal tem muitos bugs, sendo
                 * que se adotou a seguinte solu��o:
                 *   - garantir que a largura do texto seja sempre <=
                 *     � largura da janela
                 *   - garantir que o WordWrap esteja sempre ativado
                 CASE ASCAN(VN_TeclaGravar,N_Tecla) # 0
                      L_FimOK   := .T.
                      N_Retorno := K_ESC     // n�o � necess�rio salvar (n�o teve edi��o)
              ENDCASE
              *
           ENDIF
           *
      CASE EVAL(B_Edita)
           DO CASE
              CASE ASCAN(VN_TeclaGravar,N_Tecla) # 0
                   L_FimOK   := .T.
                   N_Retorno := K_CTRL_W       // sempre salva ao terminar
              CASE N_Tecla   == K_INS
                   * A tecla INS ainda ser� processada, por isso este
                   * comando � o inverso do comando efetuado na fun��o principal.
                   SET(_SET_CURSOR,IIF(READINSERT(),SC_NORMAL,SC_INSERT))
              CASE (N_Tecla == K_ENTER .AND. READINSERT())
                   N_TotLinhas := N_TotLinhas + 1         &&* VIDE ABAIXO
              CASE N_Tecla == K_CTRL_N_ARBITRADO_TECLADO
                   * O K_CTRL_N n�o est� criando mais linha nova.
                   * Al�m disto, tem funcionamento irregular:
                   *    - no xHarbour desfaz todas as modifica��es, como se fosse o CTRL-Z
                   *    - no Harbour n�o faz nada
                   *
                   * Por estes motivos, n�o mais incrementar o contador de linhas...
                   * N_TotLinhas := N_TotLinhas + 1         &&* VIDE ABAIXO
              CASE N_Tecla == K_CTRL_Y_ARBITRADO_TECLADO .AND. N_TotLinhas >= 1
                   * O K_CTRL_Y funciona conforme esperado (apaga uma linha)
                   N_TotLinhas := N_TotLinhas - 1         &&* VIDE ABAIXO
              CASE RESERVADA(N_Tecla)
                   * esta fun��o por objetivo evitar que teclas reservadas da
                   * MEMOEDIT sejam tratadas no filtro de teclas do usu�rio
              CASE IIF(B_FiltroTec==NIL .OR. .NOT. L_Converter_Tecla_ANSI_para_OEM,;
                       .F.,;
                       _FILTROTEC_(B_FiltroTec,.F.))
                   * caso seja uma tecla substitu�vel,
                   * j� foi colocado no buffer de teclado
           ENDCASE
           *
           IF N_Lin > N_TotLinhas
              N_TotLinhas := N_Lin           &&* VIDE ABAIXO
           ENDIF
   ENDCASE
   *
   N_Tecla_Ant := N_Tecla
   *
ENDIF
*
#UNDEF VN_TeclaGravar
*
IF L_MontarRolamento
   // IF ( L_MontarRolamento .AND. N_Modo == ME_INIT ) .OR. N_Modo == ME_IDLE
   *
   * montar indicativos de rolamento
   *    &&* FURADOS PARA TEXTO COM EDI��O, POIS N�O � POSS�VEL PREVER
   *    &&* TODOS OS CASOS EM QUE LINHAS SER�O INCLU�DAS/EXCLU�DAS DO
   *    &&* TEXTO. SER� FEITA, ENTRETANTO, UMA TENTATIVA DE APROXIMA��O
   *    &&* DO RESULTADO CORRETO, DESPREZANDO:
   *    &&* - O EFEITO DA TECLA <DEL> QUE APAGA LINHA SE
   *    &&*   EM FINAL DE LINHA, QUE N�O SEJA FINAL DE TEXTO. )
   *    &&* - TODAS OS REALINHAMENTOS AUTOMATICOS CAUSADOS PELO WORD WRAP
   *
   #DEFINE L_Cima  ( N_Lin - 1 # ROW() - Lin1Livre(MEMVAR->VX_Janela) )
   #DEFINE L_Baixo ( N_Lin + (Lin2Livre(MEMVAR->VX_Janela) - ROW()) < N_TotLinhas )
   #DEFINE L_Esq   .F.
   #DEFINE L_Dir   .F.
   * Rolamento horizontal em memoedit foi abolido...
   * #DEFINE L_Esq   ( N_Col     # COL() - Col1Livre(MEMVAR->VX_Janela) )
   * #DEFINE L_Dir   ( N_Col + (Col2Livre(MEMVAR->VX_Janela) - COL()) < N_TamLinha )
   *
   Rolamento_(MEMVAR->VX_Janela,L_Esq,L_Cima,L_Baixo,L_Dir)
   *
   #UNDEF L_Cima
   #UNDEF L_Baixo
   #UNDEF L_Esq
   #UNDEF L_Dir
   *
ENDIF
*
IF N_Modo == ME_IDLE
   *
   * No Harbour, o status do "ReadInsert" tem de ser controlado manualmente.
   IF L_ReadInsert_Ativado_Automaticamente
      L_ReadInsert_Ativado_Automaticamente := .F.
      READINSERT(.F.)
   ENDIF
   *

   N_SEGUNDOS := SECONDS()
   N_TIMEOUT  := SETA_TIMEOUT()
   DO WHILE NEXTKEY() == 0     // resolve o problema do TIME SLICE
      HB_IdleState()
      IF N_TIMEOUT > 0
         IF (SECONDS() - N_SEGUNDOS) > N_TIMEOUT
            KEYBOARD REPL(CHR(K_ESC),50)
            SETA_TEMPOLIMITE(.T.)
         ENDIF
      ENDIF
   ENDDO
   *
ENDIF
*
SETCOLOR(C_CorAnt)
*
RETURN N_Retorno
// *
*******************
STAT FUNC RESERVADA ( N_Tecla )
*******************
Local C_Lista := { K_UP, K_DOWN, K_LEFT, K_RIGHT, K_HOME, K_END, K_PGUP,;
                   K_PGDN, K_CTRL_LEFT, K_CTRL_RIGHT, K_CTRL_HOME, K_CTRL_END,K_CTRL_W,;
                   K_CTRL_PGUP, K_CTRL_PGDN, K_ESC, K_RETURN, K_DEL, K_TAB,;
                   K_SH_TAB, K_INS, K_BS, K_CTRL_T, K_CTRL_Y }
*
RETURN ASCAN(C_Lista,N_Tecla) # 0

**********************************
STATIC FUNC INABILITA_EDICAO_TEXTO()
**********************************
LOCAL B_BLOCO := {||.T.}
*
IF CHECAR_MUDADADOS_COM_ESTE_SISTEMA_INABILITA()
   IF SELECT("XXPREG") # 0
      IF .NOT. EHPRINCIPAL(.F.)
         B_BLOCO := {||.F.}
      ENDIF
   ENDIF
ENDIF
*
RETURN B_BLOCO
*
******************************
STATIC FUNC INABILITA_TECLA_F9(N_Tecla) // A telca F9, s� � usada na especializa��o Texto.
******************************
LOCAL L_RET := .T.
*
IF N_Tecla == K_F9
   IF CHECAR_MUDADADOS_COM_ESTE_SISTEMA_INABILITA()
      IF .NOT. EHPRINCIPAL(.F.)
         L_RET := .F.
      ENDIF
   ENDIF
ENDIF
*
RETURN L_RET
// *
// *********************************

// /*
// -----------------------------------------------------------------------------
// Compara��o de comportamente em uma edi��o de texto entre xHarbour vs Harbour.
// Informa��o para documenta��o.
// -----------------------------------------------------------------------------


// DEL
//    - xHarbour - Ok
//    - Harbour  - Ok

// CTRL T

//    - xHarbour - Apaga somente a pr�xima palavra a partir da posi��o do cursor
//    - Harbour  - Apaga somente a pr�xima palavra a partir da posi��o do cursor

// CTRL C

//    - xHarbour - Envolve todo o texto
//    - Harbour  - Envolve todo o texto

// BackSpace

//    - xHarbour - Volta o cursor/deleta continuamente
//    - Harbour  - Volta o cursor/deleta somente na linha corrente

// Selecionar texto

//    - xHarbour

//       - Seleciona o texto
//       - DEL       - Apaga somente o texto selecionado
//       - BackSpace - Apaga o caractere onde cursor est� posicionado
//       - CTRL T    - Apaga somente a pr�xima palavra a partir da posi��o do cursor
//       - CTRL C    - Independente da sele��o, envolve todo o texto

//    - Harbour

//       - N�o Seleciona o texto
//       - DEL       - Apaga o caractere onde cursor est� posicionado
//       - BackSpace - Apaga o caractere onde cursor est� posicionado
//       - CTRL T    - Apaga somente a pr�xima palavra a partir da posi��o do cursor
//       - CTRL C    - Envolve todo o texto

// -----------------------------------------------------------------------------
// */