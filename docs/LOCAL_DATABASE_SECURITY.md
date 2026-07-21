# Local Database Security

Status: risco aceito somente para teste interno controlado.

O banco `helpbari.sqlite` usa SQLite/Drift sem criptografia em repouso. O Android mantém sandbox da aplicação, backup está desabilitado, cleartext está bloqueado, logs de produção não incluem exceções/dados clínicos e a exclusão LGPD limpa linhas e arquivos conhecidos. Essas medidas reduzem exposição, mas não substituem criptografia em aparelho comprometido.

Não foi adotado SQLCipher nesta rodada. Uma troca de driver sem migração comprovada poderia tornar bancos clínicos existentes ilegíveis. A implementação futura exige:

- biblioteca Drift/Android mantida e compatível;
- chave aleatória no Android Keystore, nunca no repositório;
- migração atômica do SQLite existente para banco criptografado;
- verificação de integridade antes da troca e rollback recuperável;
- testes de instalação limpa e upgrade com dados, tombstones e pendências;
- troca A→B→A, logout e exclusão;
- medição de startup, consultas e tamanho;
- estratégia para perda/invalidação da chave.

Até esses gates existirem, não distribuir o APK fora de grupo controlado nem alegar proteção completa em repouso.
