-- Query 1: Contar vehículos por tipo 
-- Resultado esperado: Lista simple con tipos de vehículo y cantidades.
select
	v.vehicle_type as Tipo_Vehiculo,
	count(v.vehicle_id) as Cantidad_Vehiculos
from resources.vehicles v
group by v.vehicle_type;

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

-- Query 3: Total de viajes por estado 
-- Resultado esperado: Conteo simple por estado (in_progress, completed)
select 
	r.destination_city as Ciudad_Viaje,
	count(t.trip_id) as Viajes,
	t.status as Estado 
from resources.trips t 
join resources.routes r on r.route_id = t.route_id 
group by r.destination_city, t.status;

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
