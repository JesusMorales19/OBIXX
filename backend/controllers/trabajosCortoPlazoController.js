import { query } from '../config/db.js';
import { handleDatabaseError, handleValidationError } from '../services/errorHandler.js';

/**
 * Registrar un nuevo trabajo de corto plazo
 */
export const registrarTrabajoCortoPlazo = async (req, res) => {
  try {
    const {
      emailContratista,
      titulo,
      descripcion,
      rangoPago,
      moneda = 'MXN',
      latitud,
      longitud,
      direccion,
      disponibilidad,
      vacantesDisponibles,
      especialidad,
      imagenes = [],
    } = req.body;

    if (!emailContratista || !titulo || !descripcion || !rangoPago) {
      return handleValidationError(res, 'Faltan campos requeridos');
    }

    if (vacantesDisponibles === undefined || vacantesDisponibles === null) {
      return handleValidationError(res, 'El número de vacantes es requerido');
    }

    // Validar que tenga al menos dirección o coordenadas
    if ((!latitud || !longitud) && (!direccion || direccion.trim() === '')) {
      return handleValidationError(res, 'Se requiere la ubicación del trabajo (coordenadas o dirección)');
    }

    const contratistaResult = await query(
      'SELECT email FROM contratistas WHERE email = $1',
      [emailContratista]
    );

    if (contratistaResult.rows.length === 0) {
      return handleValidationError(res, 'Contratista no encontrado', 404);
    }

    const trabajoResult = await query(
      `INSERT INTO trabajos_corto_plazo (
        email_contratista,
        titulo,
        descripcion,
        latitud,
        longitud,
        direccion,
        rango_pago,
        moneda,
        estado,
        vacantes_disponibles,
        disponibilidad,
        especialidad
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'activo', $9, $10, $11)
      RETURNING *`,
      [
        emailContratista,
        titulo,
        descripcion,
        latitud || null,
        longitud || null,
        direccion || null,
        rangoPago,
        moneda,
        vacantesDisponibles,
        disponibilidad || null,
        especialidad || null,
      ]
    );

    const trabajo = trabajoResult.rows[0];

    if (Array.isArray(imagenes) && imagenes.length > 0) {
      const insertPromises = imagenes
        .filter((img) => typeof img === 'string' && img.trim().length > 0)
        .map((img) =>
          query(
            `INSERT INTO trabajos_corto_plazo_imagenes (id_trabajo_corto, imagen_base64)
             VALUES ($1, $2)`,
            [trabajo.id_trabajo_corto, img]
          )
        );
      await Promise.all(insertPromises);
    }

    res.status(201).json({
      success: true,
      message: 'Trabajo de corto plazo registrado',
      data: trabajo,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al registrar trabajo corto plazo');
  }
};

/**
 * Obtener trabajos de corto plazo del contratista
 */
export const obtenerTrabajosCortoPorContratista = async (req, res) => {
  try {
    const { emailContratista } = req.query;

    if (!emailContratista) {
      return handleValidationError(res, 'Email del contratista es requerido');
    }

    const result = await query(
      `SELECT 
        tcp.*,
        COALESCE(
          json_agg(json_build_object(
            'id_imagen', tci.id_imagen,
            'imagen_base64', tci.imagen_base64
          ) ORDER BY tci.id_imagen)
          FILTER (WHERE tci.id_imagen IS NOT NULL),
          '[]'::json
        ) AS imagenes
       FROM trabajos_corto_plazo tcp
       LEFT JOIN trabajos_corto_plazo_imagenes tci ON tcp.id_trabajo_corto = tci.id_trabajo_corto
       WHERE tcp.email_contratista = $1
       GROUP BY tcp.id_trabajo_corto
       ORDER BY tcp.created_at DESC`,
      [emailContratista]
    );

    res.status(200).json({
      success: true,
      total: result.rows.length,
      trabajos: result.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener trabajos cortos');
  }
};

/**
 * Buscar trabajos de corto plazo cercanos a un trabajador
 */
export const buscarTrabajosCortoCercanos = async (req, res) => {
  try {
    const { emailTrabajador, radio = 500 } = req.query;

    if (!emailTrabajador) {
      return handleValidationError(res, 'Email del trabajador es requerido');
    }

    const trabajadorResult = await query(
      `SELECT t.latitud, t.longitud, c.nombre AS categoria_nombre
       FROM trabajadores t
       LEFT JOIN categorias c ON t.categoria = c.id_categoria
       WHERE t.email = $1`,
      [emailTrabajador]
    );

    if (trabajadorResult.rows.length === 0) {
      return handleValidationError(res, 'Trabajador no encontrado', 404);
    }

    const { latitud: lat1, longitud: lon1, categoria_nombre: categoriaNombreRaw } =
      trabajadorResult.rows[0];

    if (!lat1 || !lon1) {
      return handleValidationError(res, 'El trabajador no tiene ubicación registrada');
    }

    const categoriaNombre =
      typeof categoriaNombreRaw === 'string' && categoriaNombreRaw.trim().length > 0
        ? categoriaNombreRaw.trim()
        : null;

    if (!categoriaNombre) {
      return res.status(200).json({
        success: true,
        total: 0,
        radio_km: Number(radio),
        trabajos: [],
      });
    }

    const result = await query(
      `SELECT 
        trabajos.id_trabajo_corto,
        trabajos.email_contratista,
        trabajos.titulo,
        trabajos.descripcion,
        trabajos.rango_pago,
        trabajos.moneda,
        trabajos.latitud,
        trabajos.longitud,
        trabajos.direccion,
        trabajos.estado,
        trabajos.vacantes_disponibles,
        trabajos.disponibilidad,
        trabajos.especialidad,
        trabajos.created_at,
        trabajos.nombre_contratista,
        trabajos.apellido_contratista,
        trabajos.telefono_contratista,
        trabajos.distancia_km,
        COALESCE(
          json_agg(json_build_object(
            'id_imagen', tci.id_imagen,
            'imagen_base64', tci.imagen_base64
          ) ORDER BY tci.id_imagen)
          FILTER (WHERE tci.id_imagen IS NOT NULL),
          '[]'::json
        ) AS imagenes
       FROM (
         SELECT 
           tcp.*,
           c.nombre AS nombre_contratista,
           c.apellido AS apellido_contratista,
           c.telefono AS telefono_contratista,
           CASE 
             -- Si el trabajo tiene coordenadas, calcular distancia trabajo → trabajador
             WHEN tcp.latitud IS NOT NULL AND tcp.longitud IS NOT NULL THEN
               (6371 * acos(
                 cos(radians($1)) * cos(radians(tcp.latitud)) * 
                 cos(radians(tcp.longitud) - radians($2)) + 
                 sin(radians($1)) * sin(radians(tcp.latitud))
               ))
             -- Si el trabajo NO tiene coordenadas pero tiene dirección, usar coordenadas del contratista
             WHEN (tcp.latitud IS NULL OR tcp.longitud IS NULL) 
                  AND (tcp.direccion IS NOT NULL AND tcp.direccion != '')
                  AND c.latitud IS NOT NULL AND c.longitud IS NOT NULL THEN
               (6371 * acos(
                 cos(radians($1)) * cos(radians(c.latitud)) * 
                 cos(radians(c.longitud) - radians($2)) + 
                 sin(radians($1)) * sin(radians(c.latitud))
               ))
             ELSE NULL
           END AS distancia_km
         FROM trabajos_corto_plazo tcp
         INNER JOIN contratistas c ON tcp.email_contratista = c.email
         WHERE tcp.estado = 'activo'
           AND LOWER(tcp.especialidad) = LOWER($4)
           AND (
             -- Trabajos con coordenadas dentro del radio
             (tcp.latitud IS NOT NULL AND tcp.longitud IS NOT NULL AND
              (6371 * acos(
                cos(radians($1)) * cos(radians(tcp.latitud)) * 
                cos(radians(tcp.longitud) - radians($2)) + 
                sin(radians($1)) * sin(radians(tcp.latitud))
              )) <= $3)
             OR
             -- Trabajos sin coordenadas pero con dirección: usar coordenadas del contratista
             ((tcp.latitud IS NULL OR tcp.longitud IS NULL) 
              AND (tcp.direccion IS NOT NULL AND tcp.direccion != '')
              AND c.latitud IS NOT NULL AND c.longitud IS NOT NULL
              AND (6371 * acos(
                cos(radians($1)) * cos(radians(c.latitud)) * 
                cos(radians(c.longitud) - radians($2)) + 
                sin(radians($1)) * sin(radians(c.latitud))
              )) <= $3)
           )
       ) AS trabajos
       LEFT JOIN trabajos_corto_plazo_imagenes tci ON trabajos.id_trabajo_corto = tci.id_trabajo_corto
       GROUP BY trabajos.id_trabajo_corto,
                trabajos.email_contratista,
                trabajos.titulo,
                trabajos.descripcion,
                trabajos.rango_pago,
                trabajos.moneda,
                trabajos.latitud,
                trabajos.longitud,
                trabajos.direccion,
                trabajos.estado,
                trabajos.vacantes_disponibles,
                trabajos.disponibilidad,
                trabajos.especialidad,
                trabajos.created_at,
                trabajos.nombre_contratista,
                trabajos.apellido_contratista,
                trabajos.telefono_contratista,
                trabajos.distancia_km
       ORDER BY 
         CASE WHEN trabajos.distancia_km IS NULL THEN 1 ELSE 0 END,
         trabajos.distancia_km ASC NULLS LAST`,
      [lat1, lon1, Number(radio), categoriaNombre]
    );

    res.status(200).json({
      success: true,
      total: result.rows.length,
      radio_km: Number(radio),
      trabajos: result.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al buscar trabajos cortos cercanos');
  }
};