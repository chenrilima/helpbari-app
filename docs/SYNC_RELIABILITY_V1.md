# Sync Reliability V1

## Autoridade e sessão

Drift permanece a fonte local de verdade e `SyncEngine` continua sendo a única autoridade de sincronização. Cada execução iniciada por `SyncManager` captura `userId` e uma geração de `SyncSessionRegistry`. Logout, expiração e troca de conta revogam a geração. O engine valida o token antes e depois de leitura de estado, páginas, aplicação local, confirmação, retry, cursor e persistência de resultado.

Uma requisição HTTP já enviada não pode ser desfeita pelo cliente. Depois da revogação, porém, sua resposta não é aplicada nem confirmada, o backoff é interrompido e a nova sessão recebe um passe serializado próprio. RLS continua sendo a barreira remota obrigatória.

## Gatilhos

- bootstrap autenticado;
- login;
- retorno ao foreground;
- recuperação de transporte de rede, com debounce;
- commit local nos fluxos já existentes;
- ação manual.

`connectivity_plus` é somente um gatilho. O resultado não prova acesso à internet; timeout, retry e backoff permanecem no engine. Eventos repetidos são deduplicados, e recuperação em background não inicia sync.

## Pull paginado

O contrato `PagedPullSyncRepository` processa streams de páginas. O helper Supabase usa keyset `(updated_at, id)`, filtra `user_id`, inclui tombstones, limita a página e o engine deduplica `(id, updatedAt, tipo)`. O cursor do repositório só avança depois de todas as páginas e do push sem erro.

Em 21/07/2026, Water, Weight, Meals, Appointments, Exams e Bioimpedance usam esse contrato. Agregados de documentos, exames médicos, prescrições, plataforma de prescrições, Smart Routines e logs ainda exigem paginação que preserve a atomicidade pai/filhos; o gate de APK permanece fechado até isso ser concluído.

## Conflitos

O comportamento legado ainda compara `updatedAt` do dispositivo. Triggers remotos rejeitam regressão temporal, mas isso não elimina clock skew nem oferece comparação de versão base. A solução canônica requer migration aditiva com revisão monotônica confirmada pelo servidor e push condicional atômico. Não foi improvisada uma RPC genérica nem uma migração parcial porque isso poderia sobrescrever dado clínico.

## Background

Não existe worker Android confiável no projeto. Bootstrap, foreground, conectividade e ação manual são o mecanismo atual. Um worker futuro deve reutilizar o mesmo engine, abrir somente a sessão autenticada vigente, aceitar execução inexata do Android e ser validado em dispositivo. Background periódico é melhoria operacional pós-APK, não nova autoridade.

## Tombstones

Tombstones não devem ser removidos remotamente sem acknowledgements por dispositivo. Até existir watermark por dispositivo e uma janela máxima de clientes suportados, a política segura é retenção remota, paginação e índices `(user_id, updated_at, id)`. Exclusão LGPD é imediata e separada. Compactação local só poderá remover tombstones confirmados depois de um protocolo de ressincronização completa documentado.
