/* encoding: cp850 */
#INCLUDE "cua.ch"
#INCLUDE "gtnap.ch"

***********************************
PROC DOC_LINE(O_DOC, C_Line)
***********************************
    NAP_DOC_INSERT_TEXT(O_DOC, C_Line)
    NAP_DOC_INSERT_NEW_LINE(O_DOC)

***********************************
PROC TST_R00234
***********************************
LOCAL O_DOC := NAP_DOC_CREATE()

// Total chars by line
LOCAL N_Width := 80

// Field tabulations
LOCAL V_Tabs := {45, SDK_HALIGN_LEFT, 17, SDK_HALIGN_RIGHT, 18, SDK_HALIGN_RIGHT}
LOCAL C_Line := ""

IF OFFICE_ERROR("Erro ao criar documento de texto")
    RETURN
ENDIF

// Header, footer and page margins config
NAP_DOC_PAGE_HEADER_SHOW(O_DOC, .T.)
NAP_DOC_PAGE_HEADER_MARGINS(O_DOC, 254, 280, 508, 102, .T., .T.)
NAP_DOC_PAGE_FOOTER_SHOW(O_DOC, .T.)
NAP_DOC_PAGE_FOOTER_MARGINS(O_DOC, 354, 380, 608, 202, .T., .T.)
NAP_DOC_PAGE_MARGINS(O_DOC, 2819, 178, 1270, 533, 0)

// Create and empty header with some line breaks
NAP_DOC_TEXT_SPACE(O_DOC, SDK_TEXT_SPACE_HEADER)
NAP_DOC_FONT_FAMILY(O_DOC, "Times New Roman")
NAP_DOC_FONT_SIZE(O_DOC, 10.0)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)

// Set the text space to main page
NAP_DOC_TEXT_SPACE(O_DOC, SDK_TEXT_SPACE_PAGE)
NAP_DOC_FONT_FAMILY(O_DOC, "Courier New")
NAP_DOC_FONT_SIZE(O_DOC, 10.0)
NAP_DOC_PARAGRAPH_LSPACING(O_DOC, 330)
DOC_LINE(O_DOC, "Cear�")
DOC_LINE(O_DOC, "Governo Municipal de Piquet Carneiro")
DOC_LINE(O_DOC, "Consolidado")
DOC_LINE(O_DOC, "         T E R M O    D E    C O N F E R � N C I A    D E    C A I X A")
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
DOC_LINE(O_DOC, "       Nesta data, em  cumprimento �s exig�ncias estabelecidas por Lei, o abaixo")
DOC_LINE(O_DOC, "assinado, tesoureiro do(a)  Prefeitura  Municipal de Piquet Carneiro, procedeu �")
DOC_LINE(O_DOC, "verifica��o dos valores   existentes   no   Caixa   deste(a)  Prefeitura,  tendo")
DOC_LINE(O_DOC, "encontrado o seguinte:")
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
DOC_LINE(O_DOC, "a) CAIXA____:  R$ 0,00 (Zero Real).")
NAP_DOC_INSERT_NEW_LINE(O_DOC)
DOC_LINE(O_DOC, "b) BANCOS___:  R$ 12.794.126,25 (Doze  Milh�es,  Setecentos  e  Noventa e Quatro")
DOC_LINE(O_DOC, "               Mil, Cento e Vinte e Seis Reais e Vinte e Cinco Centavos).")
NAP_DOC_INSERT_NEW_LINE(O_DOC)
DOC_LINE(O_DOC, "c) EXATORES.:  R$ 0,00 (Zero Real).")
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
DOC_LINE(O_DOC, "       Os valores acima  mencionados  foram  verificados  por  mim � vista do(a)")
DOC_LINE(O_DOC, "Sr.(a). PREFEITO MUNICIPAL  que  tamb�m  assina o presente e achado certo com os")
DOC_LINE(O_DOC, "registros do Livro  de  Caixa  existente nesta Tesouraria, nesta data, no ato do")
DOC_LINE(O_DOC, "encerramento do expediente.")
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
DOC_LINE(O_DOC, "Visto:                                   Piquet Carneiro, 31 de Janeiro de 2023.")
NAP_DOC_FONT_SIZE(O_DOC, 6.0)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
NAP_DOC_INSERT_TEXT(O_DOC, "                          ")
NAP_DOC_INSERT_DASH(O_DOC, 38)
NAP_DOC_INSERT_TEXT(O_DOC, "   ")
NAP_DOC_INSERT_DASH(O_DOC, 38)
NAP_DOC_INSERT_NEW_LINE(O_DOC)
DOC_LINE(O_DOC, "                                 BISMARCK BARROS BEZERRA             WEYNE CESAR MACHADO DO NASCIMENTO")

// Save the document
NAP_DOC_SAVE(O_DOC, {|| NAP_WORK_PATH() + "/../office/ods_gen/Exemple_R00234.odt" })
OFFICE_ERROR("Erro ao salvar documento de texto")

// Export to PDF
NAP_DOC_PDF(O_DOC, {|| NAP_WORK_PATH() + "/../office/ods_gen/Exemple_R00234.pdf" })
OFFICE_ERROR("Exportando para PDF")

// Close the document (mandatory)
NAP_DOC_CLOSE(O_DOC)
OFFICE_ERROR("Erro ao fechar o documento de texto")

MOSTRAR("M15566", "O documento de texto foi criado com sucesso.")

// Open the result into a LibreOffice window
NAP_OFFICE_BROWSE_DOC(NAP_WORK_PATH() + "/../office/ods_gen/Exemple_R00234.odt")
