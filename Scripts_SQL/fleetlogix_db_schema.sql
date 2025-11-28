-- =====================================================
-- FLEETLOGIX DATABASE SETUP
-- Sistema de Gestión de Transporte y Logística
-- =====================================================

-- Creacion base de datos
create FLEETLOGIX_DATABASE;

-------- CREACION DE ESQUEMAS ---------

-- Esquema Person (Personas)
CREATE SCHEMA Persons AUTHORIZATION pg_database_owner;
-- Esquema Resources (Recursos)
CREATE SCHEMA Resources AUTHORIZATION pg_database_owner;

-------- CREACION DE TABLAS -----------

-- Tabla 1: vehicles (vehículos de la flota)
create table fleetlogix_database.resources.vehicles (
    vehicle_id serial primary key,
    license_plate varchar(20) unique not null,
    vehicle_type varchar(50) not null,
    capacity_kg decimal(10,2),
    fuel_type varchar(20),
    acquisition_date date,
    status varchar(20) default 'active'
);

-- Tabla 2: drivers (conductores)
create table fleetlogix_database.persons.drivers (
    driver_id serial primary key,
    employee_code varchar(20) unique not null,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    license_number varchar(50) unique not null,
    license_expiry date,
    phone varchar(20),
    hire_date date,
    status varchar(20) default 'active'
);

-- Tabla 3: routes (rutas predefinidas)
create table fleetlogix_database.resources.routes (
    route_id serial primary key,
    route_code varchar(20) unique not null,
    origin_city varchar(100) not null,
    destination_city varchar(100) not null,
    distance_km decimal(10,2),
    estimated_duration_hours decimal(5,2),
    toll_cost decimal(10,2) default 0
);

-- Tabla 4: trips (viajes realizados)
CREATE TABLE fleetlogix_database.resources.trips (
    trip_id serial primary key,
    vehicle_id integer, 
    driver_id integer, 
    route_id integer,
    departure_datetime timestamp not null,
    arrival_datetime timestamp,
    fuel_consumed_liters decimal(10,2),
    total_weight_kg decimal(10,2),
    status varchar(20) default 'in_progress'
);

-- Referencia fk_vehicle_id
alter table resources.trips
add constraint fk_vehicle_id
foreign key (vehicle_id) references resources.vehicles(vehicle_id);
-- Referencia fk_driver_id
alter table resources.trips
add constraint fk_driver_id
foreign key (driver_id) references persons.drivers(driver_id);
-- Referencia fk_route_id
alter table resources.trips
add constraint fk_route_id
foreign key (route_id) references resources.routes(route_id);

-- Tabla 5: deliveries (entregas individuales)
create table fleetlogix_database.resources.deliveries (
    delivery_id serial primary key,
    trip_id integer,
    tracking_number varchar(50) unique not null,
    customer_name varchar(200) not null,
    delivery_address text not null,
    package_weight_kg decimal(10,2),
    scheduled_datetime timestamp,
    delivered_datetime timestamp,
    delivery_status varchar(20) default 'pending',
    recipient_signature boolean default false
);

-- Referencia fk_trip_id
alter table resources.deliveries
add constraint fk_trip_id
foreign key (trip_id) references resources.trips(trip_id)

-- Tabla 6: maintenance (mantenimientos de vehículos)
create table fleetlogix_database.resources.maintenance (
    maintenance_id serial primary key,
    vehicle_id integer,
    maintenance_date date not null,
    maintenance_type varchar(50) not null,
    description text,
    cost decimal(10,2),
    next_maintenance_date date,
    performed_by varchar(200)
);

-- Referencia fk_vehicle_id_maintenance
alter table resources.maintenance 
add constraint fk_vehicle_id_maintenance
foreign key (vehicle_id) references resources.vehicles(vehicle_id)

--------- CREACION INDICES ----------

-- 2. Crear índices básicos proporcionados

-- Index idx_trips_departure
create index idx_trips_departure on resources.trips(departure_datetime);
-- Index idx_deleveries_status
create index idx_deliveries_status on resources.deliveries(delivery_status);
-- Index idx_vehicles_satatus
create index idx_vehicles_status ON resources.vehicles(status);

-- 3. Agregar comentarios a las tablas para documentación
comment on table resources.vehicles    is 'Registro de vehículos de la flota de FleetLogix';
comment on table persons.drivers 	   is 'Información de conductores empleados';
comment on table resources.routes 	   is 'Rutas predefinidas entre ciudades';
comment on table resources.trips 	   is 'Registro de viajes realizados';
comment on table resources.deliveries  is 'Entregas individuales asociadas a cada viaje';
comment on table resources.maintenance is 'Historial de mantenimiento de vehículos';

-- 4.1 Verificar la creación de las tablas (schema = 'resources')
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns 
     WHERE table_schema = 'resources' 
     AND table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'resources'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 4.2 Verificar la creación de las tablas (schema = 'persons') 
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns 
     WHERE table_schema = 'persons' 
     AND table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'persons'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 5. Verificar las relaciones (foreign keys)
select
    tc.table_name as tabla_origen,
    kcu.column_name as columna_origen,
    ccu.table_name as tabla_referencia,
    ccu.column_name as columna_referencia
from information_schema.table_constraints as tc
join information_schema.key_column_usage as kcu
    on tc.constraint_name = kcu.constraint_name
join information_schema.constraint_column_usage as ccu
    on ccu.constraint_name = tc.constraint_name
where tc.constraint_type = 'FOREIGN KEY';

-- 6. Verificar índices creados
select
    schemaname,
    tablename,
    indexname,
    indexdef
from pg_indexes
order by tablename, indexname;