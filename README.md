# Startai

- **Disciplina:** `Projeto Integrador Multidisciplinar`
- **Instituição:** `Faculdade Senac de Pernambuco`
- **Período:** `2026.2`

## O que é o projeto

Criação de uma plataforma de matchmaking que conecta startups nascentes do
Porto Digital (Recife/PE) a mentores e investidores anjo, um SaaS completo, com
cadastro de startups por segmento, perfis de investidor e vínculo de membros
por startup.

## Stack

- **Frontend:** React, Vite, TypeScript, Tailwind CSS, Axios.
- **Backend:** Gleam, BEAM VM, árvore de supervisão OTP.
- **Database:** PostgreSQL 18.
- **Orquestração:** Docker Compose.

## O que é o projeto

Plataforma de matchmaking que conecta startups nascentes do Porto Digital (Recife/PE) a
mentores e investidores anjo. O sistema permite cadastro de startups por segmento, perfis
de mentor e investidor, vínculo de membros por startup, busca com filtros e registro de
interesse entre as partes.

O produto é entregue como SaaS.

### O que o MVP faz

- Cadastro e autenticação de usuários (startup, mentor, investidor)
- Perfil público de startup, mentor e investidor
- Busca de startups com filtro por área de atuação e estágio
- Registro de interesse entre perfis, com status (`pendente`, `aceito`, `recusado`)
- Exportação de dados pessoais e registro de consentimento (LGPD)

### O que o MVP não faz

- Não há algoritmo de recomendação. O "match" da v1 é manifestação de interesse com
  acompanhamento de status, não score automático.
- Não há chat interno, notificação por e-mail ou upload de documentos.

---

## Stack

**Frontend**

| Camada | Tecnologia |
| --- | --- |
| Biblioteca de UI | React 18 |
| Build / dev server | Vite |
| Linguagem | TypeScript |
| Estilos | Tailwind CSS |
| Cliente HTTP | Axios |

**Backend**

| Camada | Tecnologia |
| --- | --- |
| Linguagem | Gleam |
| Runtime | BEAM VM (Erlang), com árvore de supervisão OTP |
| Servidor HTTP | Mist |
| Framework web | Wisp |
| Acesso a dados | pog (cliente PostgreSQL) + Squirrel (SQL type-safe) |
| Hash de senha | argus (Argon2id) |
| Tokens | JWT via implementação JOSE |
| Banco | PostgreSQL 16 |

Gleam é uma linguagem funcional de tipagem estática que compila para Erlang e roda na
BEAM. A escolha traz tipagem forte de ponta a ponta (front em TypeScript, back em Gleam)
e o modelo de concorrência do BEAM. Em contrapartida, o ecossistema é jovem: não há ORM,
então o acesso a dados é SQL escrito à mão e tipado pelo Squirrel.

**Infraestrutura**

- Docker e Docker Compose para orquestração local
- Volume Docker para persistência do Postgres

---

## Arquitetura

O diagrama completo está em [`docs/arquitetura.mermaid`](docs/arquitetura.mermaid).
Esse arquivo é a **fonte da verdade** os PNGs distribuídos no Trello são exportações
dele e podem estar desatualizados.

Para visualizar sem instalar nada, cole o conteúdo em <https://mermaid.live>.

### Fluxo de uma requisição

```
Cliente (React)
  → HTTPS / JSON
  → Middlewares (CORS, auth, rate limit, validação)
  → Controller
  → Service (regras de negócio)
  → Repository
  → PostgreSQL
```

## Como rodar localmente

### Pré-requisitos

- Docker e Docker Compose
- Git

### Passos

```bash
git clone https://github.com/gislanysa/startai.git
cd startai
cp .env.example .env
docker compose up -d
```

Serviços disponíveis após subir:

| Serviço | URL |
| --- | --- |
| Front-end | http://localhost: |
| API | http://localhost: |
| PostgreSQL | localhost: |

| Variável | Descrição |
| --- | --- |
| `DATABASE_URL` | String de conexão do PostgreSQL |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | Credenciais do container do banco |
| `PORT` | Porta da API (padrão `8080`) |
| `JWT_SECRET` | Segredo de assinatura do access token |
| `JWT_REFRESH_SECRET` | Segredo de assinatura do refresh token |
| `WISP_SECRET_KEY_BASE` | Chave usada pelo Wisp para assinar cookies |
| `CORS_ORIGIN` | Origem permitida do front-end |

---

## API

Endpoints previstos para o MVP:

### Autenticação

| Método | Rota | Retorno |
| --- | --- | --- |
| POST | `/auth/signup` | 201 |
| POST | `/auth/login` | 200 |
| POST | `/auth/refresh` | 200 / 401 |
| POST | `/auth/logout` | 204 |

### Usuários

| Método | Rota | Retorno |
| --- | --- | --- |
| GET | `/users/me` | 200 |
| PUT | `/users/me` | 200 |
| DELETE | `/users/me` | 204 |

### Startups

| Método | Rota | Retorno |
| --- | --- | --- |
| GET | `/startups` | 200 |
| GET | `/startups/:id` | 200 / 404 |
| POST | `/startups` | 201 |
| PUT | `/startups/:id` | 200 |
| DELETE | `/startups/:id` | 204 |

### Mentores e investidores

| Método | Rota | Retorno |
| --- | --- | --- |
| GET | `/mentors` | 200 |
| GET | `/investors` | 200 |

### Busca e interesse

| Método | Rota | Retorno |
| --- | --- | --- |
| GET | `/search?area=&estagio=` | 200 |
| POST | `/interests` | 201 |
| GET | `/interests` | 200 |
| PATCH | `/interests/:id` | 200 |

### LGPD

| Método | Rota | Retorno |
| --- | --- | --- |
| POST | `/privacy/consent` | 201 |
| GET | `/users/me/export` | 200 |

### Códigos de status utilizados

`200` OK · `201` Created · `204` No Content · `400` Bad Request · `401` Unauthorized
`403` Forbidden · `404` Not Found · `409` Conflict · `422` Unprocessable
`429` Too Many Requests · `500` Server Error

Autenticação via header `Authorization: Bearer <token>`.

---

## Privacidade e LGPD

A plataforma trata dados pessoais de fundadores, mentores e investidores. As medidas
previstas desde o início do desenvolvimento:

- Registro explícito de consentimento no cadastro, com data e versão dos termos
- Endpoint de exportação dos dados do titular (`GET /users/me/export`)
- Exclusão de conta com remoção ou anonimização dos dados (`DELETE /users/me`)
- Senhas armazenadas apenas como hash, nunca em texto puro
- Coleta mínima: só pedimos o que o produto realmente usa

Conformidade não é tarefa da última sprint — cada funcionalidade que toca dado pessoal
já nasce com esses pontos considerados.

---

## Roadmap

| Entrega | Escopo | Prazo |
| --- | --- | --- |
| Entrega 1 — MVP | Auth, perfis, busca, interesse, LGPD básico | 15/10/2026 |
| Entrega 2 — SaaS | Backlog completo (ver Trello) | 11/12/2026 |

---

## Contribuindo

### Branches

```
main            # código estável
feat/<nome>     # nova funcionalidade
fix/<nome>      # correção
docs/<nome>     # documentação
```

### Pull requests

Toda alteração em `main` passa por PR com pelo menos uma revisão de outro membro do time.

---

## Equipe

| Nome | Responsabilidade |
| --- | --- |
| [Bianca Guimarães](https://github.com/BiancagscCabral) | Desenvolvedora Front-end · Pesquisa e Melhoria Contínua |
| [Eduardo Soares](https://github.com/edudxs) | Documentação Técnica · Gestão de Projeto (Trello, Docs & Apresentações) |
| [Gislany Araujo](https://github.com/gislanysa) | Desenvolvedora Front-end · Owner do Repositório |
| [João Marcos](https://github.com/jmtmds) | Desenvolvedor Front-end · Documentação Técnica |
| [Pedro Ayres](https://github.com/Kacaii) | Desenvolvedor Back-end |
| [Reideclildon Paulo](https://github.com/kiing12) | Desenvolvedor Back-end |


---

## Licença

Distribuído sob a licença MIT. Ver [LICENSE](LICENSE).
