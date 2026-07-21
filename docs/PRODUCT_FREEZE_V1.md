# HelpBari — Product Freeze V1

Status: **fonte principal de verdade do produto V1**  
Escopo: produto, experiência, contratos conceituais, compatibilidade e gates  
Público: Produto, UX/UI, Engenharia, QA, Segurança, novos colaboradores e agentes de IA

## 1. Finalidade deste documento

Este documento consolida as decisões aprovadas para a V1 do HelpBari. Ele é a
referência obrigatória para implementação, UX/UI, arquitetura, testes, revisão
de produto e avaliação de novas features.

Em caso de divergência com documentos anteriores de produto ou roadmap, este
Product Freeze prevalece para o escopo visível da V1. Documentos arquiteturais
das Macros 1, 2 e 3 continuam normativos para suas autoridades, invariantes,
persistência, sincronização, segurança e compatibilidade.

Este documento diferencia deliberadamente:

- o produto percebido pelo paciente;
- as capacidades internas que sustentam o produto;
- o estado atual, que será adaptado em lotes;
- possibilidades futuras, que não são requisitos da V1.

O Product Freeze não autoriza remoções físicas, mudanças destrutivas ou o
início da Macro 4.

## 2. Visão do produto

> **O HelpBari é o companheiro diário do paciente bariátrico.**

O produto deve ajudar o paciente a responder:

1. O que preciso fazer agora?
2. O que ainda falta hoje?
3. Como estou evoluindo?
4. Onde encontro os outros recursos?

O HelpBari não deve ser percebido como:

- prontuário hospitalar;
- sistema administrativo;
- sistema técnico de prescrições;
- lista de features isoladas;
- ferramenta que substitui profissionais de saúde.

## 3. Princípios obrigatórios da V1

1. **Foco no paciente.** A experiência é avaliada pelo valor e pela clareza
   para o paciente, não pela quantidade de capacidades técnicas expostas.
2. **Simplicidade antes de exposição técnica.** Conceitos internos não devem
   virar conceitos que o paciente precise aprender.
3. **Regra de decisão.** Uma feature visível deve resolver um problema do
   paciente, e não expor uma decisão da arquitetura.
4. **Offline-first.** Drift permanece fonte local de verdade para os domínios
   suportados e a experiência deve continuar útil sem rede.
5. **Local-first nas operações suportadas.** Escritas são confirmadas
   localmente e não aguardam o Supabase para liberar a interface.
6. **Sincronização resiliente.** O Sync Engine existente é reutilizado; falha
   remota não pode desfazer sucesso local válido.
7. **LGPD e minimização.** Todo dado coletado precisa de finalidade, fonte
   canônica, consumidor e ciclo de exportação/exclusão definidos.
8. **Sem informação clínica inventada.** Ausência de dado não pode gerar fato,
   orientação ou classificação artificial.
9. **Sem percentuais artificiais.** Dado insuficiente, não aplicável ou sem
   denominador nunca é apresentado como zero.
10. **Sem recomendação médica automática.** O app não diagnostica, prescreve,
    ajusta dose, recomenda compensação ou orienta interrupção.
11. **Notificações opcionais e configuráveis.** O aplicativo funciona
    integralmente com todas as notificações desativadas.
12. **Onboarding como configuração inicial.** Não é apenas cadastro de conta;
    prepara o produto para o uso do paciente.
13. **BarIA contextual e segura.** Usa contexto minimizado, explica registros e
    não substitui a equipe de saúde.
14. **Histórico preservado.** Mudanças de tratamento não reescrevem o passado.
15. **Compatibilidade.** Usuários, dados, rotas e integrações anteriores devem
    continuar seguros durante a transição.
16. **Simplicidade visual não é remoção da arquitetura.** Ocultar uma entrada
    não autoriza apagar contratos, dados ou infraestrutura.
17. **Nenhuma remoção destrutiva na V1.** Tabelas, migrations e históricos
    permanecem preservados.

## 4. Vocabulário visível

A navegação principal possui exatamente quatro áreas:

1. **Hoje**
2. **Tratamento**
3. **Evolução**
4. **Mais**

A BarIA não ocupa uma quinta aba.

| Área | Pergunta respondida | Responsabilidade |
| --- | --- | --- |
| Hoje | O que preciso fazer hoje? | Ações, agenda e acompanhamento operacional do dia |
| Tratamento | O que preciso tomar ou acompanhar? | Itens, horários, registros e detalhes do tratamento |
| Evolução | Como meus registros mudaram ao longo do tempo? | Resumos, tendências, históricos e relatórios |
| Mais | Onde encontro recursos usados com menor frequência? | Acompanhamento eventual, conteúdo, conta, privacidade e ajuda |

Termos técnicos internos não devem aparecer para o paciente. Isso inclui
`Smart Routine`, `occurrence`, `plan revision`, `mixed`, `coverage`, `cutover`
e status técnico de sync. A interface deve traduzir esses estados para
linguagem direta, segura e não julgadora.

## 5. Navegação principal

A V1 usa navegação inferior com Hoje, Tratamento, Evolução e Mais. As telas-raiz
mantêm acesso discreto à BarIA. Formulários, detalhes, históricos e relatórios
podem ser empilhados sobre a área de origem.

Regras:

- alternar área não executa uma ação clínica;
- voltar retorna ao contexto de origem sempre que possível;
- ações usam verbos claros; destinos usam nomes de áreas ou recursos;
- um botão global de adição sem contexto não faz parte da V1;
- rotas legadas permanecem compatíveis ou recebem redirecionamento seguro;
- deep links são processados somente após resolver sessão e onboarding;
- nenhum deep link pode abrir dados de outro usuário;
- Relatórios acessados por Evolução ou Mais abrem a mesma capacidade e rota;
- BarIA abre sobre a origem e não substitui a navegação principal.

Mapa conceitual:

```text
HelpBari
├── Hoje
│   ├── Agora
│   ├── Seu dia — Hoje / próximos 7 dias
│   ├── Como está seu dia
│   ├── Insight contextual
│   └── Ações principais
├── Tratamento
│   ├── Hoje
│   ├── Itens
│   ├── Adicionar item
│   └── Detalhe e histórico contextual
├── Evolução
│   ├── Peso
│   ├── Hidratação
│   ├── Alimentação e proteína
│   ├── Tratamento
│   ├── Health Score
│   ├── Bioimpedância
│   └── Relatórios
└── Mais
    ├── Acompanhamento
    ├── Conteúdo
    ├── Conta e preferências
    ├── Privacidade e dados
    └── Ajuda
```

## 6. Área Hoje

Hoje é a Home da V1. Sua composição está congelada nesta ordem:

1. cabeçalho curto;
2. status offline ou de sincronização, somente quando relevante;
3. Agora, com no máximo uma ação;
4. Seu dia, com Hoje e próximos 7 dias;
5. Como está seu dia;
6. no máximo um insight contextual;
7. até quatro ações principais;
8. acesso discreto à BarIA.

### 6.1 Cabeçalho

Contém saudação curta, data e acesso ao Perfil. Não deve competir com a próxima
ação nem exibir detalhes clínicos sensíveis.

### 6.2 Status offline e sincronização

Só aparece quando existir informação útil. Dados locais continuam disponíveis.
Fila normal de sincronização não deve ser apresentada como falha clínica.

Mensagens preferidas:

- “Dados deste aparelho disponíveis.”
- “Algumas atualizações aguardam sincronização.”
- “Atualizado anteriormente.”

### 6.3 Agora

Exibe no máximo uma ação principal. A prioridade é determinística e considera,
em ordem geral:

1. conflito que exige revisão;
2. item de tratamento em janela aberta;
3. consulta próxima;
4. outra ação diária realmente executável.

Sem ação aplicável, o bloco é ocultado. O mesmo item pode continuar em Seu dia,
mas não com a mesma ênfase ou com CTA principal duplicado.

### 6.4 Seu dia

É uma agenda única com alternância entre Hoje e próximos 7 dias. Reúne
ocorrências de tratamento e consultas. Não existem seções separadas para
“Agenda de hoje” e “Próximos compromissos”.

Estados visuais distinguem:

- executável;
- informativo;
- futuro;
- concluído;
- cancelado;
- sem registro;
- requer revisão.

PRN sem uso não aparece como pendência. Exames realizados não são compromissos.
Falha de uma fonte não remove os demais itens disponíveis.

### 6.5 Como está seu dia

É um resumo compacto e não julgador. Pode apresentar:

- Tratamento, quando houver expectativas válidas;
- Água, quando o acompanhamento e a meta estiverem habilitados;
- Alimentação/proteína, quando o acompanhamento estiver habilitado.

Peso não é indicador diário permanente. Pode aparecer de forma contextual,
sem criar cobrança diária.

Exemplos:

- “2 de 3 concluídos”;
- “800 ml de 1.500 ml”;
- “2 refeições registradas”;
- “Ainda não configurado”;
- “Sem dados suficientes”.

### 6.6 Insight

No máximo um insight determinístico, curto, seguro e relevante. Pode ter ação
“Entender melhor”, que abre a BarIA com contexto minimizado. Sem insight útil,
o bloco é ocultado.

### 6.7 Ações principais

As quatro ações da V1 são:

1. Registrar água;
2. Registrar refeição;
3. Ver tratamento;
4. Adicionar consulta.

Tocar em uma ação de navegação não registra dados. Em particular, abrir Água
não pode adicionar volume automaticamente. Escritas suportadas são locais
primeiro e fornecem feedback específico.

### 6.8 Conteúdo excluído da Home permanente

A Home não mostra permanentemente:

- Health Score completo;
- prescrições;
- documentos;
- relatórios;
- configurações;
- Academia Bariátrica;
- menu geral de features;
- múltiplas agendas;
- card grande da BarIA;
- múltiplos insights;
- históricos extensos.

### 6.9 Resiliência

Falhas são isoladas por bloco. Um domínio indisponível não bloqueia toda a
Home. Durante atualização, o snapshot anterior permanece quando for seguro. Um
erro técnico não pode ser traduzido em conclusão sobre a saúde do paciente.

## 7. Área Tratamento

Tratamento é a única experiência visível para itens que o paciente precisa
tomar ou acompanhar.

Categorias:

- Medicamento;
- Vitamina;
- Suplemento;
- Outro.

Categorias servem para classificar, filtrar, apresentar e agregar. Elas não
criam features ou destinos principais separados.

### 7.1 Estrutura V1

- Hoje;
- Itens;
- Adicionar item;
- detalhe do item;
- histórico contextual no detalhe ou em acesso secundário.

A V1 não cria uma aba principal de Histórico sem validação posterior de uso.

### 7.2 Comportamentos obrigatórios

- múltiplos horários;
- dias específicos;
- uso único;
- quando necessário;
- período definido;
- uso contínuo somente por escolha explícita;
- duração não informada como estado distinto;
- edição aplicada ao futuro;
- histórico preservado;
- pausa;
- conclusão;
- exclusão lógica;
- lembretes por item ou horário quando suportado;
- conflito tratado por revisão, nunca por escolha silenciosa;
- PRN sem pendência recorrente.

Ausência de duração nunca significa uso contínuo. Alterar categoria, dose,
frequência, horários, dias ou vigência não pode reinterpretar o passado.

### 7.3 Autoridade interna

Smart Routines permanece a autoridade de Tratamento. O modelo preserva rotina,
planos versionados, schedules, ocorrências, eventos, pausas, coverage e origem.
Unified Treatment Engine permanece interno e controla migração, cutover e
compatibilidade. A interface não expõe essas estruturas.

Medications e Vitamins permanecem como fachadas/legado durante a transição,
mas deixam de ser destinos principais separados.

## 8. Prescrições

A decisão da V1 está congelada:

- Prescrições não são uma feature visível;
- não existe aba Prescrições;
- não existe card permanente de Prescrições;
- não existe destino principal em Hoje, Tratamento, Evolução ou Mais;
- nenhum novo fluxo de criação ou importação é priorizado na V1;
- documentos podem continuar armazenados como documentos;
- prescrições podem continuar internamente como origem ou vínculo;
- rotas, tabelas, migrations, dados, contratos, sync, provenance e LGPD são
  preservados;
- pendências e deep links legados recebem fallback seguro;
- nenhum dado é apagado;
- nenhuma remoção física pertence a este ciclo.

Os termos possuem significados diferentes:

| Ação | Significado na V1 | Aprovada? |
| --- | --- | --- |
| Ocultar da experiência | Retirar entradas permanentes e promoção visual | Sim |
| Congelar evolução | Não priorizar novos fluxos ou capacidades visíveis | Sim |
| Manter compatibilidade | Preservar dados, rotas, sync e fallbacks | Sim, obrigatório |
| Depreciar visualmente | Indicar que a entrada principal não pertence ao produto V1 | Sim |
| Remover fisicamente | Apagar código, tabela, migration, rota ou dado | Não |

Prescription Platform não é removida nem enfraquecida como infraestrutura.
Prescrição também não é sinônimo de tratamento ativo: qualquer uso futuro como
origem exige revisão e vínculo seguro.

## 9. Área Evolução

Evolução contém:

- Peso;
- Hidratação;
- Alimentação e proteína;
- Tratamento;
- Health Score;
- Bioimpedância;
- Relatórios.

A entrada é simples, rolável e centrada em resumos limitados. Históricos e
gráficos detalhados são carregados sob demanda. A área não deve parecer um
dashboard administrativo nem materializar todos os históricos no bootstrap.

Comparações só são apresentadas com dados equivalentes e suficientes. Sem
dados, a interface explica o que falta e não desenha tendências ou zeros
artificiais.

### 9.1 Health Score

Health Score:

- fica fora da Home;
- é opcional;
- não é diagnóstico;
- não representa aprovação ou reprovação;
- explica componentes participantes;
- explica dados ausentes;
- remove componentes indisponíveis do denominador;
- apresenta coverage em linguagem compreensível;
- identifica período e fórmula/versionamento quando necessário;
- contém disclaimer.

Não usar linguagem como “ruim”, “falhou”, “inadequado” ou “você não
conseguiu”.

### 9.2 Relatórios

Relatórios podem ser acessados por Evolução e Mais. As duas entradas abrem a
mesma capacidade, usam as mesmas autoridades e não duplicam lógica ou estado.

## 10. Área Mais

### 10.1 Acompanhamento

- Consultas;
- Exames;
- Documentos;
- Relatórios.

### 10.2 Conteúdo

- Academia Bariátrica;
- Favoritos;
- Histórico de leitura, quando disponível.

### 10.3 Conta e preferências

- Perfil;
- Configurações;
- Notificações.

### 10.4 Privacidade e dados

- Consentimentos;
- Exportar dados;
- Excluir dados ou conta.

Privacidade, exportação e exclusão permanecem encontráveis em no máximo dois
níveis. Confirmação e reautenticação podem ser exigidas, mas não justificam
ocultação excessiva.

### 10.5 Ajuda

- BarIA;
- Central de ajuda;
- Termos;
- Sobre.

Prescrições não aparecem em Mais.

## 11. Onboarding V1

> **O onboarding é a configuração inicial personalizada do HelpBari.**

Não é apenas cadastro de usuário.

Fluxo obrigatório:

1. autenticar;
2. resolver o usuário atual;
3. carregar estado local e remoto;
4. verificar se o onboarding está completo;
5. se incompleto, iniciar ou retomar;
6. se completo, abrir Hoje.

O onboarding aparece após login ou registro sempre que ainda não estiver
concluído. Não reaparece em todo login quando já estiver completo.

Pode reaparecer parcialmente quando:

- o usuário concluiu uma versão anterior;
- uma informação realmente obrigatória foi adicionada;
- existe inconsistência em dado obrigatório;
- consentimento obrigatório precisa ser renovado.

### 11.1 Estados conceituais

- `notStarted`;
- `inProgress`;
- `completed`;
- `needsReview`.

### 11.2 Contrato conceitual

O contrato técnico futuro utiliza:

- `userId`;
- versão do onboarding;
- ID estável da etapa atual;
- IDs estáveis das etapas concluídas;
- data de início;
- data de atualização;
- data de conclusão;
- status de sincronização;
- retomada local;
- compatibilidade com usuários antigos.

Índice de enum não é contrato persistido definitivo. Falha de rede não bloqueia
indefinidamente o usuário quando existir estado local válido e consistente.

## 12. Etapas do onboarding

| Etapa | Objetivo | Dados | Obrigatórios / opcionais | Pode pular? | Fonte canônica | Consumidores | Edição futura | Offline |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. Boas-vindas | Explicar propósito e limites | Nenhum dado clínico | Nenhum | Sim após leitura | Não aplicável | Compreensão do produto | Não aplicável | Integral |
| 2. Consentimentos | Obter bases obrigatórias | Aceites e versões | Obrigatórios para continuar | Não | PrivacyConsent | Router, LGPD, BarIA quando aplicável | Mais > Privacidade | Salvar local e sincronizar depois |
| 3. Perfil básico | Identificar e calcular dados básicos | Nome, e-mail, nascimento, altura | Nome/e-mail e dados necessários ao perfil são obrigatórios conforme contrato; demais explicitados na UI | Parcialmente | Auth + Profile | Perfil, Evolução, Reports | Mais > Perfil | Local-first |
| 4. Jornada bariátrica | Contextualizar evolução | Data e tipo de cirurgia | Obrigatoriedade depende do contrato de Perfil vigente | Somente opcionais | Profile | Evolução, Reports, BarIA minimizada | Perfil | Local-first |
| 5. Peso e metas | Criar referência inicial | Peso inicial; peso atual e meta opcionais | Peso inicial conforme Perfil; atual/meta opcionais | Opcionais sim | Profile + WeightRecord | Hoje, Evolução, Reports, Score | Evolução > Peso / Perfil | Local-first |
| 6. O que acompanhar | Configurar superfície do produto | Tratamento, Água, Alimentação, Peso | Escolha explícita; nenhuma categoria clínica cadastrada automaticamente | Sim, com defaults conservadores | Settings/preferências de acompanhamento | Hoje, Tratamento, Evolução, Notifications | Configurações | Local-first |
| 7. Metas selecionadas | Configurar recursos habilitados | Meta de água e preferência de alimentação | Obrigatórios somente para recurso que exigir configuração; sem meta inventada | Sim, desabilitando o recurso | Settings | Water, Meals, Hoje, Reports | Configurações | Local-first |
| 8. Lembretes | Registrar intenção inicial | “Quero receber lembretes” | Decisão explícita; permissão do SO é separada | Sim | Notification preferences; permissão local | Scheduler e categorias | Mais > Notificações | Preferência local-first; pedido ao SO quando disponível |
| 9. Conclusão | Confirmar configuração válida | Estado e timestamps | Requisitos mínimos e consentimentos | Não | OnboardingState | Router | Retomada/revisão versionada | Pode concluir localmente quando válido |

## 13. O que você deseja acompanhar?

A V1 inclui uma etapa explícita com estas opções:

- Tratamento;
- Água;
- Alimentação;
- Peso.

Regras:

- Tratamento pode ser recomendado, mas não presume item cadastrado;
- Água habilita meta, progresso e lembretes opcionais;
- Alimentação habilita registro, progresso e lembretes opcionais;
- Peso habilita ações e evolução relacionadas;
- recurso desativado não ocupa permanentemente a Home;
- as escolhas podem ser alteradas em Configurações;
- desativar acompanhamento não apaga histórico;
- exercícios não são item da V1 sem domínio funcional aprovado.

## 14. Dados do onboarding

> **Nenhum dado deve ser coletado sem finalidade, fonte canônica e consumidor
> definido.**

| Campo | Regra | Fonte canônica | Consumidores V1 | Uso | Edição | LGPD | Fallback e observações |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Nome | Obrigatório | Profile | Hoje, Perfil, Reports, BarIA minimizada | Saudação e identificação | Perfil | Identificação pessoal | Não inferir de documento clínico |
| E-mail | Obrigatório para conta | Auth; cópia compatível no Profile | Auth, Perfil, Reports quando necessário | Login e identificação | Fluxo de conta | Identificação/contato | Resolver pela sessão; não aceitar fallback anônimo |
| Data de nascimento | Conforme contrato do Perfil | Profile | Perfil e cálculos que dependem de idade | Contexto e validações | Perfil | Dado pessoal/saúde contextual | Não derivar por aproximação |
| Altura | Conforme contrato do Perfil | Profile | IMC, Evolução, Health Score | Cálculos explícitos | Perfil | Dado de saúde | Sem valor, componente fica indisponível |
| Peso inicial | Conforme contrato do Perfil | Profile | Evolução, Reports, Score, BarIA | Referência longitudinal | Perfil | Dado de saúde | Não substituir silenciosamente por peso atual |
| Peso atual | Opcional | WeightRecord | Hoje contextual, Evolução, Reports, Score | Registro inicial atual | Evolução > Peso | Dado de saúde | Ausência não é zero; ID estável evita duplicata |
| Meta de peso | Opcional | Profile | Evolução, Reports | Progresso quando aplicável | Perfil | Dado de saúde | Sem meta, ocultar progresso para meta |
| Data da cirurgia | Conforme contrato do Perfil | Profile | Evolução, Reports, BarIA minimizada | Linha temporal | Perfil | Dado de saúde | Não inventar data |
| Tipo de cirurgia | Conforme contrato do Perfil | Profile | Perfil, Reports, BarIA; conteúdo quando explicitamente filtrado | Contexto bariátrico | Perfil | Dado de saúde | `other` não deve esconder incerteza real |
| Meta de água | Condicional ao acompanhamento | Settings | Water, Hoje, Reports, Score | Meta e progresso | Configurações | Dado de saúde/preferência | Não criar percentual sem meta válida |
| Acompanhar Tratamento | Opcional, explícito | Preferências de acompanhamento | Hoje, Tratamento, Notifications | Visibilidade e configuração | Configurações | Preferência de saúde | Não cria item automaticamente |
| Acompanhar Água | Opcional, explícito | Preferências de acompanhamento | Hoje, Water, Notifications | Visibilidade e meta | Configurações | Preferência de saúde | Desativar não apaga registros |
| Acompanhar Alimentação | Opcional, explícito | Settings/preferências | Hoje, Meals, Notifications | Visibilidade e registro | Configurações | Dado/preferência de saúde | Desativar não apaga registros |
| Acompanhar Peso | Opcional, explícito | Preferências de acompanhamento | Hoje contextual, Evolução, Notifications | Visibilidade | Configurações | Preferência de saúde | Peso nunca vira cobrança diária por default |
| Preferência inicial de notificações | Opcional e explícita | Notification preferences | Scheduler e categorias | Define intenção global | Mais > Notificações | Preferência | Não equivale à permissão do SO |
| Timezone | Técnico, confirmado pelo dispositivo/contrato | Regra temporal do domínio e estado local do device | Tratamento e Notifications | Resolver horários | Item/Configurações quando aplicável | Metadado potencialmente sensível | Usar IANA; não reinterpretar passado |
| Locale | Técnico | Configuração do app/device | Formatação e acessibilidade | Idioma/formato | Configurações do app/device | Metadado | Não usar como inferência clínica |
| Consentimentos | Obrigatórios quando vigentes | PrivacyConsent | Router, LGPD e usos autorizados | Base legal e transparência | Mais > Privacidade | Dado legal | Versionados; renovação pode exigir revisão |
| Objectives | Fora da V1 obrigatória | Dados legados do draft, sem nova autoridade | Nenhum consumidor funcional identificado | Não coletar novamente sem caso de uso | Não aplicável | Minimização | Preservar dados existentes; não criar consumidor artificial |

## 15. Notificações e lembretes

Notificações fazem parte do valor diário, mas são opcionais. O HelpBari deve
funcionar integralmente com todas desativadas.

O produto diferencia seis camadas:

1. permissão do sistema operacional;
2. preferência global do HelpBari;
3. preferência por categoria;
4. preferência por item;
5. preferência por horário;
6. notificações concretas instaladas localmente.

Categorias V1:

- Tratamento;
- Consultas;
- Água;
- Refeições;
- Peso.

### 15.1 Regras de preferência

- não inventar horários;
- Água, Refeições e Peso começam desligados até escolha do usuário;
- preferências legadas são preservadas conservadoramente;
- desativar globalmente não apaga preferências filhas;
- categoria desativada impede agendamento;
- item desativado prevalece sobre categoria;
- horário desativado prevalece sobre item;
- configurações detalhadas ficam em Mais > Notificações;
- o onboarding coleta apenas “Quero receber lembretes”.

Preferências de negócio podem sincronizar. Permissão do SO, IDs do plugin,
manifest, estado concreto agendado e preferência futura de conteúdo detalhado
da tela bloqueada permanecem locais ao dispositivo.

### 15.2 Permissão do sistema

Fluxo congelado:

1. o usuário escolhe receber lembretes;
2. o HelpBari explica o benefício;
3. o usuário confirma;
4. o app solicita permissão ao sistema;
5. o resultado é registrado localmente;
6. em caso de negação, o app explica como alterar nas configurações.

A permissão não é solicitada automaticamente no primeiro frame após login.

A interface distingue:

- lembretes ativados no HelpBari;
- permissão concedida;
- permissão negada;
- permissão permanentemente bloqueada;
- capacidade efetiva de agendamento.

Não mostrar “lembretes ativos” quando o SO estiver bloqueando notificações.

### 15.3 Reconciliação

Reconciliar após login, sync relevante, resume, reboot, mudança de timezone,
alteração de regra/preferência, logout, troca de usuário e exclusão LGPD.

O reconciliador:

- deriva projeções desejadas a partir das autoridades;
- deduplica por chave determinística;
- atualiza alterações;
- cancela projeções obsoletas;
- respeita usuário ativo;
- não sincroniza IDs do plugin;
- não transforma notificação em fonte clínica;
- persiste ações antes de convertê-las em eventos de adesão.

### 15.4 Privacidade

Por padrão, textos são genéricos:

- “Você possui um item do tratamento programado.”
- “Você possui um compromisso próximo.”
- “Há uma atividade do HelpBari aguardando sua atenção.”

Não mostrar automaticamente na tela bloqueada:

- nome de medicamento;
- dose;
- resultado de exame;
- nome de documento;
- conteúdo de prescrição;
- observações clínicas.

Uma preferência futura de detalhes deve ser explícita, local, opcional,
conservadora e separada das preferências de negócio.

## 16. BarIA

O papel da BarIA está congelado:

- assistente contextual;
- botão discreto nas telas-raiz;
- acesso “Entender melhor” em insights;
- acesso secundário em Mais;
- não ocupa aba;
- não possui card promocional permanente na Home;
- usa contexto minimizado e necessário;
- respeita consentimentos e sessão ativa;
- não diagnostica;
- não prescreve;
- não ajusta dose;
- não orienta interrupção ou compensação;
- não substitui profissionais de saúde.

## 17. Autoridades internas

| Domínio | Fonte canônica | Consumidores | Nunca é autoridade | Compatibilidade legada |
| --- | --- | --- | --- | --- |
| Auth | Sessão do AuthRepository/Supabase Auth | Router, providers com isolamento | UI, cache de outra sessão | DevAuth somente em ambiente permitido |
| Profile | Repository local-first; Drift local e Supabase remoto | Hoje, Evolução, Reports, BarIA | Draft de onboarding após consumo | Perfil legado preservado por cutover |
| Settings | Repository local-first | Home, Water, Meals, Notifications | Widget ou plugin | Campos legados preservados durante transição |
| PrivacyConsent | PrivacyRepository e consentimentos versionados | Router, LGPD, BarIA autorizada | Checkbox temporário do draft | Aceites antigos tratados por versão |
| OnboardingState | Contrato versionado local-first futuro | State machine e Router | Booleano isolado ou índice de enum | Inferência conservadora por Perfil + Consentimento |
| WeightRecord | WeightRepository/Drift | Hoje contextual, Evolução, Reports, Score | Perfil como histórico de pesagens | Peso inicial do Perfil continua referência |
| WaterRecord | WaterRepository/Drift | Hoje, Evolução, Reports, Score | Progresso visual | Registros anteriores preservados |
| Meal | MealRepository/Drift | Hoje, Evolução, Reports, Score | Tracking toggle | Histórico não é apagado ao desativar |
| Smart Routines | Routine, Plan, Schedule, Pause, Occurrence e Event | Tratamento, Home, Notifications, Reports, Score, BarIA | Medication/Vitamin UI ou notificações | Mappings e legado permanecem |
| Unified Treatment aggregate | Serviços canônicos de consulta/adesão e coverage | Home, Evolução, Reports, Score, BarIA | Consumidores recalculando logs crus | Origem legacy/new/mixed preservada internamente |
| Appointments | AppointmentRepository/Drift | Hoje, Mais, Notifications, Reports | Notificação instalada | Rotas e registros antigos preservados |
| Exams | Medical Exam repository/Drift e storage vinculado | Mais, Reports, BarIA minimizada | Documento isolado | Exam legado permanece em compatibilidade |
| Documents | Document Intelligence repository e storage | Mais, Exams, infraestrutura interna de Prescriptions | OCR não revisado | Órfãos e vínculos existentes preservados |
| Reports | Dados canônicos por intervalo + artefato gerado | Evolução, Mais, compartilhamento | PDF como fonte clínica primária | Artefatos anteriores preservados |
| Health Score | Fórmula versionada sobre componentes com coverage | Evolução e explicações | Home, logs crus ou dado ausente | Fórmulas comparadas somente com versão clara |
| Notification preferences | Contrato local-first sincronizável futuro | Reconciliadores | Permissão do SO ou manifest | Booleans legados espelhados conservadoramente |
| Local notification manifest | Drift/local por dispositivo | Reconciliador e action inbox | Agenda ou fato clínico | Projeções antigas canceladas com segurança |
| BarIA context | Adapter minimizado do snapshot canônico | BarIA | Conversa, report completo ou dashboard paralelo | Contextos antigos não atravessam sessão |
| Prescriptions | Prescription Platform e provenance | Infraestrutura, vínculos e fallback legado | Tratamento ativo por si só | Rotas, dados, sync e LGPD preservados |

Regras transversais:

- Home é consumidora read-only;
- apresentação não acessa Drift ou Supabase diretamente;
- notificações concretas não são fonte clínica;
- Smart Routines permanece autoridade de Tratamento;
- Prescrições não são sinônimo de tratamento ativo;
- sincronização não cria uma segunda autoridade;
- Supabase sincroniza entidades e regras; Drift permanece fonte local de
  verdade da experiência offline-first.

## 18. Compatibilidade e transição

- nenhuma rota legada é apagada na primeira etapa;
- Medication e Vitamin redirecionam futuramente para Tratamento, preservando
  item/categoria quando identificáveis por ID;
- Prescription mantém fallback autenticado sem promoção no produto;
- Health Score aponta para Evolução;
- Reports mantém uma única capacidade;
- Profile, Settings, Documents e Exams são encontrados por Mais;
- BarIA preserva origem e revalida sessão;
- payload de usuário diferente da sessão ativa é rejeitado;
- dados legacy/new/mixed não são contados duas vezes;
- backfills futuros são aditivos e idempotentes;
- migrations antigas permanecem imutáveis;
- simplificação visual nunca apaga histórico.

## 19. Estado atual conhecido e transição necessária

O código existente ainda não representa integralmente este Product Freeze:

- a Home atual contém mais blocos e um menu amplo;
- Health Score e BarIA têm presença permanente na Home;
- Medicamentos, Vitaminas e Prescrições ainda possuem destinos visíveis;
- o Router atual é plano e não possui o shell das quatro áreas;
- o onboarding usa marcador local e índice de enum em parte do contrato;
- `objectives` é coletado sem consumidor funcional identificado;
- Settings ainda separa preferências de Medication/Vitamin e não possui todas
  as categorias V1;
- a permissão de notification é solicitada automaticamente após autenticação;
- Água, Refeições e Peso ainda não possuem o contrato completo de lembretes.

Essas diferenças são backlog dos lotes oficiais. Não alteram as decisões
congeladas e não autorizam um big bang.

## 20. Escopo excluído da V1

- remoção física de Prescrições;
- remoção de tabelas legadas;
- edição de migrations antigas;
- migration destrutiva;
- portal de clínicas;
- envio de prescrições por profissionais;
- diagnóstico pela BarIA;
- recomendação ou ajuste de dose;
- personalização avançada por IA;
- exercícios sem domínio funcional aprovado;
- hábitos inteligentes automáticos;
- notificações preditivas;
- reescrita completa do Router;
- reescrita completa de Smart Routines;
- big bang de arquitetura;
- Macro 4.

### Possibilidades futuras, não requisitos

- hábitos e lembretes inteligentes;
- integração com clínicas;
- importação inteligente de documentos;
- personalização avançada;
- novos acompanhamentos;
- detalhes opcionais e locais em notificações.

## 21. Roadmap oficial da V1

| Lote | Objetivo | Resultado esperado | Dependências | Fora do escopo | Gate |
| --- | --- | --- | --- | --- | --- |
| 0 — Product Freeze e contratos | Consolidar decisões e fronteiras | Fonte única aprovada e contratos conceituais | Macros 1–3 e revisões aprovadas | Código funcional | Product + Architecture |
| 1 — Contrato versionado do onboarding | Definir autoridade e compatibilidade | Estados e etapas estáveis, local-first | Lote 0 | Nova UX completa | Architecture + Data Compatibility + LGPD |
| 2 — State machine de Auth/Onboarding | Resolver entrada antes do produto | Fluxo sem loops, bypass ou bloqueio indevido offline | Lote 1 | Navegação visual V1 | Architecture + Data Compatibility |
| 3 — Uso real e minimização dos dados | Vincular cada coleta a finalidade | Campos obrigatórios/opcionais coerentes; `objectives` fora da coleta V1 | Lotes 1–2 | Personalização artificial | Product + LGPD |
| 4A — Persistência das preferências de notificações | Separar global, categoria, item e horário | Preferências local-first e compatíveis | Lotes 0–3 | Projeções concretas remotas | Data Compatibility + LGPD |
| 4B — Reconciliação e agendamento | Garantir projeções locais confiáveis | Sem duplicatas/órfãos; permissão contextual; categorias V1 | Lote 4A | Notificação preditiva | Notification Reliability |
| 5 — Navegação das quatro áreas | Criar a estrutura Hoje/Tratamento/Evolução/Mais | Navegação e back behavior previsíveis | Lotes 1–4 | Apagar rotas legadas | Product + Architecture |
| 6 — Home simplificada | Aplicar a composição congelada | Uma Home operacional, resiliente e compacta | Lote 5; Macro 3 | Nova autoridade de dados | Product + Architecture |
| 7 — Leitura unificada de Tratamento | Expor Hoje e Itens | Uma fachada visível sem dupla contagem | Lotes 4–6; UTE | Remover legado | Architecture + Data Compatibility |
| 8 — Adicionar e editar Tratamento | Unificar escrita futura | Categorias, múltiplos horários, PRN e revisões preservadas | Lote 7 | Simplificar o domínio | Product + Data Compatibility |
| 9 — Evolução | Compor históricos e resumos existentes | Entrada simples com detalhes sob demanda | Lotes 5–8 | Dashboard administrativo | Product + Architecture |
| 10 — Mais e BarIA | Tornar recursos secundários encontráveis | Grupos aprovados, Privacidade acessível e BarIA contextual | Lote 5 | Quinta aba | Product + LGPD |
| 11 — Compatibilidade e ocultação de Prescriptions | Preservar entradas antigas sem promoção V1 | Redirects/fallbacks seguros e ocultação visual | Lotes 5–10 | Remoção física | Data Compatibility + LGPD |
| 12 — Estabilização e gates finais | Validar V1 ponta a ponta | Release candidate com evidências | Todos os lotes | Macro 4 | Todos os gates |

Cada lote deve ter rollback lógico e validação própria. Nenhum lote pode apagar
dados, editar migration antiga ou trocar várias autoridades simultaneamente.

## 22. Gates de aprovação

### 22.1 Product Gate

- existem exatamente quatro áreas principais;
- Home segue a composição congelada;
- Agora possui no máximo uma ação;
- agenda Hoje/7 dias não é duplicada;
- Home possui no máximo quatro ações principais;
- Tratamento é a única experiência visível para itens;
- Prescrições estão ocultas como feature principal;
- BarIA é contextual e não ocupa aba;
- recursos secundários continuam encontráveis;
- estados vazios e insuficientes não culpabilizam o paciente.

### 22.2 Architecture Gate

- autoridades de domínio foram preservadas;
- nenhuma lógica paralela duplica domínio;
- apresentação não acessa Drift, Supabase, SQL, storage ou plugin diretamente;
- Smart Routines continua autoridade de Tratamento;
- Home continua read-only e reconstruível;
- Sync Engine existente é reutilizado;
- notificações concretas continuam projeções locais;
- consultas são limitadas e isoladas por usuário.

### 22.3 Data Compatibility Gate

- usuários antigos permanecem utilizáveis;
- histórico não é reescrito;
- legacy/new/mixed não são duplicados;
- IDs e vínculos não são resolvidos apenas por nome;
- migrations antigas permanecem imutáveis;
- backfills são aditivos, idempotentes e auditáveis;
- rotas e deep links antigos possuem destino seguro;
- rollback lógico não apaga dados novos.

### 22.4 Notification Reliability Gate

- não existem duplicatas ou projeções órfãs;
- permissão do SO é diferente de preferência;
- preferência global, categoria, item e horário respeitam precedência;
- pausa, conclusão, edição e exclusão reconciliam projeções;
- logout, troca de usuário e LGPD limpam projeções locais;
- timezone, reboot, resume e sync reconciliam;
- payload permanece técnico e minimizado;
- ações em background são idempotentes e isoladas por usuário.

### 22.5 LGPD Gate

- cada coleta possui finalidade e consumidor;
- consentimentos são versionados;
- novos contratos entram na exportação e exclusão;
- limpeza local e storage são cobertos;
- dados e logs são minimizados;
- Privacidade, exportação e exclusão são encontráveis;
- nenhum dado de outro usuário permanece acessível;
- desativar acompanhamento não apaga histórico sem pedido explícito.

## 23. Critérios de aceite do Product Freeze

Este documento é aceito quando:

- pode ser entendido sem consultar relatórios anteriores;
- é compreensível por Produto, UX e Engenharia;
- não contradiz as autoridades aprovadas nas Macros 1, 2 e 3;
- diferencia produto visível de infraestrutura interna;
- registra claramente decisões congeladas;
- registra claramente o que está fora do escopo;
- define o uso e a finalidade dos dados de onboarding;
- separa preferência e permissão de notificações;
- preserva Prescription Platform e compatibilidade legada;
- contém roadmap oficial e gates verificáveis;
- não prescreve remoções destrutivas;
- evita transformar possibilidades futuras em requisitos V1.

## 24. Uso obrigatório em trabalhos futuros

Antes de propor ou implementar trabalho da V1, Produto, Engenharia e agentes de
IA devem:

1. consultar este documento;
2. identificar a área e o lote afetados;
3. preservar as autoridades internas;
4. explicitar impacto em compatibilidade, notifications e LGPD;
5. executar os gates aplicáveis;
6. tratar qualquer divergência como decisão de produto a ser aprovada, não
   como autorização implícita para mudar o freeze.

Mudanças neste Product Freeze exigem decisão humana explícita, registro do
motivo e análise de impacto. Implementação existente divergente deve ser
adaptada incrementalmente; não redefine por si só o produto aprovado.
