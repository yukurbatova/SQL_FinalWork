SET search_path TO bookings;

--1. В каких городах больше одного аэропорта?
--В таблице Аэропорты группирую строки по полю Город и отфильтровываю те, в которых количество  > 1

select
	city as "Город"
from  airports
group by city
having count(airport_code) > 1;

--2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
-- В подзапросе  к таблице Самолеты определяю самолеты с максимальной дальностью перелета, определяю для рейса этого самолета
-- аэропорт вылета
select
	airport_code as "Код аэропорта",
	airport_name as "Название аэропорта"
from airports
where
	airport_code in 
(
	select departure_airport
	from flights
	where
		aircraft_code = (
		select aircraft_code
		from aircrafts
		where
			range = (
			select max(range)
			from aircrafts)
)
);

--3. Вывести 10 рейсов с максимальным временем задержки вылета
-- По таблице Рейсы определяю рейсы, у которых ненулевая разница времени фактического вылета и вылета по расписанию,
-- сортирую по убыванию, оставляя первые 10 результатов

select
	flight_no as "Номер рейса",
	(actual_departure - scheduled_departure) as "Задержка вылета"
from flights
where
	(actual_departure - scheduled_departure) is not null
order by 2 desc
limit 10;

--4. Были ли брони, по которым не были получены посадочные талоны?
-- Делаю левое объединение таблиц Билеты и Посадочные талоны (т.к. нужно иметь инфломацию по всем посадочным талонам), отфильтровываюпо билеты
-- по отсутвию номера посадочного талона, и объединяя с таблицей Бронирования, получаю уникальные номера бронирований

select distinct b.book_ref
from bookings b
join tickets t on b.book_ref = t.book_ref
left join boarding_passes bp on t.ticket_no = bp.ticket_no
where bp.boarding_no is null;

--5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.

-- В СТЕ определяю общее количество мест в каждом самолете
with total_seats_by_aircraft as(
select 
		s.aircraft_code,
		count(s.seat_no) total_seats
from seats s
group by s.aircraft_code 
),
-- В СТЕ определяю количество мест, по которым получены посадочные талоны (= занятых мест), для каждого рейса, который уже вылетел 
occupied_seats_by_aircraft as (
select 
		f.flight_id,
		f.flight_no,
		f.aircraft_code,
		f.departure_airport,
		f.actual_departure,
		count(bp.boarding_no) occupied_seats
from flights f
join boarding_passes bp on f.flight_id = bp.flight_id
where f.actual_departure is not null
group by f.flight_id 
)
-- В результирующем запросе объединяю оба СТЕ по коду самолета
select 
	os.flight_no as "Номер рейса",
	ts.total_seats - os.occupied_seats as "Свободные места по рейсу", 
	round((ts.total_seats - os.occupied_seats) / ts.total_seats :: dec, 2) * 100 as "% соотношение к общему числу мест",
	-- для подсчета накопительного итога в оконной функции с разделением по аэропорту вылета и времени вылета, 
	--приведенному к дате, определяется количество занятых мест (=количеству пассажиров) 
	sum(os.occupied_seats) over (partition by (os.departure_airport, os.actual_departure::date)
order by os.actual_departure) as "Накопительно по пассажирам"
from occupied_seats_by_aircraft os
join total_seats_by_aircraft ts on ts.aircraft_code = os.aircraft_code;

--6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
--В таблице Самолеты группирую записи по типу самолета, объединяю с таблицей Рейсы, в подзапросе к таблице Рейсы определяю общее количество рейсов
select 
	a.model as "Модель самолета",
	count(f.flight_id) as "Количество рейсов", 
	round (count(f.flight_id)/
	( select count (flight_id)
	from flights) :: dec * 100, 2) as "% от общего числа перелетов"
from aircrafts a
join flights f on f.aircraft_code = a.aircraft_code
group by a.model;

--7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
	
-- В СТЕ определяю для каждого рейса минимальную стоимость бизнес-класса и максимальную стоимость эконом-класса
with p1 as(
select  
			f.flight_id,
			case when tf.fare_conditions = 'Business' then min(tf.amount) end business_min_amount,
			case when tf.fare_conditions = 'Economy' then max(tf.amount) end economy_max_amount
from ticket_flights tf
join flights f on tf.flight_id = f.flight_id
group by f.flight_id, tf.fare_conditions
), 
-- В СТЕ объединяю для рейса в одну строку минимальную стоимость бизнес-класса и максимальную стоимость эконом-класса,
-- отфильтровываю рейсы, для которых стоимость бизнес-класса дешевле стоимости эконом-класса
p2 as (
select 
		p1.flight_id,
		min(p1.business_min_amount),
		max(p1.economy_max_amount)
from p1
group by p1.flight_id
having min(p1.business_min_amount) < max(p1.economy_max_amount)
)
select 	a.city as "Город прибытия"
from p2
join flights f on p2.flight_id = f.flight_id
--объединяю таблицу Рейсы с таблицей Аэропорты, чтобы определить город прилета
join airports a on f.arrival_airport = a.airport_code;

--8. Между какими городами нет прямых рейсов?
-- С помощью декартова произведения получаю уникальные комбинации городов
select a.city departure_city,  a2.city arrival_city
from airports a 
cross join airports a2 
where a.city <> a2.city 
-- Исключаю рейсы, для которых комбинация города вылета и города прилета отсутствует в декартовом произведении
except 
select a.city, a2.city 
from flights f 
join airports a on f.departure_airport = a.airport_code 
join airports a2 on f.arrival_airport = a2.airport_code

-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы
-- Определяю для рейса уникальные комбинации аэропорта вылета и аэропорта прилета
select distinct 
	a1.airport_name as "Аэропорт вылета",
	a2.airport_name as "Аэропорт прилета",
	-- Определяю по формуле из ТЗ расстояние между аэропортами, приводя к типу DECIMAL и округляя его до 2 знаков после запятой
	round((acos(sind(a1.latitude) * sind(a2.latitude) + cosd(a1.latitude) * cosd(a2.latitude) * cosd(a1.longitude - a2.longitude)) * 6371)::dec, 2) as "Расстояние",
	a."range" as "Дальность самолета",
	case when 
		-- Вычисляю по формуле из ТЗ расстояние между аэропортами
		acos(sind(a1.latitude) * sind(a2.latitude) + cosd(a1.latitude) * cosd(a2.latitude) * cosd(a1.longitude - a2.longitude)) * 6371 
		-- Сравниваю с дальностью самолета
		>
		a."range" 
		then 'Не долетит'
		else 'Долетит'
		end as "Долетит ли самолет"
from flights f
join airports a1 on f.departure_airport = a1.airport_code
join airports a2 on f.arrival_airport = a2.airport_code
join aircrafts a on f.aircraft_code = a.aircraft_code 

