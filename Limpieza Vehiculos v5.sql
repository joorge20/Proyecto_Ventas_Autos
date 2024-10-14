-- Validar estructura de la Tabla.
exec sp_help car_prices;

/* 
Mi intencion es crear otra tabla separada con un catalogo de todos los modelos de Auto, por lo que creare una nueva Columna
como ID del Vehiculo para la nueva tabla. Lo creare dentro de esta tabla de Ventas para posterior poder conectarlas.
Creare la llave usando:
	- 2 ultimos digitos del Año
	- 3 primeros caracteres de las columnas Make, Modelo, Trim, Body y Transmision, y en caso de que tenga valores NULL, le dejare la palabra

Estos valores NULL se trabajaran mas tarde.
*/
Select *, 
RIGHT(YEAR,2)+LEFT(make,3)+COALESCE(LEFT(MODEL,3),'NULL')+COALESCE(LEFT(TRIM,3),'NULL')+COALESCE(LEFT(BODY,3),'NULL')+
COALESCE(LEFT(Transmission,3),'NULL') 
from car_prices;

Alter Table CAR_PRICES add ID_VEHICULO NVARCHAR(20);

UPDATE car_prices set ID_VEHICULO =  RIGHT(YEAR,2)+LEFT(MAKE,3)+COALESCE(LEFT(MODEL,3),'NULL')+COALESCE(LEFT(TRIM,3),'NULL')+COALESCE(LEFT(BODY,3),'NULL')+COALESCE(LEFT(Transmission,3),'NULL')

/*
Se crea y se pobla la nueva tabla que servira como Catalogo de Autos.
Se cambiaran algunos nombres de columnas
*/
/*
Select * from car_prices;
Create Table Vehiculos (year int, Brand NVARCHAR(50), MODEL NVARCHAR(50), v_desc NVARCHAR(50), V_type NVARCHAR(50), transmission NVARCHAR(50), id_vehiculo nvarchar(20));

INSERT INTO Vehiculos
select year, make, model, trim, body, transmission, id_vehiculo from car_prices;
*/

/*Limpieza de Columnas*/
-- Columna Year
select distinct year, count(*) from Vehiculos
group by year;

-- Columna Brand
select * from Vehiculos;

select distinct Brand, count(*) from Vehiculos
group by brand
order by 1;

/*
Se identifican los nombres que se pueden agrupar y se actualizan con un Update Sencillo

Update vehiculos set brand = 'Chevrolet' where brand = 'chev truck';
Update vehiculos set brand = 'Dodge' where brand = 'dodge tk';
Update vehiculos set brand = 'Ford' where brand in ('ford tk','ford truck');
Update vehiculos set brand = 'GMC' where brand = 'gmc truck';
Update vehiculos set brand = 'Hyundai' where brand = 'hyundai tk';
Update vehiculos set brand = 'Land Rover' where brand = 'landrover';
Update vehiculos set brand = 'Mazda' where brand = 'mazda tk';
Update vehiculos set brand = 'Mercedes-Benz' where brand in ('mercedes','mercedes-b');
Update vehiculos set brand = 'Volkswagen' where brand = 'vw';
*/
--Buscar Marcas Vacias que no tengan informacion de modelo, descripciom o tipo.
Select brand, model, v_desc, V_type, count(*) from vehiculos where brand is null
group by brand, model, v_desc, V_type;

-- Se eliminan
--delete from  vehiculos where brand is null;

-- Columna Modelo
select * from Vehiculos;

select distinct model, count(*) from Vehiculos
group by model
order by 1;
-- Validar las descripciones de los Modelos Vacios
Select distinct v_desc from vehiculos where model is null;

Select * from vehiculos where v_desc = '750Li xDrive'
order by 1 desc;

/*
Se actualizan Manualmente
*/
Update Vehiculos set model = '7 Series' where v_desc = '750i' and model is null
Update Vehiculos set model = '6 Series Gran Coupe' where v_desc = '650i xDrive' and model is null
Update Vehiculos set model = '7 Series' where v_desc = '750i xDrive' and model is null
Update Vehiculos set model = '7 Series' where v_desc = '750Li xDrive' and model is null
Update Vehiculos set model = '7 Series' where v_desc = '750Li' and model is null
Update Vehiculos set model = 'A3' where v_desc = '2.0 TFSI Premium quattro' and model is null;

-- Columna V_desc
select * from Vehiculos;

select distinct v_desc, count(*) from Vehiculos
group by v_desc
order by 1;

Select distinct model from vehiculos where v_desc is null;

Select * from vehiculos where model = 'durango'



-- Columna Tipo
select * from Vehiculos;

select distinct V_type, count(*) from Vehiculos
group by V_type
order by 1;

Select distinct model from vehiculos where v_type is null;

Select * from vehiculos where model in (Select distinct model from vehiculos where v_type is null)

Select * from vehiculos where model in ('Durango')
and  v_type is null;

-- Para cuando los Valores NULL son el ultimo Numero
WITH CONTEO AS (
Select brand, model,v_type, count(*) as Cantidad
from vehiculos 
group by brand, model,v_type), -- Query para sacar la cantidad de autos que comparten marca, modelo y Type
RN AS(
Select brand, model,v_type, cantidad, ROW_NUMBER() OVER(PARTITION BY BRAND, MODEL ORDER BY cantidad desc) as orden 
from conteo
), -- Query para asignar un orden en base a la cantidad de Autos que hay, el que tenga mas cantidad es el primero de la lista, agrupados por Marca, y modelo
RN_2 as
(
Select brand, model,v_type, cantidad, orden, ROW_NUMBER() OVER(PARTITION BY BRAND, MODEL ORDER BY cantidad) as ordenINv 
from RN) -- Query que asigna el mismo orden que el anterior pero a la inversa, es decir que la columna que menos cantidad sea tenga el numero 1, es decir que los que tengan valores NULL pasen a tener un Orden de 1, y asi poder igualarlos con el Orden anterior y obtener los datos
Select * FROM RN_2 A INNER JOIN RN_2 b  ON
a.orden = b.ordenINv and a.model = b.model and a.brand = b.brand 
WHERE a.model = '1500'
A.v_type is not null
and b.v_type is null; -- Self Join que une el El numero de Orden Normal, con el el que tenga el mismo orden inverso, y que tengan igual modelo y marca

-- NULL EN sEGUNDA pOSICION
--Completar la Columna Body, en base a poner el tipo de Body que tenga mas cantidad
WITH CONTEO AS (
Select brand, model,v_type, count(*) as Cantidad
from vehiculos 
group by brand, model,v_type),
RN AS(
Select brand, model,v_type, cantidad, ROW_NUMBER() OVER(PARTITION BY BRAND, MODEL ORDER BY cantidad desc) as orden
from conteo
), RN_2 as
(
Select brand, model,v_type, cantidad,orden, ROW_NUMBER() OVER(PARTITION BY BRAND, MODEL ORDER BY cantidad) as ordenINv,
CASE 
	WHEN orden = 1 AND v_type IS NULL THEN 2
	WHEN ORDEN = 2 AND v_type IS NULL THEN 1
	END AS n_orden
from RN)
Select * FROM RN_2 A INNER JOIN RN_2 b  ON
a.model = b.model and a.brand = b.brand AND A.ORDEN = B.N_ORDEN -- and a.body = b.body

WHERE A.v_type is not null
and b.v_type is null;

-- Columna Transmission
select * from Vehiculos;

select distinct transmission, count(*) from Vehiculos
group by transmission
order by 1;

Select distinct model from vehiculos where transmission is null;

Select * from vehiculos where model = 'swift'

Select transmission, count(*) from vehiculos where model = 'Tiburon'
group by transmission

Select * from vehiculos where model in (Select distinct model from vehiculos where TRANSMISSION is null)

Select * from vehiculos where model in ('Durango')
and  v_type is null;

-- Para cuando los Valores NULL son el ultimo Numero
WITH CONTEO AS (
Select brand, model,transmission, count(*) as Cantidad
from vehiculos 
group by brand, model,transmission), -- Query para sacar la cantidad de autos que comparten marca, modelo y Type
RN AS(
Select brand, model,transmission, cantidad, ROW_NUMBER() OVER(PARTITION BY BRAND, MODEL ORDER BY cantidad desc) as orden 
from conteo
), -- Query para asignar un orden en base a la cantidad de Autos que hay, el que tenga mas cantidad es el primero de la lista, agrupados por Marca, y modelo
RN_2 as
(
Select brand, model,transmission, cantidad, orden, ROW_NUMBER() OVER(PARTITION BY BRAND, MODEL ORDER BY cantidad) as ordenINv 
from RN) -- Query que asigna el mismo orden que el anterior pero a la inversa, es decir que la columna que menos cantidad sea tenga el numero 1, es decir que los que tengan valores NULL pasen a tener un Orden de 1, y asi poder igualarlos con el Orden anterior y obtener los datos
Select * FROM RN_2 A INNER JOIN RN_2 b  ON
a.orden = b.ordenINv and a.model = b.model and a.brand = b.brand 
WHERE a.transmission is not null
and b.transmission is null; -- Self Join que une el El numero de Orden Normal, con el el que tenga el mismo orden inverso, y que tengan igual modelo y marca

-- Cuando el NULL no es el ultimo Valor.
--Completar la Columna Body, en base a poner el tipo de Body que tenga mas cantidad
WITH CONTEO AS (
Select brand, model,transmission, count(*) as Cantidad
from vehiculos 
group by brand, model,transmission),
RN AS(
Select brand, model,transmission, cantidad, ROW_NUMBER() OVER(PARTITION BY BRAND, MODEL ORDER BY cantidad desc) as orden
from conteo
), RN_2 as
(
Select brand, model,transmission, cantidad,orden, ROW_NUMBER() OVER(PARTITION BY BRAND, MODEL ORDER BY cantidad) as ordenINv,
CASE 
	WHEN orden = 1 AND TRANSMISSION IS NULL THEN 2
	WHEN ORDEN = 2 AND transmission IS NULL THEN 1
	END AS n_orden
from RN)
Select * FROM RN_2 A INNER JOIN RN_2 b  ON
a.model = b.model and a.brand = b.brand AND A.ORDEN = B.N_ORDEN -- and a.body = b.body
WHERE A.transmission is not null
and b.transmission is null;

--Vehiculos con Transmision Sedan
select * from Vehiculos
 where transmission = 'Sedan';
 Select TRANSMISSION, COUNT(*) from vehiculos where model = 'Jetta' and V_desc like '%SE PZEV%' GROUP BY TRANSMISSION;

 Update Vehiculos set transmission = 'Automatic'
 where transmission = 'Sedan';

-- Quitar Duplicados

WITH Duplicados as(
Select *, ROW_NUMBER() over(partition by id_vehiculo2 order by year) as rn from vehiculos)
--Select * from Duplicados
delete from Duplicados where rn > 1;

--Agregar Columna de ID Auto con Datos Correctos
Select *, 
RIGHT(YEAR,2)+LEFT(brand,3)+COALESCE(LEFT(MODEL,3),'NULL')+COALESCE(LEFT(v_desc,3),'NULL')+COALESCE(LEFT(v_type,3),'NULL')+
COALESCE(LEFT(Transmission,3),'NULL') 
from vehiculos;

Alter Table vehiculos add ID_VEHICULO2 NVARCHAR(20);

UPDATE vehiculos set ID_VEHICULO2 =RIGHT(YEAR,2)+LEFT(brand,3)+COALESCE(LEFT(MODEL,3),'NULL')+COALESCE(LEFT(v_desc,3),'NULL')+COALESCE(LEFT(v_type,3),'NULL')+
COALESCE(LEFT(Transmission,3),'NULL') 

 /*tabla ventas*/

 Select * from car_prices;

 -- Quitar columnas de los Autos.

 Alter table car_prices drop column make, model, trim,body, transmission;

-- Relacion Tablas.
Select COUNT(*) from car_prices
 where id_vehiculo IS NULL;

 DELETE from car_prices
 where id_vehiculo IS NULL;

-- Actualizar ID vEHICULO en la TABLA de ventas
Select *from car_prices A inner join Vehiculos B
on a.ID_VEHICULO = b.id_vehiculo
--WHERE B.id_vehiculo IS NULL;

UPDATE a set a.id_vehiculo = b.id_vehiculo2 from car_prices a inner join vehiculos b on a.ID_VEHICULO = b.id_vehiculo;

Select * from car_prices where ID_VEHICULO in ('12LinNavBasSUVNULL','12LinNavBasSUVaut');
Select count(distinct id_vehiculo2) from vehiculos where id_vehiculo = '14BMW6 S650SedNULL'


-- Quitar columna ID_vehiculo y renombrar id_vehiculo2

Alter table vehiculos drop column id_vehiculo

-- Limpieza tabla Car_prices
Select * from car_prices;

Select distinct state, count(*) from car_prices
group by state
order by 1;

-- Sacar los valores raros de la Columna State, al parecer esta recorrida la informacion
With largo as (
Select *, len(state) as longitud from car_prices)
Select * from largo a inner join largo b on a.state = b.state where a.longitud>2;
--UPDATE A SET A.STATE = NULL, A.VIN = B.STATE, A.CONDITION = B.ODOMETER, A.ODOMETER = B.COLOR, A.COLOR = B.INTERIOR, A.SELLER = NULL FROM LARGO A INNER JOIN LARGO B ON A.STATE = B.STATE
--WHERE A.longitud >2;
-- Update para corregir

-- Columna Condicion
SELECT * FROM CAR_PRICES;

Select distinct condition, count(*) from car_prices
group by condition
order by 1;

SELECT * FROM CAR_PRICES where condition is null;

-- Columna Color
SELECT * FROM CAR_PRICES;

Select distinct Color, count(*) from car_prices
group by Color

SELECT * FROM CAR_PRICES where color = '—'
UPDATE car_prices SET COLOR = 'NA' WHERE  (color IN ('—',NULL) OR COLOR IS NULL)

-- Columna INterior
SELECT * FROM CAR_PRICES;

Select distinct interior, count(*) from car_prices
group by interior
order by 1;

UPDATE car_prices SET interior = 'NA' WHERE  (interior IN ('—',NULL) OR interior IS NULL)

-- COlumna Seller
SELECT * FROM CAR_PRICES;

Select distinct seller, count(*) from car_prices
group by seller
order by 1;
UPDATE car_prices SET SELLER = 'NA' WHERE  (SELLER IN ('—',NULL) OR SELLER IS NULL)

-- Columna Fecha
SELECT *, TRY_CAST(SALEDATE AS DATE) FROM CAR_PRICES
WHERE YEAR = 2015;

UPDATE car_prices SET SALEDATE = TRIM(SUBSTRING(saledate,2,LEN(SALEDATE)));

UPDATE car_prices SET SALEDATE = TRY_CAST(SALEDATE AS DATE)

sELECT * FROM car_prices