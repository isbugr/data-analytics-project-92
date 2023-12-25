-- Отчет о количестве покупателей
select COUNT(*) as customers_count -- считаем количество строк в таблице customers
from customers c 



-- Отчет о десятке лучших продавцов
select
	concat(e.first_name, ' ', e.last_name) as name, -- объединяем имя и фамилию продавца в одну строку
	count(s.sales_person_id) as operations, -- считаем количество продаж каждого продавца
	floor(sum(s.quantity * p.price)) as income	-- считаем выручку каждого продавца
from sales s 
left join employees e on
	s.sales_person_id = e.employee_id
left join products p on
	s.product_id = p.product_id
group by e.first_name, e.last_name
order by income desc
limit 10



-- Отчет о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам
select
	concat(e.first_name, ' ', e.last_name) as name, -- объединяем имя и фамилию продавца в одну строку
	floor(avg(s.quantity * p.price)) as average_income -- считаем среднюю выручку продавца за сделку
from sales s 
left join employees e on
	s.sales_person_id = e.employee_id
left join products p on
	s.product_id = p.product_id
group by e.first_name, e.last_name
having sum(s.quantity * p.price) / count(s.sales_person_id) < ( -- вычисляем среднюю выручку за сделку по всем продавцам
																select
																	avg(s.quantity * p.price)
																from sales s
																left join products p on
																	s.product_id = p.product_id)
order by average_income



-- Отчет о выручке по дням недели
/*
 * Создадим временную таблицу, которая дополнительно будет содержать номер дня недели.
 * Это необходимо для сортировки данных по дням недели, начиная от понедельника,
 * заканчивая воскресеньем.
 */
with weekday_with_numb as(
select
	concat(e.first_name, ' ', e.last_name) as name, -- объединяем имя и фамилию продавца в одну строку
	to_char(s.sale_date, 'day') as weekday, -- находим день недели
	to_char(s.sale_date - 1, 'd') as wkd_numb, -- цифровое представление дня недели
	floor(sum(s.quantity * p.price)) as income	-- считаем выручку продавца для каждого дня недели
from sales s 
left join employees e on
	s.sales_person_id = e.employee_id
left join products p on
	s.product_id = p.product_id
group by wkd_numb, weekday, e.first_name, e.last_name
order by wkd_numb, name)

-- Выбираем необходимые столбцы из временной таблицы
select 
	name,
	weekday,
	income
from weekday_with_numb



-- Количество покупателей в разных возрастных группах
select 
	case  -- Распределяем покупателей по возрастным группам
		when age between 16 and 25 then '16-25'
		when age between 26 and 40 then '26-40'
		when age > 40 then '40+'		
	end as age_group,
	count(*) as count -- Считаем количество покупателей в каждой группе
from customers c 
group by age_group
order by age_group



-- Количество уникальных покупателей и выручке, которую они принесли
select
	to_char(s.sale_date, 'yyyy-mm') as date, -- выбираем год и месяц
	count(distinct s.customer_id) as total_customers, -- считаем количество уникальных покупателей по месяцам
	floor(sum(s.quantity * p.price)) as income	-- считаем выручку по покупателям
from sales s
left join products p on
	s.product_id = p.product_id
group by date
order by date


-- Отчет о покупателях, первая покупка которых была в ходе проведения акций
/*
 * Создадим временную таблицу, которая дополнительно будет содержать номер покупки,
 * в зависимости от даты приобретения акционного товара покупателем.
 * Это необходимо для выбора даты первой покупки акционного товара.
 */
with rep_with_rownmb as( 
select
	concat(c.first_name, ' ', c.last_name) as customer,
	s.sale_date,
	row_number() over(partition by s.customer_id order by s.sale_date), 
	concat(e.first_name, ' ', e.last_name) as seller
from sales s 
left join employees e on
	s.sales_person_id = e.employee_id
left join customers c on
	s.customer_id = c.customer_id
left join products p on
	s.product_id = p.product_id
where p.price = 0
order by s.customer_id
)
-- Выбираем необходимые стобцы из временной таблицы, с порядковым номером покупки равным 1.
select 
	customer,
	sale_date,
	seller
from rep_with_rownmb
where row_number = 1