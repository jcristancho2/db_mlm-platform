# MLM Platform Database

## 📋 Descripción del Proyecto

Sistema de gestión de bases de datos relacional desarrollado en MySQL que respalda la operación de una plataforma digital destinada a la comercialización de productos y servicios ofrecidos por empresas registradas.

## 🚀 Características Principales

- **Gestión de Empresas**: Registro y administración de empresas con diferentes tipos y categorías
- **Catálogo de Productos**: Sistema completo de productos con categorías y precios
- **Gestión de Clientes**: Base de datos de clientes con preferencias y favoritos
- **Sistema de Encuestas**: Evaluación de satisfacción y preferencias de productos
- **Membresías**: Diferentes niveles de membresía con beneficios específicos
- **Geolocalización**: Soporte para países, regiones y ciudades
- **Audiencias Objetivo**: Segmentación por tipos de audiencia

## 🗄️ Estructura de la Base de Datos

### Tablas Principales

#### Entidades Geográficas
- `countries` - Países con códigos ISO
- `stateregions` - Estados/Regiones por país
- `citiesormunicipalities` - Ciudades y municipios
- `subdivisioncategories` - Tipos de subdivisiones

#### Entidades de Negocio
- `companies` - Empresas registradas
- `customers` - Clientes del sistema
- `products` - Catálogo de productos
- `categories` - Categorías de productos
- `audiences` - Tipos de audiencia objetivo

#### Sistema de Relaciones
- `favorites` - Productos favoritos de clientes
- `details_favorites` - Detalles de favoritos
- `companyproducts` - Productos por empresa
- `typesidentifications` - Tipos de identificación

#### Sistema de Evaluación
- `polls` - Encuestas disponibles
- `polls_companies` - Encuestas por empresa
- `pollproducts` - Productos en encuestas
- `customerpollratings` - Calificaciones de clientes
- `category_poll_links` - Enlaces entre categorías y encuestas

#### Sistema de Membresías
- `memberships` - Tipos de membresía
- `periods` - Períodos de facturación
- `membershipperiods` - Precios por período
- `benefits` - Beneficios disponibles
- `membershipbenefits` - Beneficios por membresía
- `audiencebenefits` - Beneficios por audiencia

## 🛠️ Instalación

### Prerrequisitos
- MySQL 8.0 o superior
- MySQL Workbench (opcional, para gestión visual)

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/db_mlm-platform.git
   cd db_mlm-platform
   ```

2**Crear la base de datos**
   ```sql
   CREATE DATABASE mlm_platform;
   USE mlm_platform;
   ```
3ecutar los scripts en orden**
   ```bash
   # Estructura de la base de datos
   mysql -u root -p mlm_platform < mlm-platform.sql
   
   # Datos de inserción
   mysql -u root -p mlm_platform < insert_mlm-platform.sql
   
   # Procedimientos almacenados
   mysql -u root -p mlm_platform < procedimentos_almacenados.sql
   
   # Triggers
   mysql -u root -p mlm_platform < triggers_mlm_platform.sql
   
   # Eventos
   mysql -u root -p mlm_platform < events_mlm_platform.sql
   
   # Funciones agregadas
   mysql -u root -p mlm_platform < funciones_agregadas.sql
   ```

## 📊 Archivos del Proyecto

| Archivo | Descripción |
|---------|-------------|
| `mlm-platform.sql` | Estructura principal de la base de datos |
| `insert_mlm-platform.sql` | Datos de inserción iniciales |
| `procedimentos_almacenados.sql` | Procedimientos almacenados |
| `triggers_mlm_platform.sql` | Triggers de la base de datos |
| `events_mlm_platform.sql` | Eventos programados |
| `funciones_agregadas.sql` | Funciones personalizadas |
| `consultas_especializadas.sql` | Consultas complejas de ejemplo |
| `consultas_joins.sql` | Ejemplos de JOINs |
| `subconsultas.sql` | Ejemplos de subconsultas |
| `UDF_HISTORIAS.sql` | Funciones definidas por el usuario |

## 🔍 Ejemplos de Uso

### Consulta de Productos por Categoría
```sql
SELECT p.name, p.price, c.description as category
FROM products p
JOIN categories c ON p.category_id = c.id
WHERE c.description = Periféricos y Accesorios de Computo;
```

### Empresas por Ciudad
```sql
SELECT co.name as company, ci.name as city, st.name as state
FROM companies co
JOIN citiesormunicipalities ci ON co.city_id = ci.code
JOIN stateregions st ON ci.statereg_id = st.code
WHERE st.name = Antioquia';
```

### Productos Favoritos de Clientes
```sql
SELECT c.name as customer, p.name as product, p.price
FROM customers c
JOIN favorites f ON c.id = f.customer_id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id;
```

## 📈 Características Avanzadas

### Triggers Implementados
- Validación automática de precios
- Auditoría de cambios en productos
- Actualización de estadísticas

### Procedimientos Almacenados
- Gestión de inventario
- Cálculo de estadísticas de ventas
- Generación de reportes

### Eventos Programados
- Limpieza de datos temporales
- Actualización de índices
- Generación de backups automáticos

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -mAdd some AmazingFeature'`)4 Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👥 Autores

- **JORGE ANDRES CRISTANCHO OLARTE** - *Desarrollo inicial* - [jcristancho2](https://github.com/jcristancho2)

## 🙏 Agradecimientos

- Comunidad MySQL
- Contribuidores del proyecto
- Usuarios que reportan bugs y mejoras

## 📞 Soporte

Si tienes alguna pregunta o necesitas ayuda:
- Abre un issue en GitHub
- Contacta al equipo de desarrollo
- Revisa la documentación técnica

---

**Nota**: Este proyecto está en desarrollo activo. Las características pueden cambiar sin previo aviso.
