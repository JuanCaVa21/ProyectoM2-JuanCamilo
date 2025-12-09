## Avance #2
### Creación de Querys:

La consigna principal es crear 8 Querys usando el motor de PostgreSQL. Se crearon 12 Querys de las cuales 3 son básicas, 5 son intermedias y 4 son difíciles. Además, luego de hacer la consulta y obtener el resultado se aplicó la función 
```sql
EXPLAIN ANALYZE
```
## Query 1
La primer Query busca contar cuantos vehiculos hay por cada tipo de vehiculo
```sql
-- Query 1: Contar vehículos por tipo 
-- Resultado esperado: Lista simple con tipos de vehículo y cantidades.
select
	v.vehicle_type as Tipo_Vehiculo,
	count(v.vehicle_id) as Cantidad_Vehiculos
from resources.vehicles v
group by v.vehicle_type;
```
#### Resultado: 
![alt text](Pictures\Resultado_Query_1.png)
#### Exucution Time Explain Analyze 
* Sin index: 0,286 ms
* Con index: 11,560 ms

## Query 2
La segunda Query busca reconocer los conductores que su licencia esta proxima a vencer, esto quiere decir que se vence en los proximos 30 dias. Esta consulta puede servir como una view para poder recordarle a los conductores que deben renovar su licencia antes de su fecha de vencimiento
```sql
-- Query 2: Conductores con licencia próxima a vencer 
-- Resultado esperado: Lista de conductores que deben renovar licencia en 30 días.
select
	d.driver_id, 
	concat(d.first_name, ' ', d.last_name) as Nombre,
	d.license_expiry,
	d.status 
from persons.drivers d 
where (d.license_expiry between current_timestamp and (current_timestamp + '30 days')) and d.status = 'active'
order by d.license_expiry;
```
#### Resultado:
![alt text](Pictures\Resultado_Query_2.png)
#### Exucution Time Explain Analyze 
* Sin index: 0,257 ms
* Con index: 0,133 ms

## Query 3
La tercer Query busca ver cuales son las ciudades que mas viajes realizan lo que podemos observar que la ciudad con mas viajes realizados es Bogota pero igual la empresa tiene una media de viajes realizados bastante pareja
```sql
-- Query 3: Total de viajes por estado 
-- Resultado esperado: Conteo simple por estado (in_progress, completed).
select 
	r.destination_city as Ciudad_Viaje,
	count(t.trip_id) as Viajes,
	t.status as Estado 
from resources.trips t 
join resources.routes r on r.route_id = t.route_id 
group by r.destination_city, t.status;
```
#### Resultado:
![alt text](Pictures\Resultado_Query_3.png)
#### Exucution Time Explain Analyze
* Sin index: 40,827 ms
* Con index: 43,775 ms

## Query 4
Esta busca saber el total de entregas en el periodo de los ultimos 60 dias, uan metrica bastante interesante y util. Nos puede servir para conocer la productividad como un factor de entregas por mes aqui use la funcion ```trim``` la cual elimina los espacios en blanco (o caracteres especificados) del principio, del final o de ambos lados de una cadena de texto entonces antes de la coma se eliminan los valores y por eso nos queda solo la ciudad, esto se hizo con el fin de no tener que usar Joins con las demas tablas
```sql
-- Query 4: Total de entregas por ciudad (últimos 2 meses, 60 días) 
-- Resultado esperado: Ranking de ciudades con volumen de entregas y peso total.
select
	count(d.delivery_id) as Viajes,
	trim(split_part(d.delivery_address, ',', -1)) as Ciudad,
	sum(d.package_weight_kg) as Total_KG 
from resources.deliveries d 
where d.delivered_datetime >= current_timestamp - interval '60 days' 
group by ciudad  
order by viajes desc;

```
#### Resultado:
![alt text](Pictures\Resultado_Query_4.png)
#### Exucution Time Explain Analyze
* Sin index: 136,532 ms
* Con index: 145,225 ms

## Query 5
Esta Query nos sirve para algo importante y es conocer los conductores activos y la cantidad de viajes que realizan. Conoces tambien algo importante y esque tenemos 370 Conductores Activos que realicen viajes, solo puse 10 en la imagen ya que no cabian los 370 en un screenshot 👌
```sql
-- Query 5: Conductores activos y carga de trabajo 
-- Resultado esperado: Lista con total de viajes por conductor activo.
select 
	concat(d.first_name, ' ', d.last_name) as Nombre,
	count(t.route_id) as Viajes
from persons.drivers d 
join resources.trips t
	on d.driver_id = t.driver_id 
where d.status = 'active'
group by Nombre
order by Viajes desc;
```
#### Resultado:
![alt text](Pictures\Resultado_Query_5.png)
#### Exucution Time Explain Analyze
* Sin index: 65,450 ms
* Con index: 51,240 ms

## Query 6
A partir de esta query se ponen nivel avanzado las demas, igual esta logica la usaremos mas adelante como metrica. Para una empresa como fleetlogix es importante saber cuatas entregas en promedio hace cada conductor para asi saber si estan siendo eficientes o no y asi mismo tomar medidas, ocurre lo mismo de la query pasada al ser 370 Conductores diferentes no me caben en un screenshoot. Por cierto utilice un intervalo entre el **current_timestamp** y los proximos **6 months** para que asi se actualice cada dia la consulta 
```sql
-- Query 6: Promedio de entregas por conductor (6 meses) 
-- Resultado esperado: Métricas de productividad por conductor. 
select 
	concat(t3.first_name, ' ', t3.last_name) as Nombre,
	round(avg(t1.delivery_id), 0) as Promedio_Entregas,
	sum(t2.total_weight_kg) as Total_KG,
	sum(t2.fuel_consumed_liters) as Consumo 
from resources.deliveries t1 
join resources.trips t2 
	on t1.trip_id = t2.trip_id 
join persons.drivers t3
	on t2.driver_id = t3.driver_id 
where t1.delivered_datetime >= current_timestamp - interval '6 months' 
group by nombre 
order by promedio_entregas desc;
```
#### Resultado:
![alt text](Pictures\Resultado_Query_6.png)
#### Exucution Time Explain Analyze
* Sin index: 165,516 ms
* Con index: 153,575 ms

## Query 7
Otra de las metricas de las que usaremos la logica mas adelante en las Querys Avanzadas o dificiles. Aqui para calcular el consumo en 100Km use una logica sencilla cogi el total de litros consumidos y los dividi por la cantidad de km recorridos y asi tengo la cantidad de litros que se consumen por Km luego simplemente lo multiplique por 100 y listo. Una logica sencilla y funcional
```sql
-- Query 7: Rutas con mayor consumo de combustible 
-- Resultado esperado: Top 10 rutas con mayor consumo litros/100km.
select
	r.route_code,
	r.origin_city,
	r.destination_city,
	round(sum(r.distance_km), 0) as Total_Km,
	round(sum(t.fuel_consumed_liters), 0) as Consumo,
	round((sum(t.fuel_consumed_liters)/sum(r.distance_km))*100, 2) as Consumo_en_100Km
from resources.routes r
join resources.trips t 
	on r.route_id = t.route_id
group by r.route_code, r.origin_city, r.destination_city   
order by consumo_en_100km desc
limit 10;
```
#### Resultado:
![alt text](Pictures\Resultado_Query_7.png)
#### Exucution Time Explain Analyze
* Sin index: 79,506 ms
* Con index: 66,824 ms

## Query 8
En esta Query es una metrica importante ya que si la aplicamos a los drivers podemos darnos cuenta del porcentaje de retrasos de cada conductor y podr dia de la semana es interesante saberlo, asi nos podemos dar cuenta de que dias es mas probable que una entrega se retrase por diferentes factores lo que notamos esque el porcentaje mas alto son los miercoles y tiene cierto sentido, normalmente son de los dias con mas trafico en las grandes ciudades. Aqui utlizamos CTEs para realizar la query y usamos una funcion increible que es ```::numeric``` para convertir un numero de un tipo a otro tipo. Ademas, la ecuacion del promedio que usamos es: $\text{promedio} = \frac{\sum x_i}{n}$

```sql
-- Query 8: Análisis de retrasos por día de semana 
-- Resultado esperado: Porcentaje de retrasos por cada día de la semana. 
with retrasos as(
	select
		d.delivery_id, 
		d.delivered_datetime,
		d.scheduled_datetime,
		case
			when d.delivered_datetime > d.scheduled_datetime + interval '2 hours' then 1 else 0
		end as Retraso
	from resources.deliveries d 
	where d.delivery_status = 'delivered' 
)
select 
	to_char(r.scheduled_datetime, 'DAY') as Dia_Semana,
	sum(r.retraso) as Total_Retraso,
	count(r.delivery_id) as Total_Entregado,
	round((sum(r.retraso)::numeric) / count(r.delivery_id) * 100, 2) as porcentaje_retraso
from retrasos r
group by dia_semana; 
```
#### Resultado:
![alt text](Pictures\Resultado_Query_8.png)
#### Exucution Time Explain Analyze
* Sin index: 284,902 ms
* Con index: 213,004 ms

## Query 9
Mediante el uso de CTEs se creo otra metrica para poder hacer un buen analisis de costos de mantenimiento. Algo bastante importante en una empresa en crecimiento. Lo que vemos que es algo bastante logico esque el costo de revision de motor es mucho mas alto ya que normalmente son los mas complicados y delicados. Aqui la maquina se demoro masomenos 4 segundos en ejecutar la consulta, ojala que con el indec se demore menos 🤞
```sql
-- Query 9: Costo de mantenimiento por kilómetro 
-- Resultado esperado: Costo por km para cada tipo de vehículo usando CTEs.

with costos_mantenimiento as(
	select
		t3.maintenance_type, 
		count(t3.maintenance_id) as Cantidad_Mantenimientos, 
		sum(t1.distance_km) as Total_Viajado,
		sum(t1.estimated_duration_hours) as Tiempo_Viajado,
		sum(t1.toll_cost) as Costo_Viaje,
		sum(t3."cost") as Costo_Mantenimiento
	from resources.routes t1
	join resources.trips t2 
		on t1.route_id = t2.route_id
	join resources.maintenance t3 
		on t2.vehicle_id = t3.vehicle_id
	group by maintenance_type
)
select 
	maintenance_type as Tipo_Mantenimiento,
	round(costo_mantenimiento / total_viajado * 100, 2) as Costo_por_KM
from costos_mantenimiento;
```
#### Resultado:
![alt text](Pictures\Resultado_Query_9.png)
#### Exucution Time Explain Analyze
* Sin index: 4520,274 ms
* Con index: 2651,834 ms

## Query 10
Esta es en mi opinion la consulta mas larga ya que me piden usar diferentes metricas para medir la eficiencia las que escogi fueron consumo_por_km, entregas_por_semana y tiempo_retraso. Naturalmente mientras consumo_por_km sea mas bajo sera mucho mejor y mientras entregas_por_semana sea mas alto sera mucho mejor. Lo que se hizo fue mediante la funcion rank determinar esto, en el order by se arregla eso. Luego sumo todas las metricas como para obtener un valor de productividad y lo organizo del mejor (osea el mayor) al peor y hago un limit 20 para solo obtener los primeros 20 conductores
```sql
-- Query 10: Ranking de conductores por eficiencia 
-- Resultado esperado: Top 20 conductores con ranking múltiple usando Window Functions (RANK).

with consumo_por_km as(
	select
		concat(d.first_name, ' ', d.last_name) as Nombre,
		sum(t.fuel_consumed_liters) as Total_Consumido,
		sum(r.distance_km) as Total_Km,
		round(sum(r.distance_km) / sum(t.fuel_consumed_liters), 2) as consumo_Km
	from persons.drivers d 
	join resources.trips t 
		on d.driver_id = t.driver_id
	join resources.routes r 
		on r.route_id = t.route_id 
	group by Nombre
	order by consumo_km asc
), entregas_por_semana as(
	select
		Nombre,
		round(avg(total_entregas), 2) as Promedio_Entregas
	from (
		select
			concat(t1.first_name, ' ', t1.last_name) as Nombre,
			count(t3.delivery_id) as Total_entregas,
			date_trunc('week', t3.delivered_datetime) as Semana
		from persons.drivers t1 
		join resources.trips t2 
			on t1.driver_id = t2.driver_id
		join resources.deliveries t3 
			on t2.trip_id = t3.trip_id
		where t3.delivery_status = 'delivered'
		group by Nombre, Semana
	) as Semanas
	group by Nombre
	order by promedio_entregas desc
), tiempo_retraso as(
	select 
		concat(t3.first_name, ' ', t3.last_name) as Nombre,
		avg(t1.delivered_datetime - (t1.scheduled_datetime + interval '2 hours')) as promedio_retraso
	from resources.deliveries t1 
	join resources.trips t2
		on t1.trip_id = t2.trip_id 
	join persons.drivers t3
		on t2.driver_id = t3.driver_id
	where t1.delivered_datetime is not null and t1.delivered_datetime > t1.scheduled_datetime + interval '2 hours'
	group by nombre
	order by promedio_retraso asc
)
select
	nombre,
	rank() over(order by consumo_km asc) as rank_Consumo,
	rank() over(order by promedio_entregas desc) as rank_Entregas,
	rank() over(order by promedio_retraso asc) as rank_Retraso,
	rank() over(order by consumo_km asc) + rank() over(order by promedio_entregas desc) + rank() over(order by promedio_retraso asc) as ranking_total
from consumo_por_km 
join entregas_por_semana using(nombre)
join tiempo_retraso using(nombre)
order by ranking_total asc
limit 20;
```
#### Resultado:
![alt text](Pictures\Resultado_Query_10.png)
#### Exucution Time Explain Analyze
* Sin index: 1895,638 ms
* Con index: 618,555 ms

## Query 11
Hacer un analisis de tendencias mensuales puede hacerse sobre la tabla que quieras realmente, para este caso yo utilice la tabla de **deliveries** ya que creo que es la que mas analisis mensuales se le deben hacer. la funcion ```nullif``` compara dos valores en caso de ser iguales crea un null como resultado, se uso para cuando se vaya a comparar con meses que no existen en la base de datos. Aqui la funcion lag se uso para recibir los datos del mes anterior y lead los del mes proximos luego se creo una nueva variable que es un porcentaje de variacion para ver que tal cambia en el tiempo.
```sql
-- Query 11: Análisis de tendencia mensual 
-- Resultado esperado: Tendencia mensual con comparaciones usando LAG/LEAD.
with retraso as (
	select
		date_trunc('month', d.delivered_datetime) as mes,  
    case
		when d.delivered_datetime > d.scheduled_datetime + interval '2 hours' then 1 else 0
    end as retraso
  from resources.deliveries d
  where d.delivery_status = 'delivered' and d.delivered_datetime is not null
), month_metrics as (
	select
		mes,
    	count(*) as total_entregas,
    	sum(retraso) as total_retrasos,
    	round(sum(retraso)::numeric / nullif(count(*), 0) * 100, 2) as Porcentaje_Retrasos
	from retraso
  	group by mes
  	order by mes
)
select
  	to_char(mes, 'YYYY-MM') as mes_name, 
  	total_entregas,
  	total_retrasos,
  	porcentaje_retrasos,
  	lag(total_retrasos) over (order by mes) as retrasos_mes_anterior,
  	lead(total_retrasos) over (order by mes) as retrasos_mes_siguiente,
	case
    	when lag(total_retrasos) over (order by mes) is null then null 
    	else round((total_retrasos - LAG(total_retrasos) over (order by mes))::numeric / nullif(lag(total_retrasos) over (order by mes), 0) * 100, 2)
	end as variacion_porcentajes_retrasos_vs_mes_anterior
from month_metrics
order by mes asc;
```
#### Resultado:
![alt text](Pictures\Resultado_Query_11.png)
#### Exucution Time Explain Analyze
* Sin index: 359,862 ms
* Con index: 212,949 ms