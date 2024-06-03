--Aylık olarak order dağılımını inceleyiniz.
--Tarih verisi için order_approved_at kullanılmalıdır.SELECT
    
	
SELECT 
    TO_CHAR(order_approved_at, 'YYYY-MM') AS "Aylık tarih",
    COUNT(order_id) AS "Sipariş sayısı"
FROM 
    orders
WHERE 
    order_approved_at IS NOT NULL
GROUP BY 
    TO_CHAR(order_approved_at, 'YYYY-MM')
ORDER BY 
    "Aylık tarih" ASC;
	
	
	
--Aylık olarak order status kırılımında order sayılarını inceleyiniz. 
--Sorgu sonucunda çıkan outputu excel ile görselleştiriniz. Dramatik bir düşüşün ya da yükselişin olduğu aylar var mı?
--Veriyi inceleyerek yorumlayınız.	
	
SELECT 
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS ay,
    order_status,
    COUNT(*) AS siparis_sayisi
FROM 
    orders
GROUP BY 
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM'),
    order_status
ORDER BY 
    ay;
	
	
--Ürün kategorisi kırılımında sipariş sayılarını inceleyiniz. Özel günlerde öne çıkan kategoriler nelerdir?
--Örneğin yılbaşı, sevgililer günü…

	sELECT
    to_char(order_approved_at, 'YYYY-MM') AS tarih,
    t.category_name_english AS urun,
    COUNT(o.order_id) AS siparis_sayisi
FROM 
    orders o
JOIN 
    order_items oi ON o.order_id = oi.order_id
JOIN 
    products p ON oi.product_id = p.product_id
JOIN 
    translation t ON t.category_name = p.product_category_name
WHERE 
    (EXTRACT(MONTH FROM o.order_approved_at) = 2 AND EXTRACT(YEAR FROM o.order_approved_at) = 2017) OR
    (EXTRACT(MONTH FROM o.order_approved_at) = 2 AND EXTRACT(YEAR FROM o.order_approved_at) = 2018) OR
    (EXTRACT(MONTH FROM o.order_approved_at) = 11 AND EXTRACT(YEAR FROM o.order_approved_at) = 2017) OR
    (EXTRACT(MONTH FROM o.order_approved_at) = 11 AND EXTRACT(YEAR FROM o.order_approved_at) = 2018)
GROUP BY 
    1, 2
ORDER BY 
    3 DESC
LIMIT 10;
 

--Haftanın günleri(pazartesi, perşembe, ….) ve ay günleri (ayın 1’i,2’si gibi) bazında order sayılarını 
--inceleyiniz. Yazdığınız sorgunun outputu ile excel’de bir görsel oluşturup yorumlayınız.

--sorgu1

SELECT
    TO_CHAR(o.order_purchase_timestamp, 'Day') AS gun,
    COUNT(DISTINCT o.order_id) AS siparis_sayisi
FROM
    orders AS o
GROUP BY
    TO_CHAR(o.order_purchase_timestamp, 'Day')
ORDER BY
    TO_CHAR(MIN(o.order_purchase_timestamp), 'Day');



--sorgu 2

SELECT
    EXTRACT(day FROM order_purchase_timestamp) AS gun,
    COUNT(DISTINCT order_id) AS "sipariş sayisi"
FROM
    orders
GROUP BY
    gun;

--Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor? Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız. 

--Örneğin; Sibel Çanakkale’den 3, Muğla’dan 8 ve İstanbul’dan 10 sipariş olmak üzere 3 farklı şehirden sipariş veriyor. Sibel’in şehrini en çok sipariş verdiği şehir olan İstanbul olarak seçmelisiniz
--ve Sibel’in yaptığı siparişleri İstanbul’dan 21 sipariş vermiş şekilde görünmelidir.



WITH siparis_sayilari AS (
    SELECT
        c.customer_unique_id,
        c.customer_city,
        COUNT(o.order_id) AS siparis_sayisi
    FROM
        orders o
    JOIN
        customers c ON o.customer_id = c.customer_id
    GROUP BY
        c.customer_unique_id,
        c.customer_city
),
en_cok_siparis_verilen_sehirler AS (
    SELECT
        customer_unique_id,
        customer_city,
        RANK() OVER (PARTITION BY customer_unique_id ORDER BY siparis_sayisi DESC) AS siralama
    FROM
        siparis_sayilari
)
SELECT
    ss.customer_unique_id,
    CASE WHEN escsvs.siralama = 1 THEN escsvs.customer_city ELSE 'Diğer' END AS en_cok_siparis_verilen_sehir,
    SUM(ss.siparis_sayisi) AS toplam_siparis
FROM
    en_cok_siparis_verilen_sehirler escsvs
JOIN
    siparis_sayilari ss ON escsvs.customer_unique_id = ss.customer_unique_id
    AND escsvs.customer_city = ss.customer_city
GROUP BY
    ss.customer_unique_id,
    en_cok_siparis_verilen_sehir
ORDER BY
    toplam_siparis DESC;




--Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir?
--Top 5 getiriniz. Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve 
--puanlamaları inceleyiniz ve yorumlayınız.

SELECT oi.seller_id, 
	   COUNT (re.review_comment_message )as yorum_sayisi,       
       ROUND (AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_approved_at)) / 86400)) as ortalama_teslimat_suresi,
	   ROUND (AVG(re.review_score)) AS ortalama_puanlama
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN reviews re ON re.order_id = oi.order_id
WHERE oi.seller_id IN (SELECT seller_id
                       FROM order_items
                       GROUP BY seller_id
                       ORDER BY COUNT(*) DESC
                       LIMIT 5)
GROUP BY oi.seller_id
ORDER BY ortalama_teslimat_suresi;

--Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır? 
 --Fazla kategoriye sahip satıcıların order sayıları da fazla mı? 

WITH urun_kategorileri AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT p.product_category_name) AS kategori_sayisi,
        COUNT(DISTINCT oi.order_id) AS toplam_siparis_adedi
    FROM
        order_items oi
    JOIN
        products p ON oi.product_id = p.product_id
    GROUP BY
        oi.seller_id
)
SELECT
    uk.seller_id,
    uk.kategori_sayisi,
    uk.toplam_siparis_adedi
FROM
    urun_kategorileri uk
ORDER BY
    uk.kategori_sayisi DESC
	LIMIT 20;


--Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi bölgede yaşamaktadır? 
--Bu çıktıyı yorumlayınız.


SELECT DISTINCT c.customer_city, c.customer_state, COUNT(distinct p.payment_installments) AS installment_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
WHERE o.customer_id NOT IN (SELECT customer_id FROM orders WHERE order_id IN (SELECT order_id FROM payments GROUP BY order_id HAVING COUNT(payment_installments) > 1))
GROUP BY c.customer_city, c.customer_state
ORDER BY installment_count DESC;



--Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız
--En çok kullanılan ödeme tipinden en az olana göre sıralayınız.


	
	SELECT p.payment_type, 
       COUNT(DISTINCT o.order_id) as successful_order_count, 
      round( SUM(p.payment_value) )as total_successful_payment_amount
FROM payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered' 
GROUP BY p.payment_type
ORDER BY COUNT(DISTINCT o.order_id) DESC;



--Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız.
--En çok hangi kategorilerde taksitle ödeme kullanılmaktadır

SELECT 
    product_category_name,
    CASE 
        WHEN py.payment_installments > 1 THEN 'Taksitli'
        ELSE 'Tek Çekim'
    END AS odeme_tipi,
    COUNT(*) AS siparis_sayisi 
FROM 
    order_items oi
JOIN 
    orders o ON oi.order_id = o.order_id
JOIN 
    payments py ON py.order_id = o.order_id
JOIN 
    products p ON p.product_id = oi.product_id
WHERE 
    py.payment_type = 'credit_card'
GROUP BY 
    product_category_name, odeme_tipi
ORDER BY 
    siparis_sayisi DESC;

