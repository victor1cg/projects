/*Dashboard do criado no Power BI
https://app.powerbi.com/view?r=eyJrIjoiZmQ1NTQzM2MtMTUzNy00N2UyLWJiMTctYzU5ZWM0MzVkZjJiIiwid
CI6IjhjYTZhODNhLWZmNzgtNGM3ZC04NDhlLTM4YWM2YTEyMWJiYiJ9
--------------------------
DASHBOARD OLIST ANALYTICS
--------------------------
Bases: olist_customer_ID_dataset,olist_order_items_dataset,olist_orders_dataset,olist_sellers_dataset.csv
Objetivo:	Analisar, correlacionar e transformar as bases de dados, em dashboards do Power Bi
			para tirarmos insights e tomadas de decisões de maneira agil. 
Autor: Victor Gonçalves
Data: 23.jan.2020
*/

CREATE DATABASE OLIST
USE OLIST

-- AGRUPANDO POR SELLERS
SELECT			SELLER.seller_id,					
				SUM(ITEM.price) as FATURAMENTO,
				COUNT(ITEM.price) AS QTD_ORDERS,
				YEAR(ORDEM.order_purchase_timestamp) AS ANO,
				SELLER.seller_state as ESTADO
					FROM olist_sellers_dataset AS SELLER			--JOIN SELLER COM ITEM
						INNER JOIN olist_order_items_dataset AS ITEM
						ON SELLER.seller_id=ITEM.seller_id
						INNER JOIN olist_orders_dataset		AS ORDEM	--JOIN ITEM COM ORDEM
						ON ORDEM.order_id=ITEM.order_id
GROUP BY SELLER.seller_id, ITEM.price, SELLER.seller_state,ORDEM.order_purchase_timestamp
ORDER BY FATURAMENTO DESC

-- TOP 10 PRODUTOS POR VENDA TOTAL (QTDE*PREÇO)
SELECT product_id,									
	COUNT(product_id) as QTDE,
	price
	INTO #tmp2									--TABELA TEMPORARIA2: PRODUCT_ID, QTDE VENDIDA,PREÇO. 
	FROM olist_order_items_dataset AS ITEM
GROUP BY product_id, price
ORDER BY QTDE DESC

select	TOP(10) *,								
		QTDE * price as FATURAMENTO
		from #tmp2
ORDER BY FATURAMENTO DESC

-- TICKET MÉDIO DOS ESTADOS 

SELECT			SELLER.seller_state as ESTADO,							
				SUM(ITEM.price) as VALOR_TOTAL_VENDA,
				COUNT(ITEM.price) AS QTD_ORDERS
				--INTO #tmp3												--TABELA TEMPORARIA P/ CALCULOS
						FROM olist_sellers_dataset AS SELLER			--JOIN SELLER COM ITEM
						INNER JOIN olist_order_items_dataset AS ITEM
						ON SELLER.seller_id=ITEM.seller_id
						INNER JOIN olist_orders_dataset	AS ORDEM		--JOIN ITEM COM ORDEM
						ON ORDEM.order_id=ITEM.order_id
GROUP BY SELLER.seller_state
ORDER BY VALOR_TOTAL_VENDA DESC

DROP TABLE #tmp3

SELECT	*,															
		VALOR_TOTAL_VENDA/QTD_ORDERS AS TICKET_MEDIO				--CALCULANDO O TICKET MEDIO POR ESTADO
		FROM #tmp3
		ORDER BY TICKET_MEDIO DESC

-- TOP 10 SELLER POR VALOR TOTAL DE VENDAS
SELECT TOP (10)	SELLER.seller_id,					
				SUM(ITEM.price) AS VALOR_TOTAL,
				COUNT (ITEM.price) AS QTD_ORDERS,
				SELLER.seller_state as ESTADO
				--INTO #tmp4
						FROM olist_sellers_dataset AS SELLER			--JOIN SELLER COM ITEM
						INNER JOIN olist_order_items_dataset AS ITEM
						ON SELLER.seller_id=ITEM.seller_id
						INNER JOIN olist_orders_dataset		AS ORDEM	--JOIN ITEM COM ORDEM
						ON ORDEM.order_id=ITEM.order_id
GROUP BY SELLER.seller_id, ITEM.price, SELLER.seller_state
ORDER BY VALOR_TOTAL DESC


------- TEMPO MÉDIO DE ENTREGA POR ESTADO x ANO x MES
SELECT		SELLER.seller_state as ESTADO,
			DATEDIFF(day,ORDEM.order_purchase_timestamp,ORDEM.order_delivered_customer_date) AS TEMPO_ENTREGA,
			YEAR(ORDEM.order_purchase_timestamp) AS ANO,
			MONTH (ORDEM.order_purchase_timestamp) AS MES
			INTO #tmp5
						FROM olist_sellers_dataset AS SELLER			--JOIN SELLER COM ITEM
						INNER JOIN olist_order_items_dataset AS ITEM
						ON SELLER.seller_id=ITEM.seller_id
						INNER JOIN olist_orders_dataset		AS ORDEM	--JOIN ITEM COM ORDEM
						ON ORDEM.order_id=ITEM.order_id
						WHERE order_delivered_customer_date IS NOT NULL
ORDER BY TEMPO_ENTREGA ASC

SELECT	ANO,															-- REALIZANDO OS CAL
		MES,
		ESTADO,
		AVG (TEMPO_ENTREGA) AS MEDIA_TEMPO_ENTREGA
		FROM #tmp5
GROUP BY ANO,MES,ESTADO
ORDER BY ESTADO ASC

---- CIDADES COM MAIOR TEMPO MÉDIO DE ENTREGA POR ESTADO
SELECT		CUSTOMER.customer_id,
			ORDEM.order_id,
			CUSTOMER.customer_state as ESTADO,
			CUSTOMER.customer_city AS CIDADE,
			DATEDIFF(day,ORDEM.order_purchase_timestamp,ORDEM.order_delivered_customer_date) AS TEMPO_ENTREGA
			INTO #tmp8
						FROM olist_customer_ID_dataset		AS CUSTOMER		--JOIN SELLER COM ITEM
						INNER JOIN olist_orders_dataset		AS ORDEM		--JOIN ITEM COM ORDEM
						ON ORDEM.customer_id=CUSTOMER.customer_id
						WHERE order_delivered_customer_date IS NOT NULL
ORDER BY TEMPO_ENTREGA ASC

SELECT TOP (20)	CIDADE,										--CALCULANDO AS 20 CIDADES COM MAIS DE 200 ENTREGAS
				ESTADO,										-- E QUE POSSUEM O MAIOR TEMPO MÉDIO DE ENTREGA
				AVG (TEMPO_ENTREGA) AS TEMPO_MEDIO,
				COUNT (order_id) AS QTDE_ENTREGA
				FROM #tmp8
			GROUP BY CIDADE, ESTADO
			HAVING COUNT(order_id) > '200'
			ORDER BY TEMPO_MEDIO DESC

------------- TICKET MÉDIO POR ESTADO/MES/ANO
DROP TABLE #tmp6

SELECT	SELLER.seller_state AS ESTADO,
		DATEPART(year,ORDEM.order_purchase_timestamp) as ANO,
		DATEPART(MONTH,ORDEM.order_purchase_timestamp) as MES,	
		SUM(ITEM.price) AS VALOR_TOTAL,
		COUNT (ITEM.price) AS QTDE
		INTO #tmp6
				FROM olist_sellers_dataset AS SELLER			--JOIN SELLER COM ITEM
				INNER JOIN olist_order_items_dataset AS ITEM
				ON SELLER.seller_id=ITEM.seller_id
				INNER JOIN olist_orders_dataset		AS ORDEM	--JOIN ITEM COM ORDEM
				ON ORDEM.order_id=ITEM.order_id
		GROUP BY seller_state,YEAR(ORDEM.order_purchase_timestamp),MONTH(ORDEM.order_purchase_timestamp)
		ORDER BY ANO, MES,ESTADO

SELECT	*,
		VALOR_TOTAL/QTDE AS TICKET_MEDIO
		FROM #tmp6

------- TESTE 10 cidade por estado
SELECT		CUSTOMER.customer_state as ESTADO,
			CUSTOMER.customer_city AS CIDADE,
			DATEDIFF(day,ORDEM.order_purchase_timestamp,ORDEM.order_delivered_customer_date) AS TEMPO_ENTREGA
			INTO #tmp9
						FROM olist_customer_ID_dataset		AS CUSTOMER		--JOIN SELLER COM ITEM
						INNER JOIN olist_orders_dataset		AS ORDEM		--JOIN ITEM COM ORDEM
						ON ORDEM.customer_id=CUSTOMER.customer_id
						WHERE order_delivered_customer_date IS NOT NULL
ORDER BY TEMPO_ENTREGA ASC

SELECT 			ESTADO,
				CIDADE,
				AVG (TEMPO_ENTREGA) OVER(PARTITION BY ESTADO ORDER BY TEMPO_ENTREGA DESC) AS INDICE
				FROM #tmp8
			GROUP BY CIDADE, ESTADO, TEMPO_ENTREGA
			HAVING COUNT(TEMPO_ENTREGA) > '10'

SELECT * FROM #tmp9
