# HelpBari V1 — Plano de smoke test

Executar no artefato candidato e em Android real, registrando versão, aparelho,
ambiente, usuário de teste, data e resultado. Não usar dados pessoais reais.

## Pré-condições

- APK/AAB candidato assinado por processo seguro;
- migrations locais/remotas em paridade e RLS habilitado;
- dois usuários de teste, rede e modo avião disponíveis;
- notificações inicialmente sem permissão e links `io.helpbari.app` disponíveis.

## Instalação, login e onboarding

1. Instale limpo; confirme nome HelpBari, ícone e abertura sem crash.
2. Cadastre o usuário A, valide e-mail quando habilitado e faça login.
3. Tente credencial inválida; Hoje/onboarding não devem ser liberados.
4. Conclua consentimentos, perfil, jornada, peso, acompanhamentos, metas e lembretes.
5. Feche/reabra em cada etapa e confirme retomada correta.
6. Conclua offline, abra Hoje e reconecte; confirme sync sem duplicação.
7. Saia/entre; onboarding concluído não deve reaparecer.

## Home

1. Confirme Hoje, Tratamento, Evolução e Mais.
2. Valide cabeçalho, uma ação em Agora, agenda Hoje/7 dias, resumo diário, um
   insight e no máximo quatro ações principais.
3. Abra Água pela ação rápida; nenhum volume deve ser registrado.
4. Simule uma fonte indisponível; os demais blocos permanecem utilizáveis.
5. Confirme que PRN sem uso não aparece como pendência.

## Tratamento

1. Cadastre as categorias; valide múltiplos horários, dias, uso único, período
   definido, contínuo explícito e duração não informada.
2. Edite horário/categoria; confirme revisão nova e passado preservado.
3. Pause, retome e conclua; confira agenda e lembretes.
4. Cadastre PRN sem horário, registre uso com horário/observação e confira histórico.
5. Produza eventos incompatíveis em dois aparelhos; confira origem, versões,
   impacto, opções e cancelar. Escolha uma e confirme correção auditável.
6. Abra detalhe por lista/deep link; valide informações, categoria, horários,
   dias, lembretes, duração, status, eventos, revisões, pausas e retomadas.

## Água, alimentação e peso

1. Registre água e confira meta/progresso em Hoje e Evolução.
2. Registre refeição com/sem proteína; não deve surgir percentual inventado.
3. Registre peso e confira tendência; ausência de meta não vira zero.
4. Repita offline, reconecte e confirme envio sem perda/duplicação.

## Consultas, exames, relatórios e BarIA

1. Cadastre/edite/cancele consulta e valide Hoje, Mais e lembrete.
2. Cadastre exame, resultados e anexo; exame realizado não vira compromisso.
3. Gere relatório por Evolução e Mais; confirme a mesma capacidade/dados.
4. Abra BarIA pela raiz e insight; confirme contexto minimizado e nenhuma
   prescrição, diagnóstico, ajuste de dose ou dado de outra sessão.

## Offline, logout e troca de usuário

1. Em modo avião, leia e escreva dados suportados; confira feedback local.
2. Encerre/reabra offline; dados persistem e fila não parece falha clínica.
3. Reconecte e confirme convergência. Faça logout; notificações são canceladas.
4. Entre como usuário B; confirme onboarding e dados próprios vazios.
5. Volte ao usuário A; confirme dados A e ausência total de dados B.

## Atualização de versão

1. Instale versão anterior, crie dados e atualize sem desinstalar.
2. Confirme upgrade Drift, sessão/onboarding, rotas legadas e histórico.
3. Aprove o `applicationId` antes da primeira publicação; IDs diferentes não
   representam atualização do mesmo aplicativo.

## Exportação e exclusão de conta

1. Abra Mais > Privacidade em até dois níveis e revise consentimentos.
2. Exporte; valide usuário atual e família Smart Routines completa.
3. Solicite exclusão de dados/conta com reautenticação.
4. Confirme remoção remota/local/storage, logout, notificações canceladas e
   nenhum cache/arquivo acessível.

## Notificações

1. Negue permissão; app funciona e informa capacidade efetiva.
2. Conceda contextualmente; valide global, categoria, item e horário.
3. Desative/reative níveis; confirme precedência, sem duplicatas/órfãos.
4. Valide Tratamento, Consultas, Água, Refeições e Peso configurados.
5. Reinicie, altere timezone, use background e atualize; confirme reconciliação,
   texto genérico e usuário correto.

## Deep links

1. Sem sessão, abra callback/link; login/onboarding precedem o destino.
2. Com usuário A, abra item A; confirme destino correto.
3. Tente payload B e ID inexistente; confirme fallback sem vazamento.
4. Valide links legados Medication/Vitamin/Prescriptions sem promoção.

## Critério de saída

Zero crash, bloqueio, vazamento, perda local, resolução destrutiva automática,
notificação órfã/duplicada ou divergência do Product Freeze.
