O projeto CRUDEX que já está quase em fase final de desenvolvimento promete automatizar ao máximo o desenvolvimento de sistemas.

Até tive que inventar um conceito novo para ele: SGSI - Sistema Gerenciador de Sistemas de Informação.

Em paralelo a esse conceito, já existe no mercado os conceitos de SGBD SQL e SGBD no-SQL.

Se, futuramente, alguém criar um novo padrão de SGSI haverá os SGSI CRUDEX e os SGSI no-CRUDEX.

O que tem de novo nisso?

Oras, o analista de negócios especifica o sistema diretamente no CRUDEX, definindo tabelas, validações, índices, foreign-keys, primary-keys, etc. dessas tabelas.

O CRUDEX se encarrega de gerar automaticamente os scripts DDLs e DMLs do sistema sendo especificado, juntamente com os scripts de stored procedures responsáveis pela execução das operações de CRUD.

O CRUDEX também já fornece um frontend padrão no qual o analista de negócios já pode executar seu sistema recém-especificado, após criar o banco-de-dados executando apenas os scripts gerados automaticamente.

Desse modo, toda a inteligência do sistema se concentra no banco-de-dados, bem como as regras de negócio.

Assim, o analista de negócios não depende mais do desenvolvedor para testar suas especificações e caso o usuário goste do frontend padrão, o sistema já pode ser considerado concluído.

Caso o usuário queira um frontend mais charmoso e bonito, aí o desenvolvedor entra em ação e desenvolve um frontend melhor, desde que para executar as operações de CRUD, ele faça chamadas aos endpoints da API e não diretamente às stored procedures do banco-de-dados.

Com isso, o backend nunca mais será problema do desenvolvedor e sim, do analista de negócios ou até mesmo do DBA.

Ao desenvolvedor caberá apenas a tarefa de fazer frontends não padrão para aplicações específicas como aplicativos em celular, por exemplo.

Há várias funcionalidades extras implementadas, mas o básico é esse.
