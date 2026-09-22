# Miniprojeto SCTEC

A Pata Amiga é uma rede catarinense de pet shops. Começou com uma loja em Blumenau, em 2009, e hoje tem 32 lojas espalhadas pelo estado, de Itapoá a São Miguel do Oeste.

Em setembro de 2023 a rede ligou a operação de pedidos com entrega + app, site, telefone, WhatsApp e a própria loja física. Em sete meses foram 4.044 pedidos. A diretoria quer usar esses sete meses para decidir o próximo ciclo: onde está o gargalo da entrega, qual categoria sustenta o faturamento, se a política de desconto funciona igual em todo canal, e onde abrir a próxima loja.

O dado existe. O problema é que ele está em três sistemas que não se falam: a plataforma de e-commerce (os pedidos e os marcos da entrega), o cadastro de lojas do franchising, e a planilha de praças de atendimento que o time de expansão mantém à parte. Cada um escreve do seu jeito: a mesma loja aparece com acento, sem acento, em caixa alta e com erro de digitação; a mesma categoria tem várias grafias; data e dinheiro vêm como texto.

Reorganizar dados não parece grande coisa até você ver o que aparece do outro lado. Quando as três bases finalmente conversam, frases assim saltam da tela: que o gargalo não está na entrega, e sim entre a nota fiscal e o despacho; que uma praça concentra faturamento muito acima do seu número de domicílios com pet.

#### Perguntas de negócio:

P1 - ONDE ESTA O GARGALO DO PROCESSO DE ENTREGA?

P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?

P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?

P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?

P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?

#### Diagnóstico da origem:

|Diagnóstico    |Valor|
| ---: | ---: |
|Grafias distintas de categoria (no MySQL)   |   18|
|Grafias distintas de nome de loja           |   50|
|Grafias distintas de HouveDesconto          |   12|
|Grafias distintas de CanalPedido            |    8|
|Pedidos sem Cod Loja preenchido             | 1575|
|Pedidos sem nome de loja (vao para a -1)    |    3|

Para fazer o tratamento da base criei uma tabela limpa_pedido onde foram colocado varios Update para tratar os dados.
O nome da loja foram tratados com a função REPLACE E CASE, as colunas HouveDesconto e CanalPedido foram tratados através das tabelas dim_desconto e dim_canal com update e join na tabela limpa_pedido.



#### P1 : Onde está o gargalo da entrega?

O principal gargalo está no intervalo Nota → Despacho, que apresenta o maior tempo médio nos três portes de loja. As lojas grandes apresentam tempo médio total de entrega de 8,04 dias, as médias de 8,06 dias e as pequenas de 15,27 dias.



  <div>
    <img width="768" height="432" alt="Image" src="https://github.com/user-attachments/assets/e91f3898-2928-43be-adba-9b39bbbbb283" />
  </div>

#### P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?

A categoria Ração concentra a maior parcela do faturamento da rede, totalizando R$ 1.076.202,55, equivalente a 60,01% do faturamento total. A segunda maior categoria é Medicamento, com 17,06%, seguida por Petisco, com 7,17%. As demais categorias representam individualmente menos de 6% do faturamento.

  <div>
    <img width="768" height="432" alt="Image" src="https://github.com/user-attachments/assets/b582f6c2-005a-4c5d-ad03-161bc50a53e2" />
  </div>

  
#### P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?

Os pedidos com desconto apresentam ticket médio superior aos pedidos sem desconto. O maior aumento de ticket ocorre no WhatsApp, com diferença de R$ 335,07, seguido pelo App (R$ 320,41), Telefone (R$ 318,79), Site (R$ 312,24) e Loja Física (R$ 296,49). Assim, o desconto apresenta um padrão semelhante nos diferentes canais, pois em todos eles os pedidos com desconto possuem ticket médio maior.

Participação no faturamento é diferente entre os canais:

App:           30,79% — maior participação

Site:          25,13%

Loja Física:   20,11%

WhatsApp:      10,52%

Telefone:      6,88%

Não informado: 6,57%

 <div>
    <img width="768" height="432" alt="Image" src="https://github.com/user-attachments/assets/3f9c8a31-ab41-4eba-bf5d-4b327522b8ba" />
  </div>

  
#### P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?

A praça que concentra o maior faturamento é a Vale do Itajaí (PRC01), com R$ 633.746,09, correspondente a 35,34% do faturamento da rede. Na sequência aparecem a Grande Florianópolis, com R$ 283.546,75 (15,81%), e o Norte Industrial, com R$ 175.431,90 (9,78%).

 <div>
    <img width="768" height="432" alt="Image" src="https://github.com/user-attachments/assets/80fab5d0-a8e3-4872-b22e-ace4a16fd0a9" />
  </div>

#### P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?

As maiores taxas de itens vendidos por 1000 habitantes estão concentradas nas lojas pequenas:

|Cod_loja | Loja  |Itens por habitantes| Entrega média|
| ---: | ---: | ---: | ---: |
|LJ-012 | Rio dos Cedros            | 41,87 | 14,31 |
|LJ-008 | Presidente Getúlio        | 34,84 | 14,26 |
|LJ-011 | Ibirama                   |32,07  | 15,50 |
|LJ-016 | Itapoá                    |25,94  | 15,53 |
|LJ-020 | Santo Amaro da Imperatriz | 23,71 | 16,00 |

Por outro lado, as lojas médias apresentam tempo de entrega bem menor, em torno de 7,77 a 8,69 dias.
Os dados indicam que Rio dos Cedros apresenta uma demanda relativa elevada, mas também um tempo de entrega elevado, sendo uma localidade que merece investigação para uma possível expansão.


#### Diagrama estrela:

  <div>
    <img width="1001" height="689" alt="Image" src="https://github.com/user-attachments/assets/f50d42a3-3864-4ed4-8746-410294f12070" />
  </div>


