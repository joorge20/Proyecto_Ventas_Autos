# Proyecto_Ventas_Autos

# Resumen
Hola!
Este es proyecto es sobre un conjunto de datos que encontre en la Pagina de Kaggle, acerca de un Lote de autos en Estados Unidos, me parecio interesante ya que se puede trabajar la parte de limpieza de datos usando SQL y la Parte de visualizacion de la informacion utilizando Power BI

# Conjutno de Datos
Este Conjunto de Datos se obtiene desde la Pagina de Kaggle en el Siguient Link: [Vehicle Sales Data](https://www.kaggle.com/datasets/syedanwarafridi/vehicle-sales-data)

#  Descripcion de la Tabla
-  Year: Año de Manufactura
-  Make: Marca del Vehiculo
-  Model: Modelo Especifico del Vehiculo
-  Trim: Informacion Adicional del Modelo
-  Body: Tipo de Vehiculo
-  Transmision: Tipo de Transmision
-  VIN: Placa / Identificador Unico
-  Condition: Porcentaje del Estado del Vehiculo
-  Odometro: Distancia recoorrida en Millas
-  Color: Color Exterior del Vehiculo
-  Interior: Color del Interior del Vehiculo
-  Seller: Entidad que vendio el Vehiculo
-  MMR: Valor Estimado en el Mercado.
-  SellingPrice: Precio de Venta
-  SaleDate: Fecha de la Venta

# Limpieza Tabla Usando SQL
La informacion se descgargo en Kaggle en formato CSV, se importo a SQL Managment Studio utilizando la herramienta de Importar Archivos, con la informacion cargada se comenzo a Trabajar. 
En el Siguiente Link de Notion tengo Notas con Imagenes del proceso de Limpieza de la Informacion Utilizando SQL.

```sql
-- Validar el Tipo de Dato con el que se creo la informacion
exec sp_help car_prices;

/*
Se creara segunda  una tabla como catalogo de Vehiculos, con informacion unica del Modelo, Año, Fabricante, transmision, Deescripcion, etc, por lo que se creo una Llave/ID utilizando
-  2 ultimos digitos del Año
-  3 primeros caracteres de las columnas Make, Modelo, Trim, Body y Transmision, y en caso de que tenga valores NULL, le dejare la palabra
Por lo que se crea el ID en la tabla original para posterior pasarlo a la nueva y poder unirlos mas tarde
*/

-- Se valida como Quedara el ID.
Select *, RIGHT(YEAR,2)+LEFT(make,3)+COALESCE(LEFT(MODEL,3),'NULL')+COALESCE(LEFT(TRIM,3),'NULL')+COALESCE(LEFT(BODY,3),'NULL')+ COALESCE(LEFT(Transmission,3),'NULL') from car_prices;

-- Se agrega Columna Nueva
Alter Table CAR_PRICES add ID_VEHICULO NVARCHAR(20);

-- Se actualiza la columna con el Nuevo ID.
UPDATE car_prices
SET    id_vehiculo = RIGHT(year, 2) + LEFT(make, 3)
                     + COALESCE(LEFT(model, 3), 'NULL')
                     + COALESCE(LEFT(trim, 3), 'NULL')
                     + COALESCE(LEFT(body, 3), 'NULL')
                     + COALESCE(LEFT(transmission, 3), 'NULL') 

-- Se crea  y se pobla nueva Tabla
CREATE TABLE vehiculos
  (
     year         INT,
     brand        NVARCHAR(50),
     model        NVARCHAR(50),
     v_desc       NVARCHAR(50),
     v_type       NVARCHAR(50),
     transmission NVARCHAR(50),
     id_vehiculo  NVARCHAR(20)
  );

INSERT INTO vehiculos
SELECT year,
       make,
       model,
       trim,
       body,
       transmission,
       id_vehiculo
FROM   car_prices; 

-- Limpuieza Tabla Vehiculos
--Limpieza Columna YEAR: No tenia valores duplicados o que se pudieran agrupar.

-- Columna Brand
--Validacion
SELECT DISTINCT brand,
                Count(*)
FROM   vehiculos
GROUP  BY brand
ORDER  BY 1; 

-- Se identifican manualmente los valores y se actualizan con un update Simple como este.
Update vehiculos set brand = 'Chevrolet' where brand = 'chev truck';

--Buscar Marcas Vacias que no tengan informacion de modelo, descripciom o tipo.
Select brand, model, v_desc, V_type, count(*) from vehiculos where brand is null
group by brand, model, v_desc, V_type;

-- Se eliminan
delete from  vehiculos where brand is null;

-- Columna Tipo
-- Valdiar los NULL o datos repetidos.
SELECT DISTINCT v_type,
                Count(*)
FROM   vehiculos
GROUP  BY v_type
ORDER  BY 1;

-- Para los Valores NULL se opta por poner el Type del vehiculo que comparta BRAND y MODEL, que tenga mas Valores.
-- Con el query Anexo se crea una Conexion entre los valores NULL y los valores que tengan mas cantidad y compartan Brand y Model, posterior se saca la informacion y se crean Updates utilizando un Concatenar.
-- Este query saca los valroes donde el NULL sea el que el ultimo Numero.
WITH conteo AS
(
         SELECT   brand,
                  model,
                  v_type,
                  Count(*) AS cantidad
         FROM     vehiculos
         GROUP BY brand,
                  model,
                  v_type), -- Query para sacar la cantidad de autos que comparten marca, modelo y Type
rn AS
(
         SELECT   brand,
                  model,
                  v_type,
                  cantidad,
                  Row_number() OVER(partition BY brand, model ORDER BY cantidad DESC) AS orden
         FROM     conteo ), -- Query para asignar un orden en base a la cantidad de Autos que hay, el que tenga mas cantidad es el primero de la lista, agrupados por Marca, y modelo
rn_2 AS
(
         SELECT   brand,
                  model,
                  v_type,
                  cantidad,
                  orden,
                  Row_number() OVER(partition BY brand, model ORDER BY cantidad) AS ordeninv
         FROM     rn) -- Query que asigna el mismo orden que el anterior pero a la inversa, es decir que la columna que menos cantidad sea tenga el numero 1, es decir que los que tengan valores NULL pasen a tener un Orden de 1, y asi poder igualarlos con el Orden anterior y obtener los datos
SELECT     *
FROM       rn_2 A
INNER JOIN rn_2 b
ON         a.orden = b.ordeninv
AND        a.model = b.model
AND        a.brand = b.brand
WHERE      a.v_type IS NOT NULL
AND        b.v_type IS NULL; -- Self Join que une el El numero de Orden Normal, con el el que tenga el mismo orden inverso, y que tengan igual modelo y marca

-- Funciona de la Misma Manera del Anterior, pero este es para cuando el Numero de los NULL este en Segundo Lugar del conteo
WITH conteo
     AS (SELECT brand,
                model,
                v_type,
                Count(*) AS Cantidad
         FROM   vehiculos
         GROUP  BY brand,
                   model,
                   v_type),
     rn
     AS (SELECT brand,
                model,
                v_type,
                cantidad,
                Row_number()
                  OVER(
                    partition BY brand, model
                    ORDER BY cantidad DESC) AS orden
         FROM   conteo),
     rn_2
     AS (SELECT brand,
                model,
                v_type,
                cantidad,
                orden,
                Row_number()
                  OVER(
                    partition BY brand, model
                    ORDER BY cantidad) AS ordenINv,
                CASE
                  WHEN orden = 1
                       AND v_type IS NULL THEN 2
                  WHEN orden = 2
                       AND v_type IS NULL THEN 1
                END                    AS n_orden
         FROM   rn)
SELECT *
FROM   rn_2 A
       INNER JOIN rn_2 b
               ON a.model = b.model
                  AND a.brand = b.brand
                  AND A.orden = B.n_orden -- and a.body = b.body
WHERE  A.v_type IS NOT NULL
       AND b.v_type IS NULL; 

-- Columna Transmission
-- Se utilizo lo mismo para la Columna Transmission
WITH conteo
     AS (SELECT brand,
                model,
                transmission,
                Count(*) AS Cantidad
         FROM   vehiculos
         GROUP  BY brand,
                   model,
                   transmission),
     -- Query para sacar la cantidad de autos que comparten marca, modelo y Type
     rn
     AS (SELECT brand,
                model,
                transmission,
                cantidad,
                Row_number()
                  OVER(
                    partition BY brand, model
                    ORDER BY cantidad DESC) AS orden
         FROM   conteo),
     -- Query para asignar un orden en base a la cantidad de Autos que hay, el que tenga mas cantidad es el primero de la lista, agrupados por Marca, y modelo
     rn_2
     AS (SELECT brand,
                model,
                transmission,
                cantidad,
                orden,
                Row_number()
                  OVER(
                    partition BY brand, model
                    ORDER BY cantidad) AS ordenINv
         FROM   rn)
-- Query que asigna el mismo orden que el anterior pero a la inversa, es decir que la columna que menos cantidad sea tenga el numero 1, es decir que los que tengan valores NULL pasen a tener un Orden de 1, y asi poder igualarlos con el Orden anterior y obtener los datos
SELECT *
FROM   rn_2 A
       INNER JOIN rn_2 b
               ON a.orden = b.ordeninv
                  AND a.model = b.model
                  AND a.brand = b.brand
WHERE  a.transmission IS NOT NULL
       AND b.transmission IS NULL; -- Self Join que une el El numero de Orden Normal, con el el que tenga el mismo orden inverso, y que tengan igual modelo y marca
-- Cuando el NULL no es el ultimo Valor.
--Completar la Columna Body, en base a poner el tipo de Body que tenga mas cantidad
WITH conteo
     AS (SELECT brand,
                model,
                transmission,
                Count(*) AS Cantidad
         FROM   vehiculos
         GROUP  BY brand,
                   model,
                   transmission),
     rn
     AS (SELECT brand,
                model,
                transmission,
                cantidad,
                Row_number()
                  OVER(
                    partition BY brand, model
                    ORDER BY cantidad DESC) AS orden
         FROM   conteo),
     rn_2
     AS (SELECT brand,
                model,
                transmission,
                cantidad,
                orden,
                Row_number()
                  OVER(
                    partition BY brand, model
                    ORDER BY cantidad) AS ordenINv,
                CASE
                  WHEN orden = 1
                       AND transmission IS NULL THEN 2
                  WHEN orden = 2
                       AND transmission IS NULL THEN 1
                END                    AS n_orden
         FROM   rn)
SELECT *
FROM   rn_2 A
       INNER JOIN rn_2 b
               ON a.model = b.model
                  AND a.brand = b.brand
                  AND A.orden = B.n_orden -- and a.body = b.body
WHERE  A.transmission IS NOT NULL
       AND b.transmission IS NULL;

-- Valores Restantes
select * from Vehiculos
 where transmission = 'Sedan';
 Select TRANSMISSION, COUNT(*) from vehiculos where model = 'Jetta' and V_desc like '%SE PZEV%' GROUP BY TRANSMISSION;

 Update Vehiculos set transmission = 'Automatic'
 where transmission = 'Sedan';


-- Quitar Duplicados
WITH duplicados
     AS (SELECT *,
                Row_number()
                  OVER(
                    partition BY id_vehiculo2
                    ORDER BY year) AS rn
         FROM   vehiculos)
--Select * from Duplicados
DELETE FROM duplicados
WHERE  rn > 1;

--Agregar Columna de ID Auto con Datos Correctos
SELECT *,
       RIGHT(year, 2) + LEFT(brand, 3)
       + COALESCE(LEFT(model, 3), 'NULL')
       + COALESCE(LEFT(v_desc, 3), 'NULL')
       + COALESCE(LEFT(v_type, 3), 'NULL')
       + COALESCE(LEFT(transmission, 3), 'NULL')
FROM   vehiculos;

ALTER TABLE vehiculos
  ADD id_vehiculo2 NVARCHAR(20);

UPDATE vehiculos
SET    id_vehiculo2 = RIGHT(year, 2) + LEFT(brand, 3)
                      + COALESCE(LEFT(model, 3), 'NULL')
                      + COALESCE(LEFT(v_desc, 3), 'NULL')
                      + COALESCE(LEFT(v_type, 3), 'NULL')
                      + COALESCE(LEFT(transmission, 3), 'NULL')


-- Limpieza Tabla Car_Prices
-- Quitar columnas de los Autos.
ALTER TABLE car_prices
  DROP COLUMN make, model, trim, body, transmission;

-- Relacion Tablas.
SELECT Count(*)
FROM   car_prices
WHERE  id_vehiculo IS NULL;

DELETE FROM car_prices
WHERE  id_vehiculo IS NULL;

-- Actualizar ID vEHICULO en la TABLA de ventas
SELECT *
FROM   car_prices A
       INNER JOIN vehiculos B
               ON a.id_vehiculo = b.id_vehiculo

--WHERE B.id_vehiculo IS NULL;
UPDATE a
SET    a.id_vehiculo = b.id_vehiculo2
FROM   car_prices a
       INNER JOIN vehiculos b
               ON a.id_vehiculo = b.id_vehiculo; 

-- Limpieza tabla Car_prices
WITH largo
     AS (SELECT *,
                Len(state) AS longitud
         FROM   car_prices)
SELECT *
FROM   largo a
       INNER JOIN largo b
               ON a.state = b.state
WHERE  a.longitud > 2;
--UPDATE A SET A.STATE = NULL, A.VIN = B.STATE, A.CONDITION = B.ODOMETER, A.ODOMETER = B.COLOR, A.COLOR = B.INTERIOR, A.SELLER = NULL FROM LARGO A INNER JOIN LARGO B ON A.STATE = B.STATE
--WHERE A.longitud >2;

-- Columna Fecha
SELECT *,
       try_cast(saledate as date)
FROM   car_prices
WHERE  year = 2015;

UPDATE car_prices
SET    saledate = Trim(Substring(saledate,2,Len(saledate)));UPDATE car_prices
SET    saledate = try_cast(saledate as date)
