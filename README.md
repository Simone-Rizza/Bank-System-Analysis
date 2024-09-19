# Bank System Analysis
 
In this SQL project we are going to create a denormalized table containing behavioral indicators about the customer, computed on the basis of transactions and product possession. The purpose is to create features for a possible supervised machine learning model. The indicators created will refer to each singolo id_cliente and will indicate:
- Age
- Number of outgoing transactions on all accounts
- Number of incoming transactions on all accounts
- Amount transacted outgoing on all accounts
- Amount transacted inbound on all accounts
- Total number of accounts held
- Number of accounts held by type (one indicator per type)
- Number of outgoing transactions by type (one indicator per type)
- Number of incoming transactions by type (one indicator per type)
- Amount transacted outbound by account type (one indicator per type)
- Amount transacted inbound by account type (one indicator per type)