import { query } from '../config/db.js';
import { handleDatabaseError, handleValidationError } from '../services/errorHandler.js';

/**
 * Registrar un nuevo trabajo de largo plazo
 */
export const registrarTrabajoLargoPlazo = async (req, res) => {
  try {
    const {
      emailContratista,
      titulo,
      descripcion,
      latitud,
      longitud,
      direccion,
      fechaInicio,
      fechaFin,
      vacantesDisponibles,
      tipoObra,
      frecuencia,
    } = req.body;

    // Validaciones básicas
    if (!emailContratista || !titulo || !descripcion || !fechaInicio || !fechaFin || !vacantesDisponibles) {
      return handleValidationError(res, 'Faltan campos requeridos');
    }

    // Validar que tenga al menos dirección o coordenadas
    if ((!latitud || !longitud) && (!direccion || direccion.trim() === '')) {
      return handleValidationError(res, 'Se requiere la ubicación del trabajo (coordenadas o dirección)');
    }

    // Verificar que el contratista existe
    const contratistaResult = await query(
      'SELECT email FROM contratistas WHERE email = $1',
      [emailContratista]
    );

    if (contratistaResult.rows.length === 0) {
      return handleValidationError(res, 'Contratista no encontrado', 404);
    }

    // Insertar el trabajo
    const result = await query(
      `INSERT INTO trabajos_largo_plazo (
        email_contratista,
        titulo,
        descripcion,
        latitud,
        longitud,
        direccion,
        fecha_inicio,
        fecha_fin,
        estado,
        vacantes_disponibles,
        tipo_obra,
        frecuencia,
        created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, CURRENT_TIMESTAMP)
      RETURNING 
        id_trabajo_largo,
        email_contratista,
        titulo,
        descripcion,
        latitud,
        longitud,
        direccion,
        fecha_inicio,
        fecha_fin,
        estado,
        vacantes_disponibles,
        tipo_obra,
        frecuencia,
        created_at`,
      [
        emailContratista,
        titulo,
        descripcion,
        latitud || null,
        longitud || null,
        direccion || null,
        fechaInicio,
        fechaFin,
        'activo', // Estado inicial
        vacantesDisponibles,
        tipoObra || null,
        frecuencia || null,
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Trabajo de largo plazo registrado exitosamente',
      data: result.rows[0],
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al registrar trabajo largo plazo');
  }
};

/**
 * Obtener trabajos de largo plazo de un contratista
 */
export const obtenerTrabajosPorContratista = async (req, res) => {
  try {
    const { emailContratista } = req.query;

    if (!emailContratista) {
      return handleValidationError(res, 'Email del contratista es requerido');
    }

    const result = await query(
      `SELECT 
        tlp.*,
        c.nombre as nombre_contratista,
        c.apellido as apellido_contratista
       FROM trabajos_largo_plazo tlp
       INNER JOIN contratistas c ON tlp.email_contratista = c.email
       WHERE tlp.email_contratista = $1
       ORDER BY tlp.created_at DESC`,
      [emailContratista]
    );

    res.status(200).json({
      success: true,
      total: result.rows.length,
      trabajos: result.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener trabajos');
  }
};

/**
 * Buscar trabajos cercanos (para trabajadores)
 */
export const buscarTrabajosCercanos = async (req, res) => {
  try {
    const { emailTrabajador, radio = 500 } = req.query;

    if (!emailTrabajador) {
      return handleValidationError(res, 'Email del trabajador es requerido');
    }

    // Obtener ubicación del trabajador
    const trabajadorResult = await query(
      'SELECT latitud, longitud FROM trabajadores WHERE email = $1',
      [emailTrabajador]
    );

    if (trabajadorResult.rows.length === 0) {
      return handleValidationError(res, 'Trabajador no encontrado', 404);
    }

    const { latitud: lat1, longitud: lon1 } = trabajadorResult.rows[0];

    if (!lat1 || !lon1) {
      return handleValidationError(res, 'El trabajador no tiene ubicación registrada');
    }

    // Buscar trabajos cercanos usando la fórmula de Haversine
    // Buscar trabajos cercanos usando subconsulta para evitar error con distancia_km
    const result = await query(
      `SELECT 
        id_trabajo_largo,
        email_contratista,
        titulo,
        descripcion,
        latitud,
        longitud,
        direccion,
        fecha_inicio,
        fecha_fin,
        estado,
        vacantes_disponibles,
        tipo_obra,
        frecuencia,
        created_at,
        nombre_contratista,
        apellido_contratista,
        telefono_contratista,
        email_contratista as email_contratista_full,
        distancia_km
       FROM (
         SELECT 
           tlp.*,
           c.nombre as nombre_contratista,
           c.apellido as apellido_contratista,
           c.telefono as telefono_contratista,
           CASE 
             -- Si el trabajo tiene coordenadas, calcular distancia trabajo → trabajador
             WHEN tlp.latitud IS NOT NULL AND tlp.longitud IS NOT NULL THEN
               (6371 * acos(
                 cos(radians($1)) * cos(radians(tlp.latitud)) * 
                 cos(radians(tlp.longitud) - radians($2)) + 
                 sin(radians($1)) * sin(radians(tlp.latitud))
               ))
             -- Si el trabajo NO tiene coordenadas pero tiene dirección, usar coordenadas del contratista
             WHEN (tlp.latitud IS NULL OR tlp.longitud IS NULL) 
                  AND (tlp.direccion IS NOT NULL AND tlp.direccion != '')
                  AND c.latitud IS NOT NULL AND c.longitud IS NOT NULL THEN
               (6371 * acos(
                 cos(radians($1)) * cos(radians(c.latitud)) * 
                 cos(radians(c.longitud) - radians($2)) + 
                 sin(radians($1)) * sin(radians(c.latitud))
               ))
             ELSE NULL
           END AS distancia_km
         FROM trabajos_largo_plazo tlp
         INNER JOIN contratistas c ON tlp.email_contratista = c.email
         WHERE tlp.estado = 'activo'
         AND tlp.vacantes_disponibles > 0
         AND (
           -- Trabajos con coordenadas dentro del radio
           (tlp.latitud IS NOT NULL AND tlp.longitud IS NOT NULL AND
            (6371 * acos(
              cos(radians($1)) * cos(radians(tlp.latitud)) * 
              cos(radians(tlp.longitud) - radians($2)) + 
              sin(radians($1)) * sin(radians(tlp.latitud))
            )) <= $3)
           OR
           -- Trabajos sin coordenadas pero con dirección: usar coordenadas del contratista
           ((tlp.latitud IS NULL OR tlp.longitud IS NULL) 
            AND (tlp.direccion IS NOT NULL AND tlp.direccion != '')
            AND c.latitud IS NOT NULL AND c.longitud IS NOT NULL
            AND (6371 * acos(
              cos(radians($1)) * cos(radians(c.latitud)) * 
              cos(radians(c.longitud) - radians($2)) + 
              sin(radians($1)) * sin(radians(c.latitud))
            )) <= $3)
         )
       ) AS trabajos_con_distancia
       ORDER BY 
         CASE WHEN distancia_km IS NULL THEN 1 ELSE 0 END,
         distancia_km ASC NULLS LAST`,
      [lat1, lon1, radio]
    );

    res.status(200).json({
      success: true,
      total: result.rows.length,
      radio_km: radio,
      trabajos: result.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al buscar trabajos cercanos');
  }
};

/**
 * Actualizar estado de un trabajo
 */
export const actualizarEstadoTrabajo = async (req, res) => {
  try {
    const { idTrabajo } = req.params;
    const { estado } = req.body;

    if (!estado) {
      return handleValidationError(res, 'El estado es requerido');
    }

    const result = await query(
      `UPDATE trabajos_largo_plazo 
       SET estado = $1
       WHERE id_trabajo_largo = $2
       RETURNING *`,
      [estado, idTrabajo]
    );

    if (result.rows.length === 0) {
      return handleValidationError(res, 'Trabajo no encontrado', 404);
    }

    res.status(200).json({
      success: true,
      message: 'Estado actualizado correctamente',
      data: result.rows[0],
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al actualizar estado');
  }
};

