# Приложение 1

### 1. В работе использовался локальный тип подключения. 
### 2. ER - диаграмма БД:

![fish](https://user-images.githubusercontent.com/72889535/151113231-b3978797-3a08-4ba5-b9e8-46d873ef2ccf.jpg)
### 3. Краткое описание БД.
БД demo состоит из 8 таблиц:
- Bookings
- Tickets
- Ticket_flight
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
