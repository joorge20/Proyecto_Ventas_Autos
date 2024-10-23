# Limpeiza de Datos en SQL
En este archivo pondre los Fragmentos de Codigo mas Significativos que se usaron para la limpieza de los Datos, En el PDF Adjunto se encuentra la misma informacion pero mas detallada con mas imagenes.

La idea al comenzar la limpeiza fue la de separar la tabla principal en dos partes:
-  Tabla Ventas: Con la informacion de las ventas de los Autos (Fecha, Color, Odometro, etc).
-  Tabla Catalogo Autos: Informacion de cada modelo en Especifico (Marca, Modelo, Año, etc)

```sql
-- Validar el Tipo de Dato con el que se importo la Informacion
exec sp_help car_prices;
```
## Creacion Llave
Se creo una Llave/ID oara poder unir las tablas mas adelante, ya que las separare, la llave se creo utilizando
-  2 ultimos digitos del Año
-  3 primeros caracteres de las columnas Make, Modelo, Trim, Body y Transmision, y en caso de que tenga valores NULL, le dejare la palabra

```sql
UPDATE car_prices
SET    id_vehiculo = RIGHT(year, 2) + LEFT(make, 3)
                     + COALESCE(LEFT(model, 3), 'NULL')
                     + COALESCE(LEFT(trim, 3), 'NULL')
                     + COALESCE(LEFT(body, 3), 'NULL')
                     + COALESCE(LEFT(transmission, 3), 'NULL') 
```

## Creacion Tabla
```sql
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
```

## Limpieza Columnas

###Columna BRAND
Se detectaron Valores que se pueden Agrupar, y columnas con Valores NULL,
Las columnas que se pueden agrupar se hace mediante un update sencillo, y las columnas NULL se valido y son registros que no contienen informacion relevante, por lo que
se procede a elimianr los registros.
```sql
SELECT DISTINCT brand,
                Count(*)
FROM   vehiculos
GROUP  BY brand
ORDER  BY 1; 
```
### Columna MODEL
No hay modelos repetido, pero existen valores NULL, al validarlos por Descripcion, estos Modelos en NULL, comparten Marca y Descripcion con registros que ya existen en el catalogo,
por lo que manualmente se actualiza la informacion.

### Columna Desacripcion
No se corrige, ya que es un texto demasiado variable

### Columna Type
Se encuentran Valores NULL.
Se realizo una consulta de la cantidad de TYPE que tiene cada auto por Modelo y Marca utilizando un SELF JOIN y CTE's, para pasarle el valor que tenga la mayoría de los carros, a los que tienen valor Null que son la minoría.
Por ejemplo el Chevrolet IMPALA tiene casi 8k autos tipo SEDAN y tiene 2 Valores en NULL, entonces esos 2 pasan a ser tipo SEDAN.
La consulta la hice asignando un RANKING de acuerdo a la cantidad de TYPE que tengan, es decir lo que tenga mas cantidad sera el 1 y NULL el Ultimo, e Hice un RANKING Inverso, es decir el que tenga mas sera el utlimo y NULL el 1.
Asi realice el SELF JOIN amarrando los que tienen mas con el que tiene menos.
En este paso encontre 2 escenarios, 
-  Cuando NULL es el ID 3.
-  Cuando ID es el 2.

Se anexan las consultas utilizadas, para realizar los updates se uso EXCEL concatenando un UPDATE.
```sql
-- NULL = 3
WITH conteo
     AS (SELECT brand,
                model,
                v_type,
                Count(*) AS cantidad
         FROM   vehiculos
         GROUP  BY brand,
                   model,
                   v_type),
     -- Query para sacar la cantidad de autos que comparten marca, modelo y Type
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
     -- Query para asignar un orden en base a la cantidad de Autos que hay, el que tenga mas cantidad es el primero de la lista, agrupados por Marca, y modelo
     rn_2
     AS (SELECT brand,
                model,
                v_type,
                cantidad,
                orden,
                Row_number()
                  OVER(
                    partition BY brand, model
                    ORDER BY cantidad) AS ordeninv
         FROM   rn)
-- Query que asigna el mismo orden que el anterior pero a la inversa, es decir que la columna que menos cantidad sea tenga el numero 1, es decir que los que tengan valores NULL pasen a tener un Orden de 1, y asi poder igualarlos con el Orden anterior y obtener los datos
SELECT *
FROM   rn_2 A
       INNER JOIN rn_2 b
               ON a.orden = b.ordeninv
                  AND a.model = b.model
                  AND a.brand = b.brand
WHERE  a.v_type IS NOT NULL
       AND b.v_type IS NULL; -- Self Join que une el El numero de Orden Normal, con el el que tenga el mismo orden inverso, y que tengan igual modelo y marca

-- NULL = 2
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
```

### Columna TRANSMISSION
Se enceunrtan Valores NULL, y se aplica la misma logica del paso anterior, se pone la TRANSMISSION que mas comparta un vehiculo por marca y Modelo.
Se repite el Escenario anterior del 2 y 3.

```sql
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
```
### Columna BODY
Se aplica la misma logica de los dos Escenarios anteriores, utilizando el mismo Query pero cambiando la columna Correspondiente por BODY.

## Remover Duplicados
Se remueven filas que contengan los mismos datos, se utiliza la llave que se creo, se cuenta cuantas veces aparece, y si aparece mas de una vez se eliminan los diferentes a 1

```sql
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
```
## Columna Nueva con los ID's de Datos Corregidos.
```sql
ALTER TABLE vehiculos ADD id_vehiculo2 NVARCHAR(20);

UPDATE vehiculos
SET    id_vehiculo2 = RIGHT(year, 2) + LEFT(brand, 3)
                      + COALESCE(LEFT(model, 3), 'NULL')
                      + COALESCE(LEFT(v_desc, 3), 'NULL')
                      + COALESCE(LEFT(v_type, 3), 'NULL')
                      + COALESCE(LEFT(transmission, 3), 'NULL')
```
## Limpieza Tabla CAR_PRICES (Ventas)

### Remover Columnas del Catalogo Autos.
```sql
ALTER TABLE car_prices
  DROP COLUMN make, model, trim, body, transmission;
```
### Update Llave
Se actualiza la llave de la tabla de Ventas con la informacion de la nueva llave de ventas

```sql
UPDATE a
SET    a.id_vehiculo = b.id_vehiculo2
FROM   car_prices a
       INNER JOIN vehiculos b
               ON a.id_vehiculo = b.id_vehiculo; 

```
## Columnas Restantes
Se valido y existe cierta informacion que al parecer esta recorrida una fila, el siguiente update corrige esas columnas.
```sql
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
```

### Correcion Fechas.
```sql
UPDATE car_prices
SET    saledate = Trim(Substring(saledate,2,Len(saledate)));
UPDATE car_prices
SET    saledate = try_cast(saledate as date)

```
