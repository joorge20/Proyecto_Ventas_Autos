#Power BI

## Carga Datos
Se cargan a Power BI a traves de un Archivo EXCEL ambas tablas con la informacion ya limpia desde SQL.

No se realizo ninguna modificacion inmportante a las tablas cargadas, unicamente se cambio el formato a MAYUSCULAS a ciertas coluumnas
con la herramienta de Power Query

## Tabla Calendario
Se creo una tabla Calendario para poder trabajar con algunos datos de fechas, la tabla se creo utilizando lenguaje en codigo M.

```m
// Paso 1 Se toma de la Tabla Origen la columna sobre la que se calcularan las fechas.
= #"Ventas"[saledate]
```
![](Imagenes/9_TC_1.png)

```m
// Paso 2: Se agrega un paso extra llamado Fecha Min con la fecha deseada.
// Nota: La tabla comienza desde el año 1920 pero de esa fecha hasta 1970 la informacion no es muy relevante,
//por lo que se decide omitir.
= #date(Date.Year(List.Min(Origen)), 12, 31)
```
![](Imagenes/9_TC_2.png)

```m
// Paso 3: Se agrega otro paso llamado FechaMax para tomar el Año Maximo que encuentre en la tabla Animes
//y la columna fecha extreno,y le agregara los valores 12 y 31 haciendo referencia al dia 31 de Dicembre
= #date(Date.Year(List.Max(Origen)), 12, 31)
```
![](Imagenes/10_TC_3.png)

```m
Paso 4: Se agrega otro paso y se crea una lista desde el valor de FechaMIN hasta FechaMAX
= {Number.From(FechaMin)..Number.From(FechaMax)}
```

Paso 6: Se da a la opcion de convertir Lista a Tabla.
Paso 7: Se cambia el Tipo de Dato
Paso 8: Se agregan columnas con la herramienta de Power Query.

## Relaciones
Las tablas Vehiculos y Ventas se relacionan mediante el ID que se creo en la BD, y la columna SaleDate se relaciona con la fecha de la tabla calendario.
Se crean 2 tablas para medidas:
-  Medidas Basicas: SUM, COUNT, AVG
-  Medidas Especificas: Porcentajes, Con Filtros ETC.
![](Imagenes/11_Relaciones.png)

## Visualizaciones
![](Imagenes/12_Tablero_1.png)
![](Imagenes/13_Tablero_2.png)
![](Imagenes/14_Tablero_3.png)
![](Imagenes/15_Tablero_4.png)
![](Imagenes/16_Tablero_5.png)
