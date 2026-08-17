# preferences-api (POC)

POC irmã da [`preferences-api-mongo`](https://github.com/sabrinagomesrd/preferences-api-mongo) — **mesmo contrato HTTP e domínio**, store = **Postgres via ActiveRecord**.

> **Não é** serviço de produção. **Não fecha** ADR de persistência.

O primeiro motor local foi SQLite (default do `rails new`). Esta pasta agora sobe **Postgres no Docker**, alinhada ao Esboço A (relacional + JSON). Cloud SQL seria o Postgres *gerenciado no GCP* do `rails-templates` — **não** é o que este compose executa.

## Como o ActiveRecord e o Postgres se encaixam

Não basta um arquivo: o store é um conjunto.

| Camada | O que esta PoC usa |
|--------|-------------------|
| `Gemfile` | `gem "pg"` (sem `sqlite3`) |
| `config/database.yml` | adapter `postgresql`, só `development` / `test` |
| `docker-compose.yml` | `postgres:16` na porta host **5433** |
| Model | `Preference < ApplicationRecord` |
| Schema | `db/migrate` + `bin/rails db:prepare` |

Contraste com a irmã Mongo: lá Mongoid, `mongoid.yml` e `db:create_indexes`; **aqui** ActiveRecord, migration e `db:prepare`.

`solid_cache` / `solid_queue` continuam no Gemfile porque o template Rails 8 pluga nisso. Em development o cache já é `memory_store` — não é o objeto desta PoC.

## Decisões deste incremento

| Decisão | Escolha | Por quê |
|---------|---------|---------|
| ORM | **ActiveRecord** (nativo do template) | Esboço A: identidade em colunas + `payload` JSON |
| Motor local | **Postgres 16 no Docker** (porta 5433) | Alinha o estudo ao relacional; 5433 evita colidir com outros Postgres da máquina |
| Cloud SQL | **Fora desta pasta** | Produto GCP do template; este repo não provisiona instância gerenciada |
| `payload` | coluna **jsonb** | Tipo JSON do Postgres; `t.json` no SQLite antigo não era JSONB |
| Context vazio | Sentinel `""` (não `NULL`) | `context` é opcional no contrato mas entra na identidade; em SQL `NULL != NULL` furaria o unique |
| Unique singleton | índice unique parcial `WHERE cardinality = 'singleton'` | No máximo 1 singleton por identidade |
| `scope: system` | rejeitado no model | Padrão calculado mora na Apresentação, não neste store |

## Subir local

Pré-requisitos: Docker, Ruby alinhado a `.ruby-version`, Bundler, cliente `libpq` (a gem `pg` precisa dele para compilar).

```bash
cd ~/Developer/rd-station/preferences-api
docker compose up -d
bundle config set --local path 'vendor/bundle'
bundle install
bin/rails db:prepare db:seed
bin/rails server -p 3001
```

Em outro terminal (smoke de leitura):

```bash
bin/demo
# ou: BASE_URL=http://localhost:3001 bin/demo
```

- Host/porta default: `127.0.0.1:5433`
- Databases: `preferences_api_development` e `preferences_api_test`

O seed grava a jornada da Rosana (conta `42`: singleton team/user no cartão de deal + filtro multi na listagem de contact). Rodar de novo **apaga** as preferences dessa conta e recria.

### Exemplos curl

```bash
# Upsert delta de equipe
curl -X PUT http://localhost:3001/v1/preferences/singleton \
  -H 'Platform-Account-Id: 42' -H 'Content-Type: application/json' \
  -d '{
    "resource": { "origin": "platform_object", "key": "deal" },
    "surface": "cartao",
    "type": "cartao_fields",
    "scope": "team",
    "scope_ref": "time_negociadores",
    "payload": { "fields": { "removed": ["etapa"], "added": ["dono"] } },
    "created_by": "demo"
  }'

# Resolução (base system enviada pelo cliente na POC)
curl 'http://localhost:3001/v1/preferences/resolved?resource_origin=platform_object&resource_key=deal&surface=cartao&type=cartao_fields&team_ref=time_negociadores&user_ref=rosana&base_fields[]=titulo&base_fields[]=valor&base_fields[]=etapa' \
  -H 'Platform-Account-Id: 42'
```

## Ver o dado

Não há arquivo SQLite nesta PoC. Duas formas:

**Rails console**

```bash
bin/rails console
```

```ruby
Preference.count
Preference.last.as_api_json
```

**psql no compose**

```bash
docker compose exec postgres psql -U postgres -d preferences_api_development
```

```sql
SELECT uuid, scope, scope_ref, cardinality, payload FROM preferences;
```

Tabela: **`preferences`**. Cada linha é um desvio (singleton ou multi). `payload` é jsonb — o delta, não a tela resolvida.

## Endpoints

Mesmos da PoC Mongo (`preferences-api-mongo`). Header obrigatório: `Platform-Account-Id`.

GETs exigem query de identidade (`resource_origin`, `resource_key`, `surface`, `type`); não há dump “tudo da conta”.

| Método | Caminho | Uso |
|--------|---------|-----|
| `GET` | `/health_check` | health + `store: postgres` |
| `GET` | `/v1/preferences/raw` | camadas singleton gravadas |
| `GET` | `/v1/preferences/resolved` | resolve com `base` na query |
| `PUT` / `DELETE` | `/v1/preferences/singleton` | upsert / apaga singleton |
| `GET` / `POST` | `/v1/preferences` | lista / cria multi |
| `DELETE` | `/v1/preferences/:id` | apaga multi por `uuid` |

`GET /raw` = singletons crus daquela superfície. `GET /resolved` = cascata com **base simulando system** (query `base_fields` ou fallback `titulo, valor, etapa` — **não** grava `scope: system`).

### Por que singleton usa `PUT` (e não `POST`) nesta PoC

Singleton = **no máximo um** desvio por identidade (conta + resource + surface + type + context + scope + scope_ref). Escrever de novo **substitui** o mesmo artefato — não cria o segundo.

`PUT /v1/preferences/singleton` é **upsert** por essa identidade: primeira vez cria (201), mesma identidade de novo atualiza o `payload` (200). O verbo idempotente casa com “declarar o estado desejado do desvio”, não com “criar mais um registro”.

`POST /v1/preferences` fica para **multi** (filtros salvos, etc.), em que cada chamada **cria** uma instância nova (`uuid` novo, com `name`).

Espelho da PoC Mongo / padrão `PUT`/`DELETE` de singleton do anexo de Apresentação. **Não** é ADR: o contrato oficial ainda pode escolher outro desenho HTTP; o que o domínio exige é a regra de um-por-identidade + upsert.

## O que este incremento **não** responde

- Cloud SQL vs Atlas em produção
- Custo mensal Cloud SQL / Mongo managed na org
- Ownership de `/resolved`
- Forma canônica do `payload` por superfície
