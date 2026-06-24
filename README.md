# CRUDEX 1.0 — Sistemas de Informação Orientados por Metadados

O CRUDEX é uma plataforma para construção de sistemas de informação baseada em metadados.

Em vez de desenvolver manualmente telas, grids, formulários, relacionamentos, validações e operações CRUD para cada sistema, o desenvolvedor descreve a estrutura do sistema e o CRUDEX gera dinamicamente a aplicação.

## Principais recursos

### CRUD Dinâmico

Criação automática de:

* Grids
* Formulários
* Inclusão
* Alteração
* Exclusão
* Consultas

sem necessidade de desenvolvimento específico para cada tabela.

### Relacionamentos

Relacionamentos entre tabelas são definidos por metadados.

O CRUDEX reconhece automaticamente:

* Chaves estrangeiras (FK)
* Relacionamentos pai-filho
* Formulários Master-Detail

### Lookups Inteligentes

Campos de chave estrangeira são apresentados automaticamente como listas de seleção paginadas.

Nos grids e formulários, o usuário visualiza descrições amigáveis em vez de códigos internos.

### Paginação Transparente

O acesso aos dados é realizado através de datasets paginados.

Grids, formulários e listas trabalham sobre datasets sem necessidade de lógica específica de paginação.

### Validação

Validações podem ser executadas tanto no frontend quanto no backend.

As regras são definidas por metadados e aplicadas automaticamente durante a manutenção dos dados.

### Transações

O CRUDEX possui suporte nativo ao ciclo:

* Validate
* Persist
* Commit

permitindo tratamento consistente das operações realizadas pelo usuário.

## Arquitetura

O sistema é baseado em uma arquitetura SPA (Single Page Application), composta por:

* Frontend Web
* API REST
* Banco de Dados
* Metadados centralizados

A estrutura permite evolução da aplicação sem necessidade de alterações específicas para cada sistema construído sobre a plataforma.

## Integração com Wordex

O CRUDEX foi projetado para integração com o Wordex.

Com isso, documentos, relatórios, contratos, etiquetas, crachás e PDFs podem ser gerados diretamente a partir dos dados mantidos pelo sistema.

## Objetivo

O principal objetivo do CRUDEX é reduzir drasticamente o trabalho repetitivo de desenvolvimento de sistemas de informação, permitindo que o desenvolvedor concentre seus esforços nas regras de negócio e não na implementação manual de operações CRUD.

Em outras palavras:

Descreva o sistema.

O CRUDEX gera dinamicamente a aplicação.

## Documentação

- [Manual do CRUDEX 1.0](MANUAL.md) — guia do usuário e do desenvolvedor
- [Estado atual do projeto](ESTADO-ATUAL.md) — retrato do que existe, pendências e como retomar
