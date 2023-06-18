/* encoding: cp850 */

#pragma DebugInfo=On

/*

                    Aspec - Informatica
                    Direitos Autorais Reservado

   Criacao e tratamento das entradas de dados

*/
*
*
* OBS: N�o mais s�o v�lidas READEXIT(), somente encerra READ a seta p/ baixo
*                           UPDATED() - ser� substituida
*                           RANGE - N�o implementado
*                           SET FORMAT - N�o implementado
*                           SET SCOREBOARD - n�o tem mais influ�ncia,
*                                            por causa da B_ErroData, do
*                                            cursor de inser��o e do fim
*                                            da cl�usula RANGE.
*                           SET ESCAPE - N�o tem mais influ�ncia, o ESC
*                                        sempre encerra o READ.
*                           SET DELI   - &&* AINDA N�O DECIDIDO
*                           SET INTENS - &&* AINDA N�O DECIDIDO
*                           CLEAR, CLEAR GETS , CLEAR ALL &&*
*                           READINSERT() - &&* N�O DECIDIDO
*                           GETACTIVE() - N�o implementado
*                           SET BELL    - &&*
*
*   COLOCAR CL�USULA BRIGHT    &&*
*   COLOCAR CONTROLE DE CORES  &&*
*
#INCLUDE "inkey.ch"
#INCLUDE "setcurs.ch"
#INCLUDE "common.ch"
#INCLUDE "set.ch"
#INCLUDE "janela.ch"
#INCLUDE "define_cua.ch"
#INCLUDE "def_dados.ch"
#INCLUDE "gtnap.ch"

*
* sinalizadores de movimenta��o (armazenado em N_CodMovi)

#DEFINE ST_CIMA        1      // ir para o GET de cima
#DEFINE ST_BAIXO       2      // ir para o GET de baixo
#DEFINE ST_PRIMEIRO    3      // ir para o primeiro GET
#DEFINE ST_ULTIMO      4      // ir para o �ltimo GET
#DEFINE ST_PGUP        5      // voltar uma p�gina
#DEFINE ST_PGDN        6      // avan�ar uma p�gina
#DEFINE ST_MOUSE_CIMA  7      // voltar para um GET clicado no mouse
#DEFINE ST_MOUSE_BAIXO 8      // avan�ar para um GET clicado no mouse
*
***************
FUNC EspEntrada ( VX_Janela, B_ErroData, B_Confirma, B_Desiste, B_FiltroTec,;
                  B_Edita_Global, L_RolaVertical, L_SemToolBar )
*
DEFAULT L_RolaVertical   TO .F.
DEFAULT L_SemToolBar     TO .F.
*
IF .NOT. L_SemToolBar
   SETA_PARA_TER_TOOLBAR(VX_Janela) // ajusta N_LinIni e N_LinLivre
ENDIF
*
AJUSTA_BOTOES(VX_Janela)  // ajusta Lin2Livre � quantidade de bot�es de fun��o
*
IF L_RolaVertical
   * prever espa�o para scroll bar vertical
   Col2Livre(VX_Janela)--
   Col2Livre(VX_Janela)--
   L_ScrollVertical := .T.
ENDIF
*
#DEFINE N_SayGetCor    NIL        //  preenchido na ativa��o
#DEFINE N_CodMovi      NIL        // idem
#DEFINE L_Alterado     NIL        // idem
#DEFINE L_Aborta       NIL        // idem
#DEFINE L_NaoSaltou    NIL        // idem
#DEFINE N_LinCobertas  0          // idem
#DEFINE N_ColCobertas  0          // idem
#DEFINE L_TemMessage   .F.        // preenchida na defini��o
#DEFINE L_Paginou                 // preenchida na ativa��o
#DEFINE VX_SayGetList  {}
#DEFINE V_RegiaoSayGet {}
#DEFINE N_PosRegiaoSayGet 0
#DEFINE L_PrimAtivacao .T.    // indica que � primeira ativa��o da janela
#DEFINE L_AtivaGui     .F.    // se os boxs dos GETs devem ser desenhados
#DEFINE V_Lst_CdGET    {}
#DEFINE C_Say_Anterior_Help   ""
*
DEFAULT B_Edita_Global TO {||.T.}
DEFAULT B_FiltroTec    TO {||ACENTUA()}
DEFAULT B_ErroData     TO {||DATAINVA()}
*
N_TP_Jan   := _JAN_ENTRADA_10
VX_SubObj  := { B_ErroData, B_Confirma, B_Desiste , B_FiltroTec, N_SayGetCor,;
                N_CodMovi , L_Alterado, L_Aborta  , L_NaoSaltou,;
                N_LinCobertas, N_ColCobertas, L_TemMessage, L_Paginou, VX_SayGetList,;
                B_Edita_Global, V_RegiaoSayGet, N_PosRegiaoSayGet, L_PrimAtivacao,;
                L_AtivaGui, V_Lst_CdGET, C_Say_Anterior_Help}
B_Metodo   := { ||Ler(VX_Janela) }
*
#UNDEF N_SayGetCor
#UNDEF N_CodMovi
#UNDEF L_Alterado
#UNDEF L_Aborta
#UNDEF L_NaoSaltou
#UNDEF N_LinCobertas
#UNDEF N_ColCobertas
#UNDEF L_TemMessage
#UNDEF L_Paginou
#UNDEF VX_SayGetList
#UNDEF V_RegiaoSayGet
#UNDEF N_PosRegiaoSayGet
#UNDEF L_PrimAtivacao
#UNDEF L_AtivaGui
#UNDEF V_Lst_CdGET
#UNDEF C_Say_Anterior_Help
*
RETURN NIL
*
*
* DEFINI�OES DE USO GERAL
*
#DEFINE B_ErroData        VX_Edicao[1]   // bloco a ser executado se data inv�lida
#DEFINE B_Confirma        VX_Edicao[2]   // bloco de confirma��o final
#DEFINE B_Desiste         VX_Edicao[3]   // bloco de desist�ncia de abortagem
#DEFINE B_FiltroTec       VX_Edicao[4]   // bloco para filtragem de teclas
#DEFINE N_SayGetCor       VX_Edicao[5]   // n�mero do GET/SAY corrente
#DEFINE N_CodMovi         VX_Edicao[6]   // c�digo de movimenta��o do GET corrente
#DEFINE L_Alterado        VX_Edicao[7]   // se algum GET foi alterado
#DEFINE L_Aborta          VX_Edicao[8]   // .T.  se for abortado
#DEFINE L_NaoSaltou       VX_Edicao[9]   // se GET corrente foi saltado ou
                                         // o item corrente for um SAY
#DEFINE N_LinCobertas     VX_Edicao[10]  // linhas cobertas pelo rolamento vertical
#DEFINE N_ColCobertas     VX_Edicao[11]  // colunas cobertas pelo rolamento horizontal
#DEFINE L_TemMessage      VX_Edicao[12]  // se existe alguma cl�usula MESSAGE
#DEFINE L_Paginou         VX_Edicao[13]  // se houve pagina��o ou n�o
#DEFINE VX_SayGetList     VX_Edicao[14]  // lista de GETs e SAYs anexados
#DEFINE B_Edita_Global    VX_Edicao[15]  // cl�usula global de edi��o ou n�o
#DEFINE V_RegiaoSayGet    VX_Edicao[16]  // regioes na tela dos Says/Gets
#DEFINE N_PosRegiaoSayGet VX_Edicao[17]  // �ltima regi�o de say/get clicada
#DEFINE L_PrimAtivacao    VX_Edicao[18]  // indica que � primeira ativa��o da janela
#DEFINE L_AtivaGui        VX_Edicao[19]
#DEFINE V_Lst_CdGET       VX_Edicao[20]  // lista de GETs para rotina de help
#DEFINE C_Say_Anterior_Help   VX_Edicao[21]  // conte�do do �ltimo SAY anexado � lista
*
#INCLUDE "color.ch"
*************
FUNC AnexeSay ( VX_Janela, N_Lin, N_Col, B_Expressao, C_Pict, C_CorSay, ;
                L_SimboloDropDown  )
*************
*
DEFAULT L_SimboloDropDown TO .F.
*
IF C_CorSay == NIL
   C_CorSay := _Pega_Cor_(CorJanela(VX_Janela),CLR_STANDARD)
ELSEIF "/" $ C_CorSay .OR. "," $ C_CorSay
   * formato inv�lido, adotar cor default
   C_CorSay := _Pega_Cor_(CorJanela(VX_Janela),CLR_STANDARD)
ELSEIF C_CorSay=="+"
   * intensificar a cor de frente atual
   C_CorSay := CorJanInten(VX_Janela)
ELSE
   * Mudar cor de frente, mantendo cor de fundo
   C_CorSay := C_CorSay+"/"+_Pega_Cor_(CorJanela(VX_Janela),CLR_STANDARD,.F.)
ENDIF
*
#DEFINE VX_Edicao   VX_SubObj
AADD(VX_SayGetList,  { N_Lin, N_Col, B_Expressao, C_Pict, C_CorSay, ;
                       L_SimboloDropDown } )
IF .NOT. L_SimboloDropDown
   C_Say_Anterior_Help := ConteudoCaractere(B_Expressao,C_Pict)
ENDIF
#UNDEF  VX_Edicao
*
RETURN NIL
*
*************
FUNC AnexeGet ( VX_Janela, N_Lin, N_Col, VX_Get, C_CorGet,;
                B_When , B_Valid , B_Edita , B_Lista, B_Auto, B_Mess, C_CdGET,;
                O_Dominio, O_Campo, C_IdCurtoCampoDoCampo,;
                L_F4ComCodigo, L_SemF4, L_CampoOpcional )
*************
LOCAL N_LarguraVar, N_LarguraTela, N_LarguraGet, C_CorNaoSele
LOCAL C_Tipo_de_GET
LOCAL C_Picture_GET_Aux
LOCAL L_Get_tem_Picture
LOCAL L_With_B_Lista := .F.
*
IF .NOT. LEFT(C_CdGET,1) == "C"
   ? MEMVAR->ERRO_ASSUME
ENDIF
IF .NOT. LEN(TROCA(C_CdGET,"C0123456789?",""))==0
   ? MEMVAR->ERRO_ASSUME
ENDIF
IF .NOT. LEN(C_CdGET)==6
   ? MEMVAR->ERRO_ASSUME
ENDIF
*


//!! Futuramente pode ser removido, se todos recompilarem todos os fontes !
* O "default" abaixo somente � necess�rio para evitar a recompila��o de todos os ".o".
* No c�digo n�o recompilado, estes campos conter�o NIL
* No c�digo recompilado, estes campos conter�o .T. ou .F.
DEFAULT L_F4ComCodigo     TO .F.
DEFAULT L_SemF4           TO .F.
DEFAULT L_CampoOpcional  TO .F.
//!! Futuramente pode ser removido

* PENDENTE - testar tudo novamente dentro da GTWVW
* PENDENTE - falta usar o par�metro "ConteudoSugerido".
*            Se for menor que o campo texto do GET, acrescentar espa�os ao final.

* Garantir que, no m�ximo, somente uma das vari�veis O_Dominio, O_Campo, C_IdCurtoCampoDoCampo
* esteja preenchida (s�o mutuamente excludentes).
IF O_Dominio # NIL .OR. ;
   O_Campo # NIL .OR. ;
   C_IdCurtoCampoDoCampo # NIL
   *
   /*
   IF O_Dominio # NIL
      C_Tipo_de_GET := "DOMINIO"  // N�o padr�o, pois recebe a defini��o de um dom�nio
      *
      IF B_Lista # NIL .OR. O_Campo # NIL .OR. C_IdCurtoCampoDoCampo # NIL
         ? MEMVAR->ERRO_ASSUME_VARIAVEL_DEVERIA_CONTER_NIL_A
      ENDIF
      *
      CHK_PARAMETRO_Obj_Dominio(O_Dominio)  // V� se o HASH � v�lido
      *
      * PENDENTE - Setar dom�nio como usado, para n�o mais poder ser modificado
      * PENDENTE - Testar se tipo de dados do dom�nio � igual � vari�vel do GET
      * PENDENTE - Se caractere, testar se tamanho m�ximo do dom�nio == tamanho da vari�vel do GET !
      *
      * Garantir que usu�rio final n�o informou picture explicitamente.
      IF VX_Get:Picture # NIL
         * NOTA: Em algum momento, o "VX_Get:Picture" muda de "NIL" para "".
         *       BUG: Tem locais da CUA testando s� por NIL !
         IF LEN(VX_Get:Picture) # 0
            ? MEMVAR->ERRO_ASSUME_GET_COM_DOMINIO_NAO_PODE_TER_PICTURE_INFORMADA
         ENDIF
      ENDIF
      IF O_Dominio:TipoDeDados == "Texto"   // S� campos de tamanho fixo (n�o "memo") podem ter dom�nio
         * Setar a picture deduzida automaticamente na cria��o do dom�nio
         * (caso o dom�nio seja do tipo caractere)
         VX_Get:Picture := O_Dominio:TipoTexto_PictureDeduzida  // S� tem picture posicional
         IF O_Dominio:LetrasSempreMaiusculas()
            VX_Get:Picture := "@! "+;  // �nica picture de fun��o usadas em dom�nios
                              VX_Get:Picture
         ENDIF
      ENDIF
      *
   ELSEIF O_Campo # NIL
      C_Tipo_de_GET := "CAMPO"  // N�o padr�o, pois recebe a defini��o de um campo
      *
      IF B_Lista # NIL .OR. O_Dominio # NIL .OR. C_IdCurtoCampoDoCampo # NIL
         ? MEMVAR->ERRO_ASSUME_VARIAVEL_DEVERIA_CONTER_NIL_B
      ENDIF
      *
      CHK_PARAMETRO_Obj_Campo(O_Campo)  // V� se o HASH � v�lido
      *
      IF O_Campo:ObjetoDominio == NIL  // Campo n�o tem dom�nio
         * Buscar contradi��o na especifica��o do GET
         * (indica erro de programa��o, devendo o programador corrigir na linha do GET)
         IF L_SemF4
            ? MEMVAR->ERRO_ASSUME_CAMPO_SEM_DOMINIO_MAS_COM_SEMF4
         ENDIF
         IF B_Auto # NIL
            ? MEMVAR->ERRO_ASSUME_CAMPO_SEM_DOMINIO_MAS_COM_AUTO
         ENDIF
         IF L_F4ComCodigo
            ? MEMVAR->ERRO_ASSUME_CAMPO_SEM_DOMINIO_MAS_COM_F4SEMCODIGO
         ENDIF
         *
         L_SemF4 := .T. // Sem dom�nio n�o existe F4
         *
      ELSE  // Campo tem dom�nio
         *
         * Copiar o dom�nio existente no campo para o GET
         * PENDENTE - decidir se clona o HASH, como forma de evitar efeitos colaterais de modifica��es externas
         O_Dominio := O_Campo:ObjetoDominio
      ENDIF
      *
      * PENDENTE - Setar campo como usado, para n�o mais poder ser modificado
      * PENDENTE - Testar se campo foi especializado
      * PENDENTE - Testar se tipo de dados do campo � igual � vari�vel do GET
      * PENDENTE - Se caractere, testar se tamanho m�ximo do campo == tamanho da vari�vel do GET !
      *
      IF O_Campo:TipoDeDados == "Data"
         IF VX_Get:Picture # NIL
            * NOTA: Em algum momento, o "VX_Get:Picture" muda de "NIL" para "".
            *       BUG: Tem locais da CUA testando s� por NIL !
            IF LEN(VX_Get:Picture) # 0
               * PENDENTE - Poder dizer que data � com somente 2 anos
               * PENDENTE - explicitando a picture como sendo "99/99/99" N�O funcionou !
               IF .NOT. VX_Get:Picture == "99/99/99"
                  ? MEMVAR->ERRO_ASSUME_GET_COM_CAMPO_DATA_SO_PODE_TER_PICTURE_99_99_99
               ENDIF
            ELSE
               * Nota: Quando o campo � num�rico, O_Campo j� vem com a picture de fun��o com "@E"
               VX_Get:Picture := O_Campo:Picture
            ENDIF
         ELSE
            * Nota: Quando o campo � num�rico, O_Campo j� vem com a picture de fun��o com "@E"
            VX_Get:Picture := O_Campo:Picture
         ENDIF
      ELSEIF O_Campo:TipoDeDados == "Logico" .OR. ;
             O_Campo:TipoDeDados == "Numerico"
         IF VX_Get:Picture # NIL
            * NOTA: Em algum momento, o "VX_Get:Picture" muda de "NIL" para "".
            *       BUG: Tem locais da CUA testando s� por NIL !
            IF LEN(VX_Get:Picture) # 0
               ? MEMVAR->ERRO_ASSUME_GET_COM_CAMPO_SO_PODE_TER_PICTURE_SE_CARACTERE_OU_DATA
            ENDIF
         ENDIF
         * Nota: Quando o campo � num�rico, O_Campo j� vem com a picture de fun��o com "@E"
         VX_Get:Picture := O_Campo:Picture
      ELSEIF O_Campo:TipoDeDados == "Texto"  // S� campos de tamanho fixo (n�o "memo") podem ter GETs

         * PENDENTE - Dar erro se programador est� dando GET em campo "memo" !

         L_Get_tem_Picture := ( VX_Get:Picture # NIL )
         IF L_Get_tem_Picture
            * NOTA: Em algum momento, o "VX_Get:Picture" muda de "NIL" para "".
            *       BUG: Tem locais da CUA testando s� por NIL !
            L_Get_tem_Picture := ( LEN(VX_Get:Picture) # 0 )
         ENDIF
         *
         IF L_Get_tem_Picture
            * S� aceitar� picture "@K" e "@Snnn".
            C_Picture_GET_Aux := UPPER(VX_Get:Picture)
            C_Picture_GET_Aux := STRTRAN(C_Picture_GET_Aux,"@K","")
            C_Picture_GET_Aux := STRTRAN(C_Picture_GET_Aux,"@S","")
            IF LEN(C_Picture_GET_Aux) # 0
               * O que sobrar tem de ser s� numeros.
               IF .NOT. HB_RegExLike("\d+",C_Picture_GET_Aux)
                  ? MEMVAR->ERRO_ASSUME_GET_COM_CAMPO_CARACTERE_TEM_PICTURE_ERRADA
               ENDIF
            ENDIF
            * Se campo tem dom�nio, o conte�do de O_Campo:Picture
            * � igual ao conte�do de O_Dominio:TipoTexto_PictureDeduzida
            IF O_Campo:Picture # NIL
               VX_Get:Picture := VX_Get:Picture + ;     // S� tem picture de fun��es
                                 " " + O_Campo:Picture  // S� tem picture posicional
               IF O_Dominio # NIL  // Significa que dom�nio foi acrescentado ao campo
                  IF O_Dominio:LetrasSempreMaiusculas()
                     VX_Get:Picture := "@!"+;   // Acrescentar esta picture de fun��o �s j� existentes
                                       VX_Get:Picture
                  ENDIF
               ENDIF
            ENDIF
         ELSE
            * Se campo tem dom�nio, o conte�do de O_Campo:Picture
            * � igual ao conte�do de O_Dominio:TipoTexto_PictureDeduzida
            IF O_Campo:Picture # NIL
               VX_Get:Picture := O_Campo:Picture // S� tem picture posicional
               IF O_Dominio # NIL  // Significa que dom�nio foi acrescentado ao campo
                  IF O_Dominio:LetrasSempreMaiusculas()
                     VX_Get:Picture := "@! "+;   // �nica picture de fun��o usadas em dom�nios
                                       VX_Get:Picture
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
      ELSE
         ? MEMVAR->ERRO_ASSUME_TIPO_DE_DADOS_DE_CAMPO_INVALIDO
      ENDIF
      *
   ELSEIF C_IdCurtoCampoDoCampo # NIL
      C_Tipo_de_GET := "IDCAMPO"  // N�o padr�o, pois recebe um identificador de campo
                                  // cuja defini��o registro foi anteriormente especificada
                                  // na especializa��o da janela para entrada de dados
      *
      IF B_Lista # NIL .OR. O_Dominio # NIL .OR. O_Campo # NIL
         ? MEMVAR->ERRO_ASSUME_VARIAVEL_DEVERIA_CONTER_NIL_C
      ENDIF
      ? MEMVAR->ERRO_ASSUME  // PENDENTE DE IMPLEMENTACAO
   ENDIF ERRO
   */
   *
   IF .NOT. L_SemF4
      * Apontar para o F4 padr�o para dom�nio
      B_Lista := ROTINA_F4_PADRAO_PARA_DOMINIO(O_Dominio,L_F4ComCodigo)
   ENDIF
   *
   DEFAULT L_CampoOpcional TO .F.
   *
   * Buscar contradi��o na especifica��o do GET
   * (indica erro de programa��o, devendo o programador corrigir na linha do GET)
   IF L_SemF4
      IF B_Auto # NIL
         ? MEMVAR->ERRO_ASSUME_GET_COM_AUTO_E_SEMF4_AO_MESMO_TEMPO
      ENDIF
      IF L_F4ComCodigo
         ? MEMVAR->ERRO_ASSUME_GET_COM_F4COMCODIGO_E_SEMF4_AO_MESMO_TEMPO
      ENDIF
   ENDIF
ELSE
   C_Tipo_de_GET := "PADRAO"
   * � um GET no formato antigo, n�o podendo ter as cl�usulas novas abaixo
   IF O_Dominio # NIL .OR. C_IdCurtoCampoDoCampo # NIL .OR. C_IdCurtoCampoDoCampo # NIL
      ? MEMVAR->ERRO_ASSUME_VARIAVEL_DEVERIA_CONTER_NIL_D
   ENDIF
   *
   * No GET padr�o, a L_SemF4 sempre vem ".F.".
   * Tendo o par�metro B_Lista, tem o F4.
   L_SemF4 := (B_Lista == NIL)
   *
ENDIF
*
#DEFINE VX_Edicao   VX_SubObj
AADD(V_Lst_CdGET,{C_CdGET,C_Say_Anterior_Help})
*
IF B_Mess # NIL .AND. .NOT. L_TemMessage
   L_TemMessage := .T.
   Lin2livre(VX_Janela)--         // decrementar linha livre de uma posi��o
ENDIF
#UNDEF  VX_Edicao
*
IF C_CorGet == NIL
   C_CorGet     := _Pega_Cor_(CorJanela(VX_Janela),CLR_ENHANCED)
   C_CorNaoSele := _Pega_Cor_(CorJanela(VX_Janela),CLR_UNSELECTED)
ELSEIF "/" $ C_CorGet .OR. "," $ C_CorGet
   * formato inv�lido, adotar cor default
   C_CorGet     := _Pega_Cor_(CorJanela(VX_Janela),CLR_ENHANCED)
   C_CorNaoSele := _Pega_Cor_(CorJanela(VX_Janela),CLR_UNSELECTED)
ELSEIF C_CorGet=="PASSWORD"
   * Mudar cor de frente para ser igual � cor de fundo
   C_CorGet     := STRTRAN(_Pega_Cor_(CorJanela(VX_Janela),CLR_ENHANCED  ,.F.),"*","+")+;
                   "/"+_Pega_Cor_(CorJanela(VX_Janela),CLR_ENHANCED  ,.F.)
   C_CorNaoSele := STRTRAN(_Pega_Cor_(CorJanela(VX_Janela),CLR_UNSELECTED,.F.),"*","+")+;
                   "/"+_Pega_Cor_(CorJanela(VX_Janela),CLR_UNSELECTED,.F.)
ELSEIF C_CorGet=="INVISIBLE"
   * Mudar cor de frente e de fundo para ser igual � cor da jenela.
   * Usado para deixar o GET "invisivel".
   C_CorGet     := _Pega_Cor_(CorJanela(VX_Janela),CLR_STANDARD)
   C_CorNaoSele := _Pega_Cor_(CorJanela(VX_Janela),CLR_STANDARD)
ELSE
   * Mudar cor de frente, mantendo a cor de fundo
   C_CorGet     := C_CorGet+"/"+;
                   _Pega_Cor_(CorJanela(VX_Janela),CLR_ENHANCED  ,.F.)
   C_CorNaoSele := C_CorGet+"/"+;
                   _Pega_Cor_(CorJanela(VX_Janela),CLR_UNSELECTED,.F.)
ENDIF
C_CorGet := C_CorNaoSele + "," + C_CorGet
*
VX_Get:COLORSPEC := C_CorGet
VX_Get:PREBLOCK  := B_When
VX_Get:POSTBLOCK := B_Valid
*
IF B_Edita == NIL
   B_Edita := {||.T.}
ENDIF
IF B_Lista == NIL
   B_Lista := {||NIL}
ELSE
   L_With_B_Lista := .T.
ENDIF
IF B_Auto == NIL
   B_Auto := {||.F.}
ENDIF
*
IF VX_Get:TYPE == "C" .AND. VX_Get:PICTURE # NIL
   *
   N_LarguraVar  := LEN(VX_Get:VARGET())
   N_LarguraTela := LarguraTela(VX_Get:BLOCK,VX_Get:PICTURE)
   *
   * Caso a picture tenha a fun��o @R, "var" pode ser menor que "tela"
   IF N_LarguraVar <= N_LarguraTela
      N_Larguravar := N_LarguraTela := NIL
   ENDIF
   *
ELSEIF VX_Get:TYPE == "C"
    *
    N_LarguraVar  := LEN(VX_Get:VARGET())
    N_LarguraTela := N_LarguraVar

// DATA Type variable
ELSEIF VX_Get:TYPE == "D"
    N_LarguraVar  := 10 // DD/MM/YYYY
    N_LarguraTela := N_LarguraVar

ELSE
    NAP_LOG("TYPE OF DATA: " + VX_Get:TYPE)

ENDIF
*
* //!! depois unificar as vari�veis N_LARGURATELA E N_LARGURABOX
N_LarguraGet := LarguraTela(VX_Get:BLOCK,VX_Get:PICTURE)
VX_Get:CARGO := { N_Lin, N_Col, B_Edita, B_Lista, B_Auto, B_Mess,;
                  N_LarguraVar, N_LarguraTela, C_CdGET, N_LarguraGet,;
                  C_Tipo_de_GET, O_Dominio, O_Campo, C_IdCurtoCampoDoCampo,;
                  L_F4ComCodigo, L_SemF4, L_CampoOpcional, L_With_B_Lista }
*
#DEFINE VX_Edicao   VX_SubObj
AADD(VX_SayGetList,VX_Get)
*
* linha inicial / coluna inicial / linha final / coluna final /
*    tipo de informa��o / Posicao do Get no VX_SayGetList
AADD(V_RegiaoSayGet,{N_Lin, N_Col, ;
                     N_Lin, N_Col+N_LarguraGet-1,"GET",LEN(VX_SayGetList)})
#UNDEF  VX_Edicao
*
IF .NOT. L_SemF4
    #DEFINE N_ColSay  N_Col + LarguraTela(VX_Get:BLOCK,VX_Get:PICTURE)
    AnexeSay ( VX_Janela, N_Lin, N_ColSay, {||" "+CHR(31)+" "} )
    *
    #DEFINE _REGIAO_DROP_DOWN "DROP"
    *
    #DEFINE VX_Edicao   VX_SubObj
    AADD(V_RegiaoSayGet,{N_Lin, N_ColSay, N_Lin, N_ColSay+2,_REGIAO_DROP_DOWN,;
                        LEN(VX_SayGetList)-1}) // deve apontar para o GET original
    #UNDEF VX_Edicao
    #UNDEF N_ColSay
ENDIF
IF N_LarguraVar # N_LarguraTela
    #DEFINE N_ColSay  N_Col + N_LarguraTela + 1
    AnexeSay ( VX_Janela, N_Lin, N_ColSay, {||CHR(26)} )    // seta para esquerda
    #UNDEF N_ColSay
ENDIF
*
RETURN NIL
*
*********************************************
STATIC FUNCTION ROTINA_F4_PADRAO_PARA_DOMINIO (O_Dominio,L_F4ComCodigo)
*********************************************
* PENDENTE - no futuro, decidir se faz uma rotina TABMEM() espec�fica para dom�mio
*            (ficaria bem mais simples e expans�vel)
*
LOCAL B_Lista
LOCAL C_NomeCompleto, V_LST_POSMOSTRA
*
C_NomeCompleto := O_Dominio:NomeCompleto  // Pode conter NIL ou tamb�m o ";"
IF L_F4ComCodigo
   V_LST_POSMOSTRA := {1,2}
ELSE
   V_LST_POSMOSTRA := {2}
ENDIF
*
B_Lista := {|| TABMEM(O_Dominio:Lst_ConteudoETitulo,;
                      V_LST_POSMOSTRA,;  // quais colunas do dom�nio exibir
                      1,;     // Sempre ser� retornado a primeira coluna do vetor
                      C_NomeCompleto,;
                      .NOT. O_Dominio:TituloTemTeclaAtalho)} // se � para remover a cerquilha (#)
*
RETURN B_Lista
*
***************
FUNC AnexSayGet ( VX_Janela, N_Lin, N_Col, B_Expressao, C_Pict, C_CorSay, ;
                  VX_Get, C_CorGet, B_When, B_Valid, B_Edita, B_Lista,;
                  B_Auto, B_Mess, C_CdGET,;
                  O_Dominio, O_Campo, C_IdCurtoCampoDoCampo,;
                  L_F4ComCodigo, L_SemF4, L_CampoOpcional )
***************
*
* anexar o SAY
AnexeSay( VX_Janela, N_Lin, N_Col, B_Expressao, C_Pict, C_CorSay )
*
#DEFINE N_ColGet  N_Col + LarguraTela(B_Expressao,C_Pict) + 1
AnexeGet ( VX_Janela, N_Lin, N_ColGet, VX_Get, C_CorGet, B_When, B_Valid,;
                      B_Edita, B_Lista, B_Auto, B_Mess, C_CdGET,;
                      O_Dominio, O_Campo, C_IdCurtoCampoDoCampo,;
                      L_F4ComCodigo, L_SemF4, L_CampoOpcional )
#UNDEF N_ColGet
*
RETURN NIL
*
*********************
STAT FUNC LarguraTela ( B_Dado, C_Pict )
*********************
RETURN LEN(ConteudoCaractere(B_Dado,C_Pict))

***************************
STAT FUNC ConteudoCaractere ( B_Dado, C_Pict )
***************************
LOCAL X_Dado := EVAL(B_Dado)
LOCAL C_Dado
IF C_Pict # NIL
    C_Dado := TRANSFORM(X_Dado,C_Pict)
ELSE
    IF VALTYPE(X_Dado) == "C"
       C_Dado := X_Dado
    ELSEIF VALTYPE(X_Dado) == "D"
       C_Dado := DTOC(X_Dado)
    ELSEIF VALTYPE(X_Dado) == "N"
       C_Dado := STR(X_Dado)
    ENDIF
ENDIF
RETURN C_Dado

****************************
STATIC FUNC Ler( VX_Janela )
****************************
LOCAL N_CursorAnt, C_ReadVarAnt, N_Col, N_Row, N_Cont
LOCAL VX_Get, VX_Edicao, N_EditId, N_LabelId, N_ButId
LOCAL N_LargJanela := Col2Livre(VX_Janela)-Col1Livre(VX_Janela)+1
LOCAL N_Aux_SayGetCor, X_Info, X_Retorno, X_Dado
LOCAL B_ConfirmaBlock := NIL, B_DesisteBlock := NIL, B_ErrorDataBlock := NIL
LOCAL B_FinalLista := NIL
LOCAL N_Message := NIL

VX_Edicao := VX_SubObj

IF SOB_MODO_GRAFICO()

    IF L_PrimAtivacao

        B_ConfirmaBlock := IIF(B_Confirma # NIL, B_Confirma, {||.T.})
        B_DesisteBlock := IIF(B_Desiste # NIL, B_Desiste, {||.T.})
        B_ErrorDataBlock := IIF(B_ErroData # NIL, B_ErroData, {||.T.})

        // Set window global functions
        NAP_WINDOW_EDITABLE(N_WindowNum, B_Edita_Global)
        NAP_WINDOW_CONFIRM(N_WindowNum, B_ConfirmaBlock)
        NAP_WINDOW_DESIST(N_WindowNum, B_DesisteBlock)
        NAP_WINDOW_ERRDATE(N_WindowNum, B_ErrorDataBlock)

        // Create an inner scroll panel
        IF L_ScrollVertical
            NAP_WINDOW_SCROLL(N_WindowNum, Lin1Livre(VX_Janela), Col1Livre(VX_Janela), Lin2Livre(VX_Janela), Col2Livre(VX_Janela))
        ENDIF

        // Label for Get messages
        N_Message := NAP_LABEL_MESSAGE(N_WindowNum, LinMess(VX_Janela), Col1Livre(VX_Janela), .F.)

        FOR N_Aux_SayGetCor := 1 TO LEN(VX_SayGetList)

            X_Info := VX_SayGetList[N_Aux_SayGetCor]
            N_Col := ColVirtual(VX_Janela,N_Aux_SayGetCor)
            N_Row := LinVirtual(VX_Janela,N_Aux_SayGetCor)

            #DEFINE L_E_Get  (VALTYPE(X_Info) == "O")
            IF L_E_Get
                #DEFINE N_LarguraVar  X_Info:CARGO[7]
                #DEFINE N_LarguraTela X_Info:CARGO[8]
                #DEFINE B_Edita X_Info:CARGO[3]
                #DEFINE B_Lista X_Info:CARGO[4]
                #DEFINE L_With_B_Lista X_Info:CARGO[18]
                #DEFINE B_Auto X_Info:CARGO[5]
                #DEFINE VX_Edicao   VX_SubObj
                #DEFINE B_Mess X_Info:CARGO[6]
                #DEFINE C_CorGet X_Info:COLORSPEC

                NAP_LOG("COLOR_GET: " + C_CorGet)
                N_EditId := NAP_EDIT( ;
                                        N_WindowNum,;
                                        N_Row + Lin1Livre(VX_Janela) - 1, ;
                                        N_Col + Col1Livre(VX_Janela), ;
                                        N_LarguraVar, ;
                                        X_Info:TYPE, ;
                                        X_Info:BLOCK, ;
                                        B_Edita, ;
                                        X_Info:PREBLOCK, ;
                                        X_Info:POSTBLOCK, ;
                                        B_Mess, ;
                                        B_FiltroTec, ;
                                        L_ScrollVertical)

                NAP_EDIT_COLOR(N_WindowNum, N_EditId, C_CorGet)

                // We create a wizard for editbox
                IF L_With_B_Lista
                    N_ButId := NAP_BUTTON(;
                                        N_WindowNum, ;
                                        N_Row + Lin1Livre(VX_Janela) - 1, ;
                                        N_Col + Col1Livre(VX_Janela) + N_LarguraVar + 1, ;
                                        N_Row + Lin1Livre(VX_Janela) - 1, ;
                                        N_Col + Col1Livre(VX_Janela) + N_LarguraVar + 3, ;
                                        NIL, ;
                                        NIL, ;
                                        .F., ;
                                        .F.)

                    NAP_EDIT_WIZARD(N_WindowNum, N_EditId, N_ButId, K_F4, B_Auto, B_Lista)
                ENDIF
                #UNDEF N_LarguraVar
                #UNDEF N_LarguraTela
                #UNDEF B_Edita
                #UNDEF B_Lista
                #UNDEF B_Auto
                #UNDEF VX_Edicao
                #UNDEF B_Mess

            ELSE
                #DEFINE B_Expressao X_Info[3]
                #DEFINE C_Pict      X_Info[4]
                #DEFINE C_CorSay    X_Info[5]
                N_LabelId := NAP_LABEL(N_WindowNum, N_Row + Lin1Livre(VX_Janela) - 1, N_Col + Col1Livre(VX_Janela), B_Expressao, L_ScrollVertical)
                NAP_LABEL_COLOR(N_WindowNum, N_LabelId, C_CorSay)
                #UNDEF B_Expressao
                #UNDEF C_Pict
                #UNDEF C_CorSay

            ENDIF
            #UNDEF L_E_Get
            NEXT

    ENDIF  // L_PrimAtivacao

    // This window has embedded windows and is its first ativation --> Not modal launch
    // We wait the activation of child windows before
    IF L_PrimAtivacao .AND. L_ComEmbutidas
        L_Aborta := .T.
    ELSE
        X_Retorno := NAP_WINDOW_MODAL(N_WindowNum, N_PaiWindowNum, 0)
        IF X_Retorno == NAP_MODAL_LAST_INPUT
            L_Aborta      :=  .F.
        ELSE
            L_Aborta      :=  .T.
        ENDIF
    ENDIF

ELSE  // .NOT. SOB_MODO_GRAFICO()

*
N_CursorAnt  := SET(_SET_CURSOR,SC_NONE)
C_ReadVarAnt := READVAR("")
*
IF N_LinCobertas # 0 .OR. N_ColCobertas # 0
   * limpar tela pois pode existir dados em qualquer posi��o, deixados
   * por ativa��es anteriores
   SCROLL(Lin1Livre(VX_Janela),Col1Livre(VX_Janela),;
          Lin2Livre(VX_Janela),Col2Livre(VX_Janela)  )
   *
   N_LinCobertas := N_ColCobertas := 0
ENDIF
*
* mostrar SAY/GETs que cabem na janela a partir do primeiro item, antes da edi��o
#DEFINE _POSITIVO 1
MostrarInfo(VX_Janela,1,_POSITIVO)
#UNDEF _POSITIVO
*
Rolamento_(VX_Janela, .F., N_LinCobertas#0, PreencheDados(VX_Janela,LEN(VX_SayGetList))#0, .F.)
*
* editar os GETs , a partir do primeiro
*
N_SayGetCor   :=  0
N_CodMovi     :=  ST_BAIXO
L_Alterado    :=  .F.
L_Aborta      :=  .F.
L_NaoSaltou   :=  .T.
L_Paginou     :=  .F.
ProximoGet(VX_Janela)
*
DO WHILE (N_SayGetCor <= LEN(VX_SayGetList) .AND. .NOT. L_Aborta)
   *
   PreparaTela(VX_Janela,N_SayGetCor)
   *
   IF VALTYPE(VX_SayGetList[N_SayGetCor]) == "O"
      *
      * � um GET, edit�-lo
      VX_Get := VX_SayGetList[N_SayGetCor]
      READVAR(UPPER(VX_Get:NAME))   // atualizar a memoria interna da funcao READVAR()
      *
      #DEFINE B_Mess VX_Get:CARGO[6]
      IF B_Mess # NIL
         SETPOS(LinMess(VX_Janela),Col1Livre(VX_Janela))      // mostrar
         DISPOUT(PADR(EVAL(B_Mess),N_LargJanela))             // mensagem
      ENDIF
      GetReader(VX_Janela,VX_Edicao,VX_Get)
      IF B_Mess # NIL
         SETPOS(LinMess(VX_Janela),Col1Livre(VX_Janela))      // limpar
         DISPOUT(SPACE(N_LargJanela))                         // mensagem
      ENDIF
      #UNDEF B_Mess
      *
   ELSE
      * se item for um SAY, trat�-lo da mesma forma que um GET saltado
      L_NaoSaltou := .F.
   ENDIF
   *
   ProximoGet(VX_Janela)
ENDDO
*
SET(_SET_CURSOR,N_CursorAnt)
READVAR( C_ReadVarAnt )
*
IF L_PrimAtivacao
   LOGA_AJTELAT(C_CdTela,C_Cabec,V_Lst_CdGET)  // LOGAR conte�do de telas
ENDIF
*
*
ENDIF

L_PrimAtivacao := .F.

RETURN .NOT. L_Aborta

*
***********************
STATIC FUNC PreparaTela ( VX_Janela , N_SayGetCor2 )
***********************
LOCAL N_Scroll := PreencheDados(VX_Janela,N_SayGetCor2)
#DEFINE VX_Edicao   VX_SubObj
*
IF N_Scroll # 0
   *
   SCROLL(Lin1Livre(VX_Janela),Col1Livre(VX_Janela),;
          Lin2Livre(VX_Janela),Col2Livre(VX_Janela),N_Scroll)
   N_LinCobertas := N_LinCobertas + N_Scroll
   *
   * se ultimo movimento foi pagina�ao de telas inteiras, remontar toda a tela
   IF L_Paginou
      L_Paginou := .F.
      MostrarInfo(VX_Janela,N_SayGetCor2,-N_Scroll)
   ENDIF
   *
ENDIF
*
* Se for um GET, sempre seta a linha e coluna real na tela
* Se for um SAY, sempre imprime na tela
*
* Se N_Scroll <  0  -  imprime tela da posi�ao atual at� o in�cio
* Se N_Scroll >  0  -  imprime tela da posi�ao atual at� o fim
* Se N_Scroll == 0  -  imprime somente o item atual
*
MostrarInfo(VX_Janela,N_SayGetCor2,N_Scroll)
*
IF N_Scroll # 0
   Rolamento_(VX_Janela, .F., N_LinCobertas#0, PreencheDados(VX_Janela, LEN(VX_SayGetList)) # 0, .F.)
ENDIF
*
#UNDEF VX_Edicao
*
RETURN NIL
*
#DEFINE VX_Edicao   VX_SubObj
#DEFINE X_Info      VX_SayGetList[N_SayGetCor2]
#DEFINE L_E_Get     (VALTYPE(X_Info) == "O")
********************
STAT FUNC LinVirtual ( VX_Janela, N_SayGetCor2 )
********************
RETURN IIF(L_E_Get,X_Info:CARGO[1],X_Info[1])
********************
STAT FUNC ColVirtual ( VX_Janela, N_SayGetCor2 )
********************
RETURN IIF(L_E_Get,X_Info:CARGO[2],X_Info[2])
#UNDEF L_E_Get
#UNDEF X_Info
#UNDEF VX_Edicao
*
***********************
STAT FUNC PreencheDados(VX_Janela,N_SayGetCor2,N_Lin,N_Col)
***********************
LOCAL N_LinRel        // linha relativa ao inicio da janela
LOCAL N_Scroll := 0   // rolamento necess�rio para incluir o GET na tela
*
N_Lin := LinVirtual(VX_Janela,N_SayGetCor2)
N_Col := ColVirtual(VX_Janela,N_SayGetCor2)
*
#DEFINE VX_Edicao   VX_SubObj
N_LinRel := N_Lin - N_LinCobertas
#UNDEF VX_Edicao
IF N_LinRel < 0
   N_Scroll := N_LinRel
ELSEIF N_LinRel >       (Lin2Livre(VX_Janela)-Lin1Livre(VX_Janela))
   N_Scroll := N_LinRel-(Lin2Livre(VX_Janela)-Lin1Livre(VX_Janela))
ENDIF
*
RETURN N_Scroll
*
***********************
STATIC FUNC MostrarInfo ( VX_Janela, N_SayGetCor2, N_Sentido )
***********************
LOCAL X_Info, N_Lin, N_Col, L_Continua := .T.
LOCAL C_TextoSay
*
* A WVW_Paint � executada em background, logo n�o existe controle sobre
* o momento da execu��o. Quando era executada durante a cria��o de GETs,
* �s vezes dava erro, pois as vari�veis internas dos objetos GETs n�o
* estavam todos setados ainda.
* Por isto foi criada a L_AtivaGui, mesmo sob o risco de, eventualmente,
* o elemento gr�fico do GET (box ou s�mbolo do drop-down) n�o ser desenhado.
* Na pr�tica, esta falta de redesenho raramente ocorreu...
*
#DEFINE VX_Edicao   VX_SubObj
L_AtivaGui := .F.
#UNDEF VX_Edicao
*
* Aten��o: a DispBegin() / DispEnd() s� podem ser usadas aqui
*          se os programadores n�o fizerem parada na express�o contida
*          nos SAYs  ("EVAL(B_Expressao)" abaixo).
DispBegin()
*
DO WHILE PreencheDados(VX_Janela,N_SayGetCor2,@N_Lin,@N_Col) == 0 .AND. L_Continua
   #DEFINE VX_Edicao   VX_SubObj
   X_Info := VX_SayGetList[N_SayGetCor2]
   *
   #DEFINE L_E_Get  (VALTYPE(X_Info) == "O")
   IF L_E_Get
      X_Info:ROW := N_Lin - N_LinCobertas + Lin1Livre(VX_Janela)
      X_Info:COL := N_Col - N_ColCobertas + Col1Livre(VX_Janela)
      X_Info:DISPLAY()
      *
      IF N_Col-N_ColCobertas+LarguraTela(X_Info:BLOCK,X_Info:PICTURE) > ;
         Col2Livre(VX_Janela)-Col1Livre(VX_Janela)+1  // largura da janela
         ? MEMVAR->ERRO_LARGURA
      ENDIF
      *
   ELSE
      #DEFINE B_Expressao X_Info[3]
      #DEFINE C_Pict      X_Info[4]
      #DEFINE C_CorSay    X_Info[5]
      *
      SETPOS(N_Lin-N_LinCobertas+Lin1Livre(VX_Janela),;
             N_Col-N_ColCobertas+Col1Livre(VX_Janela))
      IF C_Pict # NIL
         C_TextoSay := TRANSFORM(EVAL(B_Expressao),C_Pict)
      ELSE
         C_TextoSay := EVAL(B_Expressao)
      ENDIF
      DISPOUT(C_TextoSay,C_CorSay)
      *
      IF N_Col-N_ColCobertas+LEN(C_TextoSay) > ;
         Col2Livre(VX_Janela)-Col1Livre(VX_Janela)+1  // largura da janela
         ? MEMVAR->ERRO_LARGURA
      ENDIF
      *
      #UNDEF B_Expressao
      #UNDEF C_Pict
      #UNDEF C_CorSay
   ENDIF
   #UNDEF L_E_Get
   *
   IF N_Sentido > 0 .AND. N_SayGetCor2 < LEN(VX_SayGetList)
      N_SayGetCor2++
   ELSEIF N_Sentido < 0 .AND. N_SayGetCor2 > 1
      N_SayGetCor2--
   ELSE
      * Se somente um item, ou se limites da janela alcan�ados
      L_Continua := .F.
   ENDIF
   *
   #UNDEF VX_Edicao
ENDDO
*
DispEnd()
*
#DEFINE VX_Edicao   VX_SubObj
L_AtivaGui := .T.
#UNDEF VX_Edicao
*
RETURN NIL
*
*******************************************
STATIC PROC GetReader( VX_Janela, VX_Edicao, VX_Get )
*******************************************
*
* sinalizadores de estado do GET corrente (armazenado em VX_Get:EXITSTATE)

#DEFINE ST_EDITA      1         // continuar a edi��o do GET corrente
#DEFINE ST_NAO_EDITA  2         // finalizar a edi��o do GET corrente

LOCAL N_Tecla, L_Auto, B_Ajuda_Ant, B_F4_Ant
LOCAL L_Encontrou_Erro
*
* Em caso de GET de "DOMINIO/CAMPO/IDCAMPO" pode n�o dar foco
* e voltar automaticamente para o GET anterior !
L_NaoSaltou := GET_pode_ter_foco(VX_Edicao,VX_Get)
*
IF L_NaoSaltou  // GET pode receber foco

   #DEFINE B_Auto VX_Get:CARGO[5]
   L_Auto := EVAL(B_Auto)
   #UNDEF  B_Auto

   #DEFINE C_CdGET VX_Get:CARGO[9]
   B_Ajuda_Ant := SETKEY(K_F1,{||XXHELP(C_CdTela,C_Cabec,C_CdGET,V_Lst_CdGET)}) // salvar help anterior
   #UNDEF  C_CdGET

   #DEFINE B_Lista VX_Get:CARGO[4]
   B_F4_Ant := SETKEY(K_F4,NIL)
   #UNDEF B_Lista

   VX_Get:SETFOCUS()

   VX_Get:EXITSTATE := ST_EDITA
   *
   IF VX_Get:TYPEOUT           // check for initial typeout (no editable positions)
      VX_Get:EXITSTATE := ST_NAO_EDITA
      * Dar erro de execu��o, pois provavelmente � erro de programa��o
      * (Exemplo: GET em vari�vel texto com o bytes ("")).
      ? MEMVAR->ERRO_ASSUME_GET_SEM_POSICAO_EDITAVEL
   ENDIF
   *
   DO WHILE VX_Get:EXITSTATE == ST_EDITA

      #DEFINE N_LarguraVar  VX_Get:CARGO[7]
      #DEFINE N_LarguraTela VX_Get:CARGO[8]

      DO WHILE VX_Get:EXITSTATE == ST_EDITA
         SET(_SET_CURSOR,IIF(READINSERT(),SC_INSERT,SC_NORMAL))
         IF L_Auto
            L_Auto  := .F.
            N_Tecla := K_F4
         ELSE
            N_Tecla := INKEYX(0)
            * Teclas combinadas precisam de tratamento especial de "desempate" (ex: CTRL-C).
            N_Tecla := AjustaTecla(N_Tecla)
         ENDIF
         SET(_SET_CURSOR,SC_NONE)
         IF SETKEY(N_Tecla) # NIL
            IF VX_Get:CHANGED
               VX_Get:ASSIGN()       // ir p/ SETKEY com vari�vel atualizada
            ENDIF
            *
            SETPOS(VX_Get:ROW,VX_Get:COL+LEN(VX_Get:BUFFER))
            EVAL(SETKEY(N_Tecla), PROCNAME(4),PROCLINE(4),READVAR(),VX_Get)
            VX_Get:RESET()
            *
         ELSE
            GetApplyKey(VX_Janela,VX_Edicao,VX_Get,N_Tecla)  // aplicar tecla ao GET
            IF N_LarguraVar # N_LarguraTela
               Rola_Hori(VX_Get)
            ENDIF
         ENDIF
      ENDDO

      IF VX_Get:BADDATE .AND. .NOT. L_Aborta
         VX_Get:EXITSTATE := ST_EDITA       // n�o sair se data inv�lida
         IF B_ErroData # NIL
            SETPOS(VX_Get:ROW,VX_Get:COL+LEN(VX_Get:BUFFER))
            EVAL(B_ErroData)   // executar bloco de erro de data
            VX_Get:HOME()
         ENDIF
      ELSE
         IF VX_Get:CHANGED
            VX_Get:ASSIGN()
         ENDIF

         // reform edit buffer, set cursor to home position, redisplay
         VX_Get:RESET()

         IF N_LarguraVar # N_LarguraTela
            Rola_Hori(VX_Get)
         ENDIF

         IF N_CodMovi # ST_CIMA .AND. N_CodMovi # ST_PRIMEIRO .AND. ;
            N_CodMovi # ST_PGUP .AND. N_CodMovi # ST_MOUSE_CIMA .AND. ;
            .NOT. L_Aborta
            *
            L_Encontrou_Erro := ERRO_EM_VALIDACOES_PRE_VALID(VX_Edicao,VX_Get)
            *
            IF .NOT. L_Encontrou_Erro
               * Executar as checagens especificadas pelo programador no VALID
               L_Encontrou_Erro := .NOT. GetPostValidate(VX_Get)
            ELSE
               * Internamente, a GetPostValidate() deve executar a "Display()".
               * Em campos num�ricos, os d�gitos estavam aparecendo sem o alinhamento
               * autom�tico � direita, que � feito automaticamente quando se
               * chama a GetPostValidate()
               VX_Get:DISPLAY()
            ENDIF
            *
            IF L_Encontrou_Erro
               // disallow exit if the VALID condition is not satisfied
               VX_Get:EXITSTATE := ST_EDITA
               *
               * No clipper, os GETs num�ricos ou com a pict "@K"
               * s�o automaticamente limpos quando se digita qualquer tecla
               * (que n�o seja tecla de movimento):
               *      - na entrada inicial do Get (get ganhou foco)
               *      - na volta de um Valid que retornou .F.
               *
               * J� no Harbour, a limpeza da vari�vel do GET ocorre somente na entrada
               * inicial do Get. Quando se digita algo ap�s um Valid
               * a vari�vel do GET n�o � limpa, pois o Get n�o perdeu o foco.
               *
               * Para fazer com o Harbour tenha o mesmo comportamento
               * do clipper, abaixo ser� feita a limpeza "manual" da
               * vari�vel do GET, ap�s o valid ter falhado...
               *
               IF VX_Get:TYPE == "N"
                  VX_Get:Clear := .T.
               ELSEIF VX_Get:PICTURE # NIL
                  IF "K" $ VX_Get:PICTURE
                     VX_Get:Clear := .T.
                  ENDIF
               ENDIF
               *
            ENDIF
         ENDIF

      ENDIF

      #UNDEF N_LarguraVar
      #UNDEF N_LarguraTela

   ENDDO

   IF VX_Get:CHANGED         // se alterado desde que recebeu foco.
      L_Alterado := .T.
   ENDIF

   // de-activate the GET
   VX_Get:KILLFOCUS()

   #DEFINE C_CdGET VX_Get:CARGO[9]
   SETKEY(K_F1,B_Ajuda_Ant)   // restaurar help anterior
   #UNDEF  C_CdGET

   SETKEY(K_F4,B_F4_Ant)

ENDIF
*
RETURN
*
*********************************
STATIC FUNCTION GET_pode_ter_foco (VX_Edicao, VX_Get,;
                                   L_Encontrou_Erro)   // Por refer�ncia
*********************************
LOCAL L_GET_pode_ter_foco
LOCAL X_Conteudo_da_Variavel_do_GET
*
IF GetPreValidate(VX_Get)
   * WHEN retornou ".T." (GET ter� foco e VALID ser� executado)
   L_GET_pode_ter_foco   := .T.
   L_Encontrou_Erro := .F.  // N�o tem como encontrar erro aqui, pois VALID s� vai ser executado depois.
ELSE
   * WHEN retornou ".F." (comportamento dependar� do tipo de GET)
   L_GET_pode_ter_foco   := .F.
   *
   VX_Get:DISPLAY()          // mostrar vari�vel pois pode ter sido alterada
                             // na pr�-valida��o (muito comum).
   *
   #DEFINE C_Tipo_de_GET VX_Get:CARGO[11]
   IF C_Tipo_de_GET == "PADRAO"
      * Por padr�o, o VALID n�o � executado quando a WHEN retorna ".F."
      * O GET n�o ter� foco e ser� "saltado" pra frente, indo-se para o GET posterior.
      *
      L_Encontrou_Erro := .F.  // N�o tem como encontrar erro aqui, pois VALID nem ser� executado.
   ELSEIF C_Tipo_de_GET $ "DOMINIO/CAMPO/IDCAMPO"
      *
      IF N_CodMovi # ST_CIMA .AND. N_CodMovi # ST_PRIMEIRO .AND. ;
         N_CodMovi # ST_PGUP .AND. N_CodMovi # ST_MOUSE_CIMA .AND. ;
         .NOT. L_Aborta
         *
         * Executam o VALID mesmo que a WHEN retorne ".F." (comportamento n�o padr�o).
         *
         VX_Get:SETFOCUS() // o objetivo � apenas dar "cor de destaque" no GET que vai ser checado
         *
         L_Encontrou_Erro := ERRO_EM_VALIDACOES_PRE_VALID(VX_Edicao,VX_Get)
         *
         IF .NOT. L_Encontrou_Erro
            * Executar as checagens especificadas pelo programador no VALID
            IF GetPostValidate(VX_Get)
               * A VALID retornou ".T."
               * O GET n�o ter� foco e ser� "saltado" pra frente, indo-se para o GET posterior.
               L_Encontrou_Erro := .F.  // VALID foi executado e retornou .T.
            ELSE
               * A VALID retornou ".F."
               * O GET n�o ter� foco e ser� "saltado" pra tr�s, indo-se para o GET anterior.
               L_Encontrou_Erro := .T.  // VALID foi executado e retornou .F.
            ENDIF
         ENDIF
         *
         IF L_Encontrou_Erro
            N_CodMovi := ST_CIMA  // causa o retrocesso at� o �ltimo GET de parada, na pr�xima chamada da GetReader()
            *
            * IMPORTANTE:
            *   Se n�o existir GET anterior ou se todos os GETs anteriores
            *   n�o possam ter foco (WHEN de todos retornando .F.), a rotina de GET
            *   entrar� em "LOOP", exibindo repetidamente a mensagem de erro,
            *   n�o tendo como o usu�rio final sair da tela.
            *   Ser� preciso finalizar o programa, atrav�s do "Gerenciador de Tarefas".
            *
            *   Esta situa��o rara, caso ocorra, precisa ser resolvida atrav�s do
            *   desenvolvedor dar foco (WHEN retornando .T.), caso o conte�do da
            *   vari�vel GET seja inv�lido, como forma do usu�rio final poder como corrigir o conte�do.
         ENDIF
         *
         // de-activate the GET
         VX_Get:KILLFOCUS() // remover a "cor de destaque" do GET checado, pois foco n�o vai ficar nele
      ELSE
         * N�o executar a valida��o quando o cursor estiver "subindo" ou o usu�rio final tiver teclado ESC
      ENDIF
   ELSE
      ? MEMVAR->ERRO_ASSUME_TIPO_DE_GET_INVALIDO
   ENDIF
   #UNDEF C_Tipo_de_GET
ENDIF
*
RETURN  L_GET_pode_ter_foco
*
********************************************
STATIC FUNCTION ERRO_EM_VALIDACOES_PRE_VALID (VX_Edicao,VX_Get)
********************************************
LOCAL L_Encontrou_Erro := .F.
LOCAL X_Conteudo_da_Variavel_do_GET
*
#DEFINE C_Tipo_de_GET VX_Get:CARGO[11]
#DEFINE O_Dominio VX_Get:CARGO[12]
#DEFINE L_CampoOpcional VX_Get:CARGO[17]
*
IF C_Tipo_de_GET == "PADRAO"
   * N�o existe valida��o pr�via ao VALID.
ELSE
   X_Conteudo_da_Variavel_do_GET := EVAL(VX_Get:BLOCK)
   *
   IF EMPTY(X_Conteudo_da_Variavel_do_GET) .AND. L_CampoOpcional
      * � normal estar vazio
   ELSE
      IF C_Tipo_de_GET == "DOMINIO"
         * Executar as checagens da validade do dom�nio
         L_Encontrou_Erro := ERRO_EM_VALIDACOES_PRE_VALID_DOMINIO(VX_Edicao,VX_Get,;
                                                                  X_Conteudo_da_Variavel_do_GET)
      ELSEIF C_Tipo_de_GET == "CAMPO"
         *
         L_Encontrou_Erro := ERRO_EM_VALIDACOES_PRE_VALID_CAMPO(VX_Edicao,VX_Get,;
                                                                X_Conteudo_da_Variavel_do_GET)
         *
         IF O_Dominio # NIL .AND. ; // Campo tem dom�nio
            .NOT. L_Encontrou_Erro
            * Executar as checagens da validade do dom�nio
            L_Encontrou_Erro := ERRO_EM_VALIDACOES_PRE_VALID_DOMINIO(VX_Edicao,VX_Get,;
                                                                     X_Conteudo_da_Variavel_do_GET)
         ENDIF
      ELSEIF C_Tipo_de_GET == "IDCAMPO"
         ? MEMVAR->ERRO_ASSUME // Falta implementar
      ELSE
         ? MEMVAR->ERRO_ASSUME_TIPO_DE_GET_INVALIDO
      ENDIF
   ENDIF
ENDIF
*
#UNDEF C_Tipo_de_GET
#UNDEF O_Dominio
#UNDEF L_CampoOpcional
*
RETURN L_Encontrou_Erro
*
****************************************************
STATIC FUNCTION ERRO_EM_VALIDACOES_PRE_VALID_DOMINIO (VX_Edicao,VX_Get,;
                                                      X_Conteudo_da_Variavel_do_GET)
****************************************************
LOCAL L_Encontrou_Erro := .F.
LOCAL V_Lst_Erros, N_Pos_Primeiro_Erro_Grave
LOCAL C_Nome_a_Exibir
LOCAL C_CDMENS
*
#DEFINE O_Dominio VX_Get:CARGO[12]
#DEFINE L_CampoOpcional VX_Get:CARGO[17]
*
* PENDENTE - Quando texto tem h�fem seguido de tra�o "-;", � para "juntar numa linha s�"
* PENDENTE - Decidir se usa o nome completo do dom�nio ou no SAY do GET (n�o � confi�vel saber o SAY do GET)
*
* PENDENTE - Analisar se n�o � melhor exibir o texto do SAY associado ao GET
*            (nem sempre o SAY anterior � do GET atual !)

/*
* PENDENTE - REMOVER O C�DIGO ABAIXO, NO FINAL
IF EMPTY(X_Conteudo_da_Variavel_do_GET)
   C_Mensagem_de_Erro := "O conte�do atual do campo;"
                         "'"+Nome_sem_Ponto_e_Virgula(O_Dominio:NomeCompleto)+"';"
                         "deve ser preenchido com um;"+;
                         "dos conte�dos permitidos para o campo."
   ALARME("M40084",C_Mensagem_de_Erro)
ELSE
   C_Mensagem_de_Erro := "O conte�do atual do campo;"
                         "'"+Nome_sem_Ponto_e_Virgula(O_Dominio:NomeCompleto)+"';"
                         "� incompat�vel com a ;"+;
                         "lista de conte�dos permitidos para o campo."
   ALARME("M40082",C_Mensagem_de_Erro)
ENDIF
*/

C_Nome_a_Exibir := "O campo;"
IF O_Dominio:NomeCompleto # NIL
   C_Nome_a_Exibir += "'"+O_Dominio:NomeCompleto+"';"
ENDIF
*
V_Lst_Erros := O_Dominio:ChecarDado(.F.,;   // N�o � para a rotina de valida��o cancelar se encontrar erro grave
                                   L_CampoOpcional,;  // Informa se � opcional ter conte�do.
                                   C_Nome_a_Exibir,;
                                   X_Conteudo_da_Variavel_do_GET)
*
#UNDEF O_Dominio
#UNDEF L_CampoOpcional
*
N_Pos_Primeiro_Erro_Grave := ASCAN(V_Lst_Erros,{|V_SubV| V_SubV[1] >= _MENS_ERRO_GRAVE})
IF N_Pos_Primeiro_Erro_Grave # 0
   L_Encontrou_Erro := .T.
   *
   C_CDMENS := V_Lst_Erros[N_Pos_Primeiro_Erro_Grave,2]
   ALARME(C_CDMENS,V_Lst_Erros[N_Pos_Primeiro_Erro_Grave,3])
ENDIF
*
RETURN L_Encontrou_Erro
*
**************************************************
STATIC FUNCTION ERRO_EM_VALIDACOES_PRE_VALID_CAMPO (VX_Edicao,VX_Get,;
                                                    X_Conteudo_da_Variavel_do_GET)
**************************************************
LOCAL L_Encontrou_Erro := .F.
LOCAL V_Lst_Erros, N_Pos_Primeiro_Erro_Grave
LOCAL C_Nome_a_Exibir
LOCAL C_CDMENS
*
#DEFINE O_Campo VX_Get:CARGO[13]
#DEFINE L_CampoOpcional VX_Get:CARGO[17]
*
* PENDENTE - Quando texto tem h�fem seguido de tra�o "-;", � para "juntar numa linha s�"
* PENDENTE - Decidir se usa o nome do campo ou no SAY do GET (n�o � confi�vel saber o SAY do GET)
* PENDENTE - Se "nome completo" for muito grande, trocar pelo "nome resumido", se existir
* PENDENTE - Melhorar a descri��o do erro, usando as informa��es se � masculino / feminino, plural / singular
*              IF EMPTY(O_Campo[?])
*                 C_Nome_a_Exibir := "O campo "                   // fixo
*              ELSE
*                 C_Nome_a_Exibir := O_Campo[?]+" "  // ex: "O ", "A ", ...
*              ENDIF
*
C_Nome_a_Exibir := "O campo;"+;
                   "'"+O_Campo:NomeCompleto+"';"
*
V_Lst_Erros := O_Campo:ChecarConteudo(.F.,;   // N�o � para a rotina de valida��o cancelar se encontrar erro grave
                                      L_CampoOpcional,;  // Informa se � opcional ter conte�do.
                                      C_Nome_a_Exibir,;
                                      X_Conteudo_da_Variavel_do_GET)
*
#UNDEF O_Campo
#UNDEF L_CampoOpcional
*
N_Pos_Primeiro_Erro_Grave := ASCAN(V_Lst_Erros,{|V_SubV| V_SubV[1] >= _MENS_ERRO_GRAVE})
IF N_Pos_Primeiro_Erro_Grave # 0
   L_Encontrou_Erro := .T.
   *
   C_CDMENS := V_Lst_Erros[N_Pos_Primeiro_Erro_Grave,2]
   ALARME(C_CDMENS,V_Lst_Erros[N_Pos_Primeiro_Erro_Grave,3])
ENDIF
*
RETURN L_Encontrou_Erro
*
********************************
STATIC FUNCTION ValidacaoDoGetOK (VX_Edicao,VX_Get)
********************************
LOCAL L_Encontrou_Erro
*
IF GET_pode_ter_foco(VX_Edicao,VX_Get,@L_Encontrou_Erro)
   * Como o GET vai ter foco, o VALID � executado a posteriori
   IF L_Encontrou_Erro  // Nunca poder� j� ter encontrado erro
        ? MEMVAR->ERRO_ASSUME_ENCONTROU_ERRO_NAO_PODE_ESTAR_T
   ENDIF
   *
   L_Encontrou_Erro := ERRO_EM_VALIDACOES_PRE_VALID(VX_Edicao,VX_Get)
   *
   IF .NOT. L_Encontrou_Erro
      * Executar as checagens especificadas pelo programador no VALID
      L_Encontrou_Erro := .NOT. GetPostValidate(VX_Get)
   ENDIF
ELSE
   * Como o GET n�o vai ter foco, a pr�pria GET_pode_ter_foco() j�
   * executou o VALID, quando for poss�vel.
ENDIF
*
RETURN .NOT. L_Encontrou_Erro
*
************************************************************
STATIC PROC GetApplyKey(VX_Janela,VX_Edicao, VX_Get,N_Tecla)
************************************************************
*
LOCAL N_Pos
LOCAL C_Tecla, X_Aux, C_Aux
LOCAL N_Keyboard, N_mRow, N_mCol, N_RegiaoMouse, L_PodeExecutar
*
DO CASE
   CASE N_Tecla == K_TAB  .OR. N_Tecla == K_DOWN  .OR. ;
        N_Tecla == K_MWBACKWARD .OR. N_Tecla == K_ENTER
        N_CodMovi := ST_BAIXO
        VX_Get:EXITSTATE := ST_NAO_EDITA
   CASE N_Tecla == K_SH_TAB .OR. N_Tecla == K_UP  .OR. ;
        N_Tecla == K_MWFORWARD
        N_CodMovi := ST_CIMA
        VX_Get:EXITSTATE := ST_NAO_EDITA
   CASE N_Tecla == K_ESC
        // VX_Get:UNDO()
        VX_Get:DISPLAY()
        L_Aborta := .T.
        VX_Get:EXITSTATE := ST_NAO_EDITA
   CASE N_Tecla == K_CTRL_HOME
        N_CodMovi := ST_PRIMEIRO
        VX_Get:EXITSTATE := ST_NAO_EDITA
        L_Paginou := .T.
   CASE N_Tecla == K_PGUP
        N_CodMovi := ST_PGUP
        VX_Get:EXITSTATE := ST_NAO_EDITA
        L_Paginou := .T.
   CASE N_Tecla == K_CTRL_W_ARBITRADO_TECLADO  // N�o d� certo usar a K_CTRL_END diretamente
        * No Harbour, n�o d� para diferenciar entre o uso da K_CTRL_END e da K_CTRL_W,
        * pois ambas exigem que se pressione a tecla "Ctrl".
        N_CodMovi := ST_ULTIMO
        VX_Get:EXITSTATE := ST_NAO_EDITA
        L_Paginou := .T.
   CASE N_Tecla == K_PGDN
        N_CodMovi := ST_PGDN
        VX_Get:EXITSTATE := ST_NAO_EDITA
        L_Paginou := .T.
   CASE N_Tecla == K_INS
        SET(_SET_INSERT, !SET(_SET_INSERT) )
   CASE N_Tecla == K_HOME
        VX_Get:HOME()
   CASE N_Tecla == K_END
        VX_Get:END()
   CASE N_Tecla == K_RIGHT
        VX_Get:RIGHT()
   CASE N_Tecla == K_LEFT
        VX_Get:LEFT()
   CASE N_Tecla == K_CTRL_RIGHT
        VX_Get:WORDRIGHT()
   CASE N_Tecla == K_CTRL_LEFT
        VX_Get:WORDLEFT()
        *
   CASE N_Tecla == K_LBUTTONDOWN  .OR. N_Tecla == K_LDBLCLK
        *
        * PENDENTE - Caso um GET tenha WHEN .F. mas a VALID retorne .F.,
        *            a mensagem de erro n�o est� sendo exibida ao usu�rio
        *            clicar no GET, mesmo que o GET seja de dom�nio.
        *            O ideal seria exibir a mensagem de erro, logo antes de voltar
        *            para o GET anterior.
        *
        N_mRow := mRow()
        N_mCol := mCol()
        N_RegiaoMouse := RegiaoJanela_(VX_Janela,N_mRow,N_mCol,;
                                       Lin1Livre(VX_Janela),;
                                       Col1Livre(VX_Janela),;
                                       Lin2Livre(VX_Janela),;
                                       Col2Livre(VX_Janela),;
                                       @N_Keyboard)
        #INCLUDE "mousecua.ch"
        *
        IF N_RegiaoMouse == AREA_UTIL
           * clicou dentro da �rea dos SAY/GETs
           *
           * A vari�vel N_PosRegiaoSayGet � salva dentro da VX_Janela
           * para pode ser usada logo em seguida na ProximoGet().
           * Apesar de ser salva no objeto, n�o � usada entre
           * diferentes ativa�oes da Janela...
           *
           N_PosRegiaoSayGet := ASCAN(V_RegiaoSayGet,{|V_Regiao| ;
               N_MRow >= V_Regiao[1]-N_LinCobertas+Lin1Livre(VX_Janela) .AND. ;
               N_MRow <= V_Regiao[3]-N_LinCobertas+Lin1Livre(VX_Janela) .AND. ;
               N_MCol >= V_Regiao[2]-N_ColCobertas+Col1Livre(VX_Janela) .AND. ;
               N_MCol <= V_Regiao[4]-N_ColCobertas+Col1Livre(VX_Janela) })
           IF N_PosRegiaoSayGet # 0
              * Clicou dentro de um GET ou do s�mbolo de drop-down
              IF V_RegiaoSayGet[N_PosRegiaoSayGet,6] > N_SayGetCor
                 N_CodMovi := ST_MOUSE_BAIXO
                 VX_Get:EXITSTATE := ST_NAO_EDITA
              ELSEIF V_RegiaoSayGet[N_PosRegiaoSayGet,6] < N_SayGetCor
                 N_CodMovi := ST_MOUSE_CIMA
                 VX_Get:EXITSTATE := ST_NAO_EDITA
              ELSEIF V_RegiaoSayGet[N_PosRegiaoSayGet,6] == N_SayGetCor .AND. ;
                     V_RegiaoSayGet[N_PosRegiaoSayGet,5] == _REGIAO_DROP_DOWN
                 HB_KeyPut(K_F4)     // Clicou no s�mbolo de drop-down do GET atual
              ENDIF
           ENDIF
        ELSEIF N_Keyboard # NIL
           HB_KeyPut(N_Keyboard)
        ENDIF
        *
   CASE N_Tecla == K_CTRL_C_ARBITRADO_TECLADO .OR. ; // Copiar - N�o d� certo usar a K_CTRL_C diretamente
        N_Tecla == K_CTRL_C_ARBITRADO_TOOLBAR
        C_Aux := NIL
        X_Aux := VX_Get:UNTRANSFORM()
        IF VALTYPE(X_Aux) == "C"
           C_Aux := ALLTRIM(X_Aux)
        ELSEIF VALTYPE(X_Aux) == "D"
           C_Aux := DTOC(X_Aux)
        ELSEIF VALTYPE(X_Aux) == "N"
           * trocar o ponto decimal
           C_Aux := STRTRAN(STR(X_Aux),".",",")
        ENDIF
        IF C_Aux # NIL
           SETCLIPBOARD_ASPEC(C_Aux)
        ENDIF
   CASE N_Tecla == K_F2
        L_PodeExecutar := INABILITA_TECLA_F2(N_Tecla, VX_Janela)
        IF L_PodeExecutar
           * No Harbour, n�o d� para diferenciar entre o uso da K_CTRL_END e da K_CTRL_W,
           * pois ambas exigem que se pressione a tecla "Ctrl".
           HB_KEYPUT(K_CTRL_W_ARBITRADO_TECLADO) // N�o d� certo usar a K_CTRL_END diretamente
           HB_KEYPUT(K_TAB) // Esta segunda chamada n�o limpa o buffer de teclado.
        ENDIF
        #DEFINE B_Edita VX_Get:CARGO[3]
   CASE .NOT. EVAL(B_Edita) .OR. .NOT. EVAL(B_Edita_Global)
        #UNDEF B_Edita
        * N�o faz nada e evita a ativa��o de mensagens que alteram a vari�vel
   CASE N_Tecla == K_CTRL_X_ARBITRADO_TECLADO .OR. ; // Recortar - N�o d� certo usar a K_CTRL_X diretamente
        N_Tecla == K_CTRL_X_ARBITRADO_TOOLBAR
        C_Aux := NIL
        X_Aux := VX_Get:UNTRANSFORM()
        IF VALTYPE(X_Aux) == "C"
           C_Aux := ALLTRIM(X_Aux)
        ELSEIF VALTYPE(X_Aux) == "D"
           C_Aux := DTOC(X_Aux)
        ELSEIF VALTYPE(X_Aux) == "N"
           * trocar o ponto decimal
           C_Aux := STRTRAN(STR(X_Aux),".",",")
        ENDIF
        IF C_Aux # NIL
           SETCLIPBOARD_ASPEC(C_Aux)
           VX_Get:Home()
           VX_Get:DelEnd()
        ENDIF
   CASE N_Tecla == K_CTRL_V_ARBITRADO_TECLADO .OR. ; // Colar - N�o d� certo usar a K_CTRL_V diretamente
        N_Tecla == K_CTRL_V_ARBITRADO_TOOLBAR
        // PENDENTE - CRTL-V �s vezes permite colar caracteres min�sculos onde tem picture "@!".
        // PENDENTE - CRTL-V �s vezes permite colar caracteres sem passar pela TECLA_IMPRIMIVEL(),
        //            permitindo inserir caracteres de controle, inclusive.
        //          - Futuramente analisar isto detalhadamente e corrigir

        * limitar o PASTE ao tamanho do GET...
        C_Aux := GETCLIPBOARD_ASPEC()
        C_Aux := MEMOLINE(C_Aux,254,1)   // pegar s� a primeira linha
        C_Aux := ALLTRIM(C_Aux)
        * limitar ao tamanho do GET e ao que resta para ser digitado no GET
        C_Aux := LEFT(C_Aux,LEN(VX_Get:BUFFER)-VX_Get:POS+1)

        for N_Pos := 1 to len(C_Aux)
            VX_Get:Insert( SUBSTR(C_Aux,N_POS,1) )
        next

   CASE N_Tecla == K_CTRL_Z_ARBITRADO_TECLADO .OR. ; // "Undo" - N�o d� certo usar a K_CTRL_Z diretamente
        N_Tecla == K_CTRL_Z_ARBITRADO_TOOLBAR
        VX_Get:Undo()
        *
   CASE N_Tecla == K_F4
        IF VX_Get:CHANGED
           VX_Get:ASSIGN()       // ir p/ EVAL com vari�vel atualizada
        ENDIF
        *
        SETPOS(VX_Get:ROW,VX_Get:COL+LEN(VX_Get:BUFFER))
        #DEFINE B_Lista VX_Get:CARGO[4]
        X_Aux := EVAL(B_Lista)
        #UNDEF  B_Lista
        IF X_Aux # NIL
           N_CodMovi := ST_BAIXO
           VX_Get:EXITSTATE := ST_NAO_EDITA
           VX_Get:VARPUT(X_Aux)
        ENDIF
        VX_Get:RESET()
   CASE N_Tecla == K_BS
        VX_Get:BACKSPACE()
   CASE N_Tecla == K_DEL
        VX_Get:DELETE()
   // K_CTRL_T s� passar� a funcionar corretamente se for criada a K_CTRL_T_ARBITRADO_TECLADO.
   // Como praticamente ningu�m sequer conhece esta combina��o, n�o fazer.
   //CASE N_Tecla == K_CTRL_T
   //     VX_Get:DELWORDRIGHT()
   CASE N_Tecla == K_CTRL_Y_ARBITRADO_TECLADO   // Apagar linha - N�o d� certo usar a K_CTRL_Y diretamente
        VX_Get:DELEND()
   CASE N_Tecla == K_CTRL_BS
        VX_Get:DELWORDLEFT()
   CASE IIF(B_FiltroTec==NIL,.F.,_FILTROTEC_(B_FiltroTec,.T.))
        * caso seja verdade, tecla j� foi inserida no buffer do teclado
   OTHERWISE
        IF TECLA_IMPRIMIVEL(N_Tecla)
           C_Tecla := CHR(N_Tecla)
           IF VX_Get:PICTURE # NIL
              IF N_Tecla > 127 .AND. "@!" $ VX_Get:PICTURE
                 * A fun��o @! n�o passa para mai�sculas letras acentuadas em
                 * portugu�s automaticamente (ex: teclado com cedilha e capslock
                 * desligado � inserido o cedilha min�sculo).
                 C_Tecla := XUPPER(C_Tecla)
              ENDIF
           ENDIF
           IF VX_Get:TYPE == "N" .AND. (C_Tecla == "." .OR. C_Tecla == ",")
              VX_Get:TODECPOS()
           ELSE
              IF SET(_SET_INSERT)
                 VX_Get:INSERT(C_Tecla)
              ELSE
                 VX_Get:OVERSTRIKE(C_Tecla)
              ENDIF

              IF VX_Get:TYPEOUT .AND. !SET(_SET_CONFIRM)
                 IF ( SET(_SET_BELL) )
                    TONE(300,1)
                 ENDIF
                 N_CodMovi := ST_BAIXO
                 VX_Get:EXITSTATE := ST_NAO_EDITA
              ENDIF

           ENDIF

        ENDIF
ENDCASE
*
RETURN
*
#UNDEF ST_EDITA
#UNDEF ST_NAO_EDITA
*
*******************
STAT PROC Rola_Hori ( VX_Get )
*******************
LOCAL L_Esq, L_Dir, N_ColAnt := COL(), N_LinAnt := ROW()
*
#DEFINE N_DeslocaTela    (COL()-VX_Get:COL)
#DEFINE N_DeslocaBuffer  (VX_Get:POS-1)
*
* Se deslocamento na tela < deslocamento no buffer
L_Esq := ( N_DeslocaTela < N_DeslocaBuffer )
*
#DEFINE N_LarguraVar  VX_Get:CARGO[7]
#DEFINE N_LarguraTela VX_Get:CARGO[8]
*
* Se espa�o at� o final GET < espa�o at� o final do buffer
L_Dir := ( N_LarguraTela-N_DeslocaTela < N_LarguraVar - N_DeslocaBuffer)
*
SETPOS(VX_Get:ROW,VX_Get:COL+N_LarguraTela+1)
IF L_Esq .AND. L_Dir
   DEVOUT(CHR(29))
ELSEIF L_Dir
   DEVOUT(CHR(26))
ELSEIF L_Esq
   DEVOUT(CHR(27))
ELSE
   DEVOUT(" ")
ENDIF
SETPOS(N_LinAnt,N_ColAnt)
*
#UNDEF N_LarguraVar
#UNDEF N_LarguraTela
*
#UNDEF N_DeslocaTela
#UNDEF N_DeslocaBuffer
*
***********************************
STATIC FUNC GetPreValidate(VX_Get)
**********************************
LOCAL L_Entrar := .T.
*
IF VX_Get:PREBLOCK # NIL
   L_Entrar := EVAL(VX_Get:PREBLOCK, VX_Get)
   VX_Get:UPDATEBUFFER()
ENDIF
*
RETURN L_Entrar

***********************************
STATIC FUNC GetPostValidate(VX_Get)
***********************************
LOCAL X_Retorno
LOCAL L_Sair := .T.
*
IF VX_Get:POSTBLOCK # NIL
   X_Retorno := EVAL(VX_Get:POSTBLOCK, VX_Get)
   VX_Get:UPDATEBUFFER()
   IF VALTYPE(X_Retorno)=="L"    // o Valid retornou .T. ou .F.
      L_Sair := X_Retorno
   ELSEIF VALTYPE(X_Retorno)=="C"   // o Valid retornou uma mensagem de erro
      IF EMPTY(X_Retorno)
         L_Sair := .T.
      ELSE
         L_Sair := .F.
         ALARME("M01196",X_Retorno)
      ENDIF
   ELSE
      ? MEMVAR->TIPO_DE_DADO_NAO_ESPERADO_NA_CLAUSULA_VALID_DO_GET
   ENDIF
ENDIF
*
RETURN L_Sair
*
*
***********************************
STATIC FUNC ProximoGet( VX_Janela )
***********************************
LOCAL N_NovaLin
#DEFINE VX_Edicao   VX_SubObj
*
IF L_Aborta
   *
   * Se houver bloco de controle de abortagem, execut�-lo.
   * Caso o bloco retorne .F., a edi��o � continuada com o cursor na mesma posi��o.
   *
   IF B_Desiste # NIL
      L_Aborta := EVAL(B_Desiste)
   ENDIF
ELSE
   *
   * se o primeiro item n�o pode ser acessado ( SAY ou GET n�o edit�vel),
   * mudar o poss�vel status ST_CIMA, ST_PRIMEIRO, ST_PGUP, ST_MOUSE_CIMA
   * para ST_BAIXO, para evitar o loop sem fim.
   *
   IF N_SayGetCor == 1 .AND. .NOT. L_NaoSaltou       // se saltou o 1� item
      N_CodMovi := ST_BAIXO
   ENDIF
   *
   DO CASE
      CASE N_CodMovi == ST_BAIXO
           N_SayGetCor ++
      CASE N_CodMovi == ST_CIMA .AND. N_SayGetCor > 1
           N_SayGetCor --
      CASE N_CodMovi == ST_ULTIMO
           #DEFINE VX_Get    VX_SayGetList[N_SayGetCor]
           #DEFINE L_E_Get   VALTYPE(VX_SayGetList[N_SayGetCor]) == "O"
           *
           DO WHILE N_SayGetCor < LEN(VX_SayGetList) .AND. ;
              IIF(L_E_Get,;
                  ValidacaoDoGetOK(VX_Edicao,VX_Get),;
                  .T.)
              * Ao se teclar Ctrl-End, saltando GETs que eram preenchidos
              * na cl�usula WHEN, o novo conte�do n�o estava sendo exibido na tela,
              * muito embora a vari�vel tivesse realmente um novo conte�do.
              MostrarInfo(VX_Janela,N_SayGetCor,0)
              *
              N_SayGetCor ++
           ENDDO
           N_CodMovi := ST_CIMA  // causa o retrocesso at� o �ltimo GET de parada
      CASE N_CodMovi == ST_PRIMEIRO
           N_SayGetCor := 1
           N_CodMovi := ST_BAIXO
      CASE N_CodMovi == ST_PGUP
           * nova linha virtual := 1a. linha da tela atual - uma p�gina
           N_NovaLin := N_LinCobertas + 1 - ;
                        (Lin2Livre(VX_Janela)-Lin1Livre(VX_Janela)+1)
           *
           * retroceder atrav�s da lista at� encontrar a nova linha virtual
           DO WHILE N_SayGetCor > 1 .AND. ;
              LinVirtual(VX_Janela,N_SayGetCor) > N_NovaLin
              N_SayGetCor --
           ENDDO
           N_CodMovi := ST_CIMA
      CASE N_CodMovi == ST_PGDN
           * nova linha virtual := ultima linha da tela anterior + duas p�ginas
           N_NovaLin := N_LinCobertas - 1 + ;
                        2*(Lin2Livre(VX_Janela)-Lin1Livre(VX_Janela)+1)
           *
           DO WHILE N_SayGetCor < LEN(VX_SayGetList) .AND. ;
              LinVirtual(VX_Janela,N_SayGetCor) < N_NovaLin .AND. ;
              IIF(L_E_Get,;
                  ValidacaoDoGetOK(VX_Edicao,VX_Get),;
                  .T.)
              * Ao se teclar PgDn, saltando GETs que eram preenchidos
              * na cl�usula WHEN, o novo conte�do n�o estava sendo exibido na tela,
              * muito embora a vari�vel tivesse realmente um novo conte�do.
              MostrarInfo(VX_Janela,N_SayGetCor,0)
              *
              N_SayGetCor ++
           ENDDO
           N_CodMovi := ST_CIMA
      CASE N_CodMovi ==  ST_MOUSE_CIMA
           DO WHILE N_SayGetCor > 1 .AND. ;
              N_SayGetCor > V_RegiaoSayGet[N_PosRegiaoSayGet,6]
              N_SayGetCor --
           ENDDO
           N_CodMovi := ST_BAIXO
           *
           IF V_RegiaoSayGet[N_PosRegiaoSayGet,6] == N_SayGetCor .AND. ;
              V_RegiaoSayGet[N_PosRegiaoSayGet,5] == _REGIAO_DROP_DOWN
              HB_KeyPut(K_F4)     // Clicou no s�mbolo de drop-down do GET
           ENDIF
           *
      CASE N_CodMovi ==  ST_MOUSE_BAIXO
           DO WHILE N_SayGetCor < LEN(VX_SayGetList) .AND. ;
              N_SayGetCor < V_RegiaoSayGet[N_PosRegiaoSayGet,6] .AND. ;
              IIF(L_E_Get,;
                  ValidacaoDoGetOK(VX_Edicao,VX_Get),;
                  .T.)
              * Ao se clicar sobre GET, saltando outros GETs que eram preenchidos
              * na cl�usula WHEN, o novo conte�do n�o estava sendo exibido na tela,
              * muito embora a vari�vel tivesse realmente um novo conte�do.
              MostrarInfo(VX_Janela,N_SayGetCor,0)
              *
              N_SayGetCor ++
           ENDDO
           N_CodMovi := ST_CIMA
           *
           * Se conseguiu ir para o GET clicado (algum valid pode bloquear...)
           IF V_RegiaoSayGet[N_PosRegiaoSayGet,6] == N_SayGetCor .AND. ;
              V_RegiaoSayGet[N_PosRegiaoSayGet,5] == _REGIAO_DROP_DOWN
              HB_KeyPut(K_F4)     // Clicou no s�mbolo de drop-down do GET
           ENDIF
           *
           #UNDEF L_E_Get
           #UNDEF VX_Get
   ENDCASE
   *
   * Se houver bloco de controle de finaliza��o, execut�-lo.
   * Caso o bloco retorne .F., a edi��o � continuada com o cursor na posi��o
   * final.
   *
   IF N_SayGetCor > LEN(VX_SayGetList) .AND. B_Confirma # NIL
      IF .NOT. EVAL(B_Confirma)
         N_SayGetCor--
         N_CodMovi := ST_CIMA      // voltar saltando os SAYs e os GETs n�o edit�veis
      ENDIF
   ENDIF
   *
ENDIF
*
RETURN NIL
*
#UNDEF VX_Edicao
*
****************
FUNC _FILTROTEC_ ( B_FiltroTec2, L_Eh_Get )
****************
LOCAL C_Retorno := EVAL(B_FiltroTec2), L_FoiFiltrada := .F.
IF C_Retorno # NIL
   IF L_Eh_Get
      KEYBOARD C_Retorno
   ELSE
      KEYBOARD IIF(SET(_SET_INSERT),CHR(K_BS),CHR(K_LEFT))+C_Retorno+;
               IIF(SET(_SET_INSERT),"",SPACE(01)+CHR(K_LEFT))
   ENDIF
   L_FoiFiltrada := .T.
ENDIF
RETURN L_FoiFiltrada
*
**************************
STAT FUNC TECLA_IMPRIMIVEL (N_Tecla)
**************************
#INCLUDE "xx.ch"
LOCAL L_OK := .F.
IF N_Tecla >= 32 .AND. N_Tecla <= 126
   L_OK := .T.
ELSEIF CHR(N_Tecla) $ _AC_UM_SIM   // caracteres acentuados
   L_OK := .T.
ELSEIF N_Tecla==156 .OR. N_Tecla==245    // caracteres � e �
   L_OK := .T.
ELSEIF N_Tecla==174 .OR. N_Tecla==175    // caracteres + e � - usado no LT
   L_OK := .T.
ENDIF
RETURN L_OK
*
*

***************************
FUNC GetCdGET_Atual_Entrada(VX_Janela)
***************************
LOCAL C_CdGET_Atual := ""
LOCAL VX_Get
*
#DEFINE VX_Edicao   VX_SubObj
* verificar se ativa��o da entrada de dados n�o foi finalizada
* (mas ainda com a janela na tela, esperando outra ativa��o)
IF N_SayGetCor <= LEN(VX_SayGetList)
   * Se item atual for um GET
   * (nada impede que uma fun��o chamada de dentro de um SAY chame a ALARME()...)
   IF VALTYPE(VX_SayGetList[N_SayGetCor]) == "O"
      * � um GET
      VX_Get := VX_SayGetList[N_SayGetCor]
      #DEFINE C_CdGET VX_Get:CARGO[9]
      C_CdGET_Atual := C_CdGET  // ,V_Lst_CdGET)}) // salvar help anterior
      #UNDEF  C_CdGET
   ENDIF
ENDIF
#UNDEF VX_Edicao
*
RETURN C_CdGET_Atual

****************
Func AjustaTecla (N_Tecla)
****************
N_Tecla := AjustaTecla_vinda_por_Teclado(N_Tecla)
N_Tecla := AjustaTecla_vinda_por_HB_KeyPut(N_Tecla)
RETURN N_Tecla
*
***************************************
STAT Func AjustaTecla_vinda_por_Teclado (N_Tecla)
***************************************
#if defined(__PLATFORM__WINDOWS) || defined(__PLATFORM__Windows)
   IF CtrlPressed()
      * Teclas recebidas via digita��o direta no teclado.
      *
      IF N_Tecla==K_PGDN
         N_Tecla := K_CTRL_C_ARBITRADO_TECLADO
      ELSEIF N_Tecla==K_INS
         N_Tecla := K_CTRL_V_ARBITRADO_TECLADO
      ELSEIF N_Tecla==K_DOWN
         N_Tecla := K_CTRL_X_ARBITRADO_TECLADO
      ELSEIF N_Tecla==K_CTRL_LEFT
         N_Tecla := K_CTRL_Z_ARBITRADO_TECLADO
      ELSEIF N_Tecla==K_CTRL_END
         * N�o d� para diferenciar entre o uso da K_CTRL_END e da K_CTRL_W,
         * pois ambas exigem que se pressione a tecla "Ctrl".
         N_Tecla := K_CTRL_W_ARBITRADO_TECLADO
      ELSEIF N_Tecla==K_CTRL_N
         N_Tecla := K_CTRL_N_ARBITRADO_TECLADO
      ELSEIF N_Tecla==K_CTRL_Y
         N_Tecla := K_CTRL_Y_ARBITRADO_TECLADO
      ENDIF
   ENDIF
#elif defined(__PLATFORM__LINUX) || defined(__PLATFORM__Linux)                // ADAPTACAO_LINUX
   // Na plataforma LINUX n�o h� necessidade de tratar "ARBITRADO_TECLADO"?   // ADAPTACAO_LINUX
   // � necess�rio entender onde mais isso precisa ser tratado. //!!          // ADAPTACAO_LINUX
#else                                                                         // ADAPTACAO_LINUX
   #erro "C�digo n�o adaptado para esta plataforma"
#endif
*
RETURN N_Tecla
*
*****************************************
STAT Func AjustaTecla_vinda_por_HB_KeyPut (N_Tecla)
*****************************************
* Teclas recebidas via buffer do teclado (ex: HB_KeyPut() / Toolbar).
IF N_Tecla==K_CTRL_C_TROCADO_POR_K_CTRL_F9
   N_Tecla := K_CTRL_C_ARBITRADO_TOOLBAR
ELSEIF N_Tecla==K_CTRL_V_TROCADO_POR_K_CTRL_F10
   N_Tecla := K_CTRL_V_ARBITRADO_TOOLBAR
ELSEIF N_Tecla==K_CTRL_X_TROCADO_POR_K_CTRL_F11
   N_Tecla := K_CTRL_X_ARBITRADO_TOOLBAR
ELSEIF N_Tecla==K_CTRL_Z_TROCADO_POR_K_CTRL_F12
   N_Tecla := K_CTRL_Z_ARBITRADO_TOOLBAR
ENDIF
*
* Foi necess�rio tratar as teclas abaixo, pois a CtrlPressed()
* retorna .F. quando ocorre o seguinte:
*    - Usu�rio n�o est� pressionando a tecla CTRL
*    - Usu�rio usa a ToolBar para "jogar" uma tecla no buffer,
*      tecla esta que, se via teclado, exigiria o pressionamento da CTRL.
*
* Do conjunto de teclas que receberam um valor ARBITRADO
* na fun��o AjustaTecla_vinda_por_Teclado():
*
*   K_PGDN (transformada internamente a K_CTRL_C_ARBITRADO_TECLADO) - n�o precisou de ajuste
*   K_INS  (transformada internamente a K_CTRL_V_ARBITRADO_TECLADO) - n�o precisou de ajuste
*   K_DOWN (transformada internamente a K_CTRL_X_ARBITRADO_TECLADO) - n�o precisou de ajuste
*
*   As teclas K_CTRL_LEFT e K_CTRL_N n�o foram tratadas, pelo fato de n�o serem ativadas via Toolbar
*   (trat�-las futuramente, caso necess�rio)
*
IF N_Tecla==K_CTRL_END
   * N�o d� para diferenciar entre o uso da K_CTRL_END e da K_CTRL_W,
   * pois ambas exigem que se pressione a tecla "Ctrl".
   N_Tecla := K_CTRL_W_ARBITRADO_TECLADO
ELSEIF N_Tecla==K_CTRL_Y
   N_Tecla := K_CTRL_Y_ARBITRADO_TECLADO
ENDIF
*
RETURN N_Tecla
*
********************
function CtrlPressed()
********************
* returns state of CONTROL keys
// #define VK_CONTROL            17
return (GetKeyState(17) < 0)
*
**************************
STAT function ShiftPressed()
**************************
* returns state of SHIFT keys**
// #define VK_SHIFT            16
return (GetKeyState(16) < 0)
*
******************************
STATIC FUNC INABILITA_TECLA_F2(N_Tecla, VX_Janela) // A telca F2, na fun��o de SALVAR, s� � usada na especializa��o Entrada.
******************************
LOCAL L_RET := .T., N_CT
*

IF N_Tecla == K_F2
   IF CHECAR_MUDADADOS_COM_ESTE_SISTEMA_INABILITA()
      IF SELECT("XXPREG") # 0
         IF .NOT. EHPRINCIPAL(.F.)
            FOR N_CT := 1 TO LEN(V_RegiaoBotoes)
                IF UPPER(ALLTRIM(V_RegiaoBotoes[N_CT,_BOTAO_TEXTO_TRATADO_2])) == "F2=SALVAR"
                   L_RET := .F.
                ENDIF
            NEXT
         ENDIF
      ENDIF
   ENDIF
ENDIF
*
RETURN L_RET
*
#pragma BEGINDUMP
#include "hbapi.h"
#ifdef __WIN32__
#include <windows.h>

HB_FUNC( GETKEYSTATE )
{
   hb_retni( GetKeyState( hb_parni( 1 ) ) ) ;
}
#else
HB_FUNC( GETKEYSTATE )
{
   hb_retni( -1 );
}
#endif

#pragma ENDDUMP

**************************** FIM DO entrada.prg *******************************
