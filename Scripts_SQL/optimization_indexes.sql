-- =====================================================
-- FLEETLOGIX - ÍNDICES DE OPTIMIZACIÓN
-- Basados en las 12 queries analizadas
-- Objetivo: Mejorar performance en 20%+
-- Juan
-- =====================================================

-- Análisis de performance ANTES de crear índices
-- Ejecutar cada query con EXPLAIN ANALYZE y guardar tiempos

-- =====================================================
-- ÍNDICE 1: Optimización para JOINs frecuentes en trips
-- =====================================================
-- Justificación: Las queries 4-12 hacen JOIN intensivo entre trips y otras tablas
-- Queries beneficiadas: 4, 5, 6, 7, 9, 10, 11
create index idx_trips_composite_joins on resources.trips(vehicle_id, driver_id, route_id, departure_datetime)
where status = 'completed';

-- =====================================================
-- ÍNDICE 2: Optimización para análisis temporal de deliveries
-- =====================================================
-- Justificación: Queries 8, 12 filtran y agrupan por scheduled_datetime
-- Queries beneficiadas: 4, 8, 12
create index idx_deliveries_scheduled_datetime on resources.deliveries(scheduled_datetime, delivery_status)
where delivery_status = 'delivered';

-- =====================================================
-- ÍNDICE 3: Optimización para mantenimiento por vehículo
-- =====================================================
-- Justificación: Query 9 necesita acceso rápido a mantenimientos por vehículo
-- Queries beneficiadas: 9
create index idx_maintenance_vehicle_cost on resources.maintenance(vehicle_id, cost);

-- =====================================================
-- ÍNDICE 4: Optimización para análisis de conductores
-- =====================================================
-- Justificación: Queries 5, 6, 10 filtran por conductores activos
-- Queries beneficiadas: 2, 5, 6, 10
create index idx_drivers_status_license on persons.drivers(status, license_expiry)
where status = 'active';

-- =====================================================
-- ÍNDICE 5: Optimización para métricas de rutas
-- =====================================================
-- Justificación: Query 7 calcula consumo por ruta
-- Queries beneficiadas: 4, 7, 9, 1
create index idx_routes_metrics on resources.routes(route_id, distance_km, destination_city);

-- =====================================================
-- COMANDOS PARA VERIFICAR ÍNDICES CREADOS
-- =====================================================
select 
    schemaname,
    tablename,
    indexname,
    indexdef
from pg_indexes
where schemaname = 'persons'
    and indexname like 'idx_%'
order by tablename, indexname;

select 
    schemaname,
    tablename,
    indexname,
    indexdef
from pg_indexes
where schemaname = 'resources'
    and indexname like 'idx_%'
order by tablename, indexname;

-- =====================================================
-- MANTENIMIENTO DE ÍNDICES
-- =====================================================
analyze resources.vehicles;
analyze persons.drivers;
analyze resources.routes;
analyze resources.trips;
analyze resources.deliveries;
analyze resources.maintenance;