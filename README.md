# Proyecto M2 - Generación de Datos Sintéticos con Python y PostgreSQL

En el primer avance se generan más de **500.000 registros simulados** para poblar una base de datos PostgreSQL y simular la base de datos de la empresa de transporte FleetLogix.

FleetLogix es una empresa de transporte y logística que opera una flota de 200 vehículos realizando entregas de última milla en 5 ciudades principales. La empresa ha estado operando con sistemas legacy y hojas de cálculo, pero necesita modernizar su infraestructura de datos para competir en el mercado actual.

De sus sistemas podemos sacar las siguientes tablas:

- Vehículos  
- Conductores  
- Rutas  
- Viajes   
- Entregas   
- Mantenimientos  

El objetivo del primer avance es crear un dataset, coherente e integrado que permita realizar pruebas, análisis o construir dashboards.

## Herramientas Utilizadas

- **Python 3.9+**
- **PostgreSQL 13+**
- Librerías de Python:
  - psycopg2
  - Faker
  - NumPy
  - pandas
  - tqdm
  - logging
  - json
  - DateTime

## Instalación del Motor PostgreSQL

### 1. Descargar PostgreSQL  
Ir a la página oficial:  
- https://www.enterprisedb.com/downloads/postgres-postgresql-downloads

Seleccionar tu sistema operativo e instalar:

- PostgreSQL Version 17.7  

Durante la instalación:

- Define una contraseña para el usuario `postgres`
- Deja por defecto el puerto **5432**

### 2. Crear la base de datos

- Abre Dbeaver y genera una nueva conexion con Ctrl + Shift + N
- Configura la conexion con PostgresSQL 
- La configuracion se ve asi:
![alt text](Pictures\image-1.png)
- Deja la configuracion de host igual
- Coloca tu contraseña y listo
- Crea un nuevo script SQL y ejecuta:
```sql
CREATE DATABASE fleetlogix_database;
```

### 3. Creacion de esquemas y tablas

```sql
-- Esquema Person (Personas)
CREATE SCHEMA Persons AUTHORIZATION pg_database_owner;
-- Esquema Resources (Recursos)
CREATE SCHEMA Resources AUTHORIZATION pg_database_owner;
```
- Las tablas se dividen asi:
- *persons*
  - drivers
- *resources*
  - vehicles
  - routes
  - trips
  - deliveries
  - maintenance

![alt text](Pictures\Diagrama_ER_Profesional.png)

### 4. Instalar dependencias
```bash
pip install -r requirements.txt
```

### 5. Configuracion logging en data_generation.py

- Para empezar la generacion de los datos
```python
DB_CONFIG = {
    'host': 'localhost',
    'database': 'fleetlogix_database',
    'user': 'postgres',
    'password': 'password', # Aqui colocas tu contraseña
    'port': 5432 
}
```

### 6. Ejecutar codigo

```bash
python data_generation.py
```
- Se espera que se creen los siguientes archivos
``data_generation.log`` 
``generation_summary.json`` 

