/*we create temporary views for individual queries, we will use them later to run
a more complex query to create our denormalized table*/

-- Customer's age:
create temporary table eta AS
select cli.id_cliente, nome, cognome, 
       timestampdiff(year, data_nascita, curdate()) as eta 
from cliente cli
left join conto con
on cli.id_cliente = con.id_cliente;

-- Outgoing and incoming transacted amount on all accounts:
create temporary table importo_trans_totali as
select id_conto,
       round(sum(case when id_tipo_trans in (0, 1, 2) then importo else 0 end),2) as importo_totale_trans_entrata,
       round(sum(case when id_tipo_trans in (3, 4, 5, 6, 7) then importo else 0 end),2) as importo_totale_trans_uscita
from banca.transazioni
group by id_conto;

-- Number of outgoing and incoming transactions by type:
create temporary table numero_transazioni as
select id_conto,
       sum(case when id_tipo_trans = 0 then 1 else 0 end) as stipendio,
       sum(case when id_tipo_trans = 1 then 1 else 0 end) as pensione,
       sum(case when id_tipo_trans = 2 then 1 else 0 end) as dividendi,
       sum(case when id_tipo_trans in (0,1,2) then 1 else 0 end) as num_trans_entrata,
       sum(case when id_tipo_trans = 3 then 1 else 0 end) as acquisto_amazon,
       sum(case when id_tipo_trans = 4 then 1 else 0 end) as rata_mutuo,
       sum(case when id_tipo_trans = 5 then 1 else 0 end) as hotel,
       sum(case when id_tipo_trans = 6 then 1 else 0 end) as biglietto_aereo,
       sum(case when id_tipo_trans = 7 then 1 else 0 end) as supermercato,
       sum(case when id_tipo_trans in (3,4,5,6,7) then 1 else 0 end) as num_trans_uscita
from banca.transazioni
group by id_conto;

-- Number of accounts by type and number of total accounts:
create temporary table numero_conti as
select id_cliente,
       sum(case when id_tipo_conto = 0 then 1 else 0 end) as numero_conti_base,
       sum(case when id_tipo_conto = 1 then 1 else 0 end) as numero_conti_business,
       sum(case when id_tipo_conto = 2 then 1 else 0 end) as numero_conti_privati,
       sum(case when id_tipo_conto = 3 then 1 else 0 end) as numero_conti_famiglie,
       sum(case when id_tipo_conto in (0,1,2,3) then 1 else 0 end) as numero_tot_conti
from conto
group by id_cliente;

-- Outgoing and incoming transacted amount by account type:
create temporary table import_trans_tipo_conto as
select 
    cl.id_cliente,
    cl.nome,
    cl.cognome,
    cl.data_nascita,
    round(sum(case when tc.id_tipo_conto = '0' and t.id_tipo_trans in (3,4,5,6,7) then t.importo else 0 end), 2) as spese_uscita_conto_base,
    round(sum(case when tc.id_tipo_conto = '1' and t.id_tipo_trans in (3,4,5,6,7) then t.importo else 0 end), 2) as spese_uscita_conto_business,
    round(sum(case when tc.id_tipo_conto = '2' and t.id_tipo_trans in (3,4,5,6,7) then t.importo else 0 end), 2) as spese_uscita_conto_privati,
    round(sum(case when tc.id_tipo_conto = '3' and t.id_tipo_trans in (3,4,5,6,7) then t.importo else 0 end), 2) as spese_uscita_conto_famiglie,
    round(sum(case when tc.id_tipo_conto = '0' and t.id_tipo_trans in (0,1,2) then t.importo else 0 end), 2) as spese_entrata_conto_base,
    round(sum(case when tc.id_tipo_conto = '1' and t.id_tipo_trans in (0,1,2) then t.importo else 0 end), 2) as spese_entrata_conto_business,
    round(sum(case when tc.id_tipo_conto = '2' and t.id_tipo_trans in (0,1,2) then t.importo else 0 end), 2) as spese_entrata_conto_privati,
    round(sum(case when tc.id_tipo_conto = '3' and t.id_tipo_trans in (0,1,2) then t.importo else 0 end), 2) as spese_entrata_conto_famiglie
from 
    banca.cliente cl
left join 
    banca.conto c on cl.id_cliente = c.id_cliente
left join 
    banca.tipo_conto tc on c.id_tipo_conto = tc.id_tipo_conto
left join 
    banca.transazioni t on c.id_conto = t.id_conto
group by 
    cl.id_cliente, cl.nome, cl.cognome, cl.data_nascita
order by 
    cl.id_cliente;
    
-- Let us now run the query that will create our denormalized table:
create table features as
select 
    e.id_cliente,
    e.eta,
    nc.numero_tot_conti,
    nc.numero_conti_base,
    nc.numero_conti_business,
    nc.numero_conti_privati,
    nc.numero_conti_famiglie,
    sum(nt.num_trans_entrata) as totale_trans_entrata,
    sum(nt.num_trans_uscita) as totale_trans_uscita,
    sum(itt.importo_totale_trans_entrata) as importo_totale_entrata,
    sum(itt.importo_totale_trans_uscita) as importo_totale_uscita,
    sum(nt.stipendio) as num_trans_stipendio,
    sum(nt.pensione) as num_trans_pensione,
    sum(nt.dividendi) as num_trans_dividendi,
    sum(nt.acquisto_amazon) as num_trans_acquisto_amazon,
    sum(nt.rata_mutuo) as num_trans_rata_mutuo,
    sum(nt.hotel) as num_trans_hotel,
    sum(nt.biglietto_aereo) as num_trans_biglietto_aereo,
    sum(nt.supermercato) as num_trans_supermercato,
    ittc.spese_uscita_conto_base,
    ittc.spese_uscita_conto_business,
    ittc.spese_uscita_conto_privati,
    ittc.spese_uscita_conto_famiglie,
    ittc.spese_entrata_conto_base,
    ittc.spese_entrata_conto_business,
    ittc.spese_entrata_conto_privati,
    ittc.spese_entrata_conto_famiglie
from 
    eta e
left join 
    numero_conti nc on e.id_cliente = nc.id_cliente
left join 
    conto c on e.id_cliente = c.id_cliente
left join 
    numero_transazioni nt on c.id_conto = nt.id_conto
left join 
    importo_trans_totali itt on c.id_conto = itt.id_conto
left join 
    import_trans_tipo_conto ittc on e.id_cliente = ittc.id_cliente
group by 
    e.id_cliente, e.eta, 
    nc.numero_tot_conti, nc.numero_conti_base, nc.numero_conti_business, nc.numero_conti_privati, nc.numero_conti_famiglie,
    ittc.spese_uscita_conto_base, ittc.spese_uscita_conto_business, ittc.spese_uscita_conto_privati, ittc.spese_uscita_conto_famiglie,
    ittc.spese_entrata_conto_base, ittc.spese_entrata_conto_business, ittc.spese_entrata_conto_privati, ittc.spese_entrata_conto_famiglie
order by 
    e.id_cliente;