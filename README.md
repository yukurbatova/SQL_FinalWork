# Приложение 1

### 1. В работе использовался локальный тип подключения. 
### 2. ER - диаграмма БД:

![fish](https://user-images.githubusercontent.com/72889535/151113231-b3978797-3a08-4ba5-b9e8-46d873ef2ccf.jpg)
### 3. Краткое описание БД.
БД demo состоит из 8 таблиц:
- Bookings
- Tickets
- Ticket_flights
- Boarding_passes
- Flights
- Airports
- Aircrafts
- Seats

БД demo содержит 2 представления:
- Flights_v
- Routes

### 3. Развернутый анализ БД.
- Таблица Bookings - Бронирования состоит из следющих полей:

book_ref - номер бронирования, комбинация 6 букв и цифр;  
book_date - дата бронирования, максимум за месяц до рейса;  
total_amount - полная сумма бронирования, хранит общую стоимость включенных в бронирование перелетов всех пассажиров.  

Индексы:  
 PRIMARY KEY, btree (book_ref)  
Ссылки извне:  
 TABLE "tickets" FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)  

- Таблица Tickets - Билеты состоит из следющих полей:

ticket_no - номер билета, 13 цифр;  
book_ref - номер бронирования;  
passenger_id - идентификатор пассажира;  
passenger_name - фамилия и имя пассажира;  
contact_data - контактнае данные пассажира.  

Индексы:  
 PRIMARY KEY, btree (ticket_no)  
Ограничения внешнего ключа:  
 FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)  
Ссылки извне:  
 TABLE "ticket_flights" FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no)  
 
 - Таблица Ticket_flight - Связь билета с рейсом состоит из следющих полей:

ticket_no - номер билета;  
flight_id - идентификатор рейса;  
fare_conditions - класс обслуживания;  
amount - стоимость перелета.  

Индексы:
 PRIMARY KEY, btree (ticket_no, flight_id)  
Ограничения-проверки:  
 CHECK (amount >= 0)  
 CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))  
Ограничения внешнего ключа:  
 FOREIGN KEY (flight_id) REFERENCES flights(flight_id)  
 FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no)  
Ссылки извне:  
 TABLE "boarding_passes" FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)
 
  - Таблица Boarding_passes - Посадочные талоны состоит из следющих полей:

ticket_no - номер билета;  
flight_id - идентификатор рейса;  
boarding_no - номер посадочного талона;  
seat_no - номер места.  
Индексы:  
 PRIMARY KEY, btree (ticket_no, flight_id)  
 UNIQUE CONSTRAINT, btree (flight_id, boarding_no)  
 UNIQUE CONSTRAINT, btree (flight_id, seat_no)  
Ограничения внешнего ключа:  
 FOREIGN KEY (ticket_no, flight_id)  
 REFERENCES ticket_flights(ticket_no, flight_id)  
 
 - Таблица Flights - Рейсы состоит из следющих полей:
 
flight_id - идентификатор рейса;  
flight_no - номер рейса;  
scheduled_departure - время вылета по расписанию;  
scheduled_arrival - время прилета по расписанию;  
departure_airport - аэропорт вылета;  
arrival_airport - аэропорт прилета;  
status - статус рейса;  
aircraft_code - код самолета;  
actual_departure - фактическое время вылета;  
actual_arrival - фактическое время прилета.  
Индексы:  
 PRIMARY KEY, btree (flight_id)  
 UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)  
Ограничения-проверки:  
 CHECK (scheduled_arrival > scheduled_departure)  
 CHECK ((actual_arrival IS NULL)  
 OR ((actual_departure IS NOT NULL AND actual_arrival IS NOT NULL)  
 AND (actual_arrival > actual_departure)))  
 CHECK (status IN ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduled', 'Cancelled'))  
Ограничения внешнего ключа:  
 FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code)  
 FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code)  
 FOREIGN KEY (departure_airport) REFERENCES airports(airport_code)  
Ссылки извне:  
 TABLE "ticket_flights" FOREIGN KEY (flight_id) REFERENCES flights(flight_id)  

 - Таблица Airports - Аэропорты состоит из следющих полей:

airport_code - код аэропорта, 3 буквы;  
airport_name - название аэропорта;  
city - город аэропорта;  
longitude - координаты аэропорта: долгота;  
latitude - координаты аэропорта: широта;  
timezone - временная зона аэропорта.  
Индексы:  
 PRIMARY KEY, btree (airport_code)  
Ссылки извне:  
 TABLE "flights" FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code)  
 TABLE "flights" FOREIGN KEY (departure_airport) REFERENCES airports(airport_code)  
 
  - Таблица Aircrafts - Самолеты состоит из следющих полей:

aircraft_code - код самолета;  
model - модель самолета;  
range - максимальная дата самолета в км.  
Индексы:  
 PRIMARY KEY, btree (aircraft_code)  
Ограничения-проверки:  
 CHECK (range > 0)  
Ссылки извне:  
 TABLE "flights" FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code)  
 TABLE "seats" FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE
 
 - Таблица Seats - Места состоит из следющих полей:

aircraft_code - код самолета;  
seat_no - номер места;  
fare_conditions - класс обслуживания.  
Индексы:  
 PRIMARY KEY, btree (aircraft_code, seat_no)  
Ограничения-проверки:  
 CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))  
Ограничения внешнего ключа:  
 FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE  
 
 ### Бизнес задачи, которые можно решить, используя БД.
 1. Получать рейсы с задержкой вылета для анализа причин.
 2. 
 
