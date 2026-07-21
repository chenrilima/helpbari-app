# Plataforma de Notificações V1

Status: contrato implementado do Bloco B do Product Freeze V1.

## Separação de responsabilidades

A plataforma mantém seis estados distintos:

1. permissão do sistema operacional, local ao aparelho;
2. preferência global de negócio;
3. preferência por categoria;
4. preferência por item;
5. preferência por horário;
6. notificação concreta instalada e seu manifest local.

`NotificationPreferences`, persistido como parte de Settings, é a autoridade
sincronizável das camadas 2–5. Permissão, timezone observado, IDs do plugin,
manifest e action inbox não são enviados ao Supabase. Desativar a preferência
global impede projeções sem apagar as escolhas filhas.

Categorias V1: Tratamento, Consultas, Água, Alimentação e Peso. Água e
Alimentação exigem um horário diário explícito. Peso exige dia da semana e
horário explícitos. Consultas usam antecedência escolhida pelo usuário. Nenhum
horário ou frequência é inferido.

Os booleans legados de vitaminas, medicamentos e consultas continuam sendo
lidos como fallback e são espelhados a partir da nova autoridade. O backfill
preserva Tratamento e Consultas conservadoramente; Água, Alimentação e Peso
permanecem desligados até opt-in.

## Tratamento

Smart Routines continua sendo a única autoridade funcional. A plataforma
consome `RoutineNotificationProjection` derivada de occurrences elegíveis na
janela móvel. Planos, múltiplos horários, schedules, timezone IANA, pausas,
conclusão, cancelamento, tombstones, PRN, revisões e conflitos continuam sendo
resolvidos pelo domínio canônico. PRN sem occurrence não gera lembrete.

Preferência por item usa `routineId`; preferência por horário usa `scheduleId`.
Notificações nunca materializam nova recorrência de Medication/Vitamin e nunca
se tornam fonte de adesão. Ações em background são persistidas no inbox antes
da conversão em eventos canônicos.

## Projeção e reconciliação

O bootstrap reconcilia após login, sync concluído, foreground/resume e troca
de usuário. Alterações em Settings e Appointments disparam nova reconciliação.
O plugin restaura alarmes no reboot e o bootstrap recompõe o manifest na
próxima inicialização.

O reconciliador:

- limita e ordena a janela futura;
- deduplica por chave determinística;
- atualiza horários alterados;
- cancela itens obsoletos, concluídos, pausados ou desabilitados;
- rejeita projeções de outro usuário;
- registra falhas para retry sem declarar agendamento ativo;
- limpa manifest e notificações concretas no logout, troca de usuário e LGPD.

Mudança de timezone é observada no resume. Tratamento preserva o timezone IANA
do schedule; lembretes configuráveis preservam o timezone confirmado no
momento da configuração. Apenas projeções futuras são reconstruídas.

## Permissão e privacidade

Agendar nunca solicita permissão. O único fluxo de solicitação é:

```text
explicação → confirmação → prompt do SO → resultado
```

A preferência pode permanecer ligada se o SO negar a permissão, mas a UI não
deve afirmar que notificações concretas estão ativas.

Título e corpo são genéricos. Payload contém somente source, userId e ID
técnico necessário ao deep link/command. Nome, dose, exame, prescrição,
resultado, localização, profissional e observações não entram no payload ou na
tela bloqueada.

Preferências de negócio fazem parte da exportação LGPD. Manifest e action inbox
são operações locais descartáveis: não são exportados e são eliminados no
logout/exclusão.

## Persistência e sync

Drift schema 22 adiciona `notification_preferences_json` a Settings. Supabase
adiciona `settings.notification_preferences` em migration aditiva. O Settings
Repository continua local-first, com LWW por `updatedAt`, tombstones, RLS e o
Sync Engine existente. A tabela remota legada `notification_reminders`
permanece descontinuada.
