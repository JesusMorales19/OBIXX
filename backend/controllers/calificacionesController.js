import { getClient, query } from '../config/db.js';
import { notificarCalificacionTrabajador } from '../services/notificationService.js';
import { handleDatabaseError, handleValidationError, handleError } from '../services/errorHandler.js';

const obtenerNombreContratista = async (emailContratista) => {
  if (!emailContratista) return '';
  const result = await query(
    'SELECT nombre, apellido FROM contratistas WHERE email = $1',
    [emailContratista]
  );
  if (result.rows.length === 0) return '';
  const { nombre, apellido } = result.rows[0];
  return [nombre, apellido]
    .map((parte) => (parte || '').trim())
    .filter((parte) => parte.length > 0)
    .join(' ');
};

export const registrarCalificacion = async (req, res) => {
  const {
    emailContratista,
    emailTrabajador,
    idAsignacion,
    estrellas,
    resena = null,
  } = req.body;

  if (
    !emailContratista ||
    !emailTrabajador ||
    !idAsignacion ||
    estrellas === undefined
  ) {
    return handleValidationError(res, 'Faltan campos requeridos');
  }

  const idAsignacionNumber = Number(idAsignacion);
  const estrellasNumber = Number(estrellas);

  if (Number.isNaN(idAsignacionNumber) || idAsignacionNumber <= 0) {
    return handleValidationError(res, 'El id de asignación no es válido');
  }

  if (
    Number.isNaN(estrellasNumber) ||
    estrellasNumber < 1 ||
    estrellasNumber > 5
  ) {
    return handleValidationError(res, 'La calificación debe ser un número entre 1 y 5');
  }

  const client = await getClient();
  const nombreContratista = await obtenerNombreContratista(emailContratista);

  try {
    await client.query('BEGIN');

    const asignacionResult = await client.query(
      `SELECT email_contratista, email_trabajador, estado, tipo_trabajo, id_trabajo
       FROM asignaciones_trabajo
       WHERE id_asignacion = $1`,
      [idAsignacionNumber]
    );

    if (asignacionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'La asignación indicada no existe', 404);
    }

    const asignacion = asignacionResult.rows[0];
    if (
      asignacion.email_contratista !== emailContratista ||
      asignacion.email_trabajador !== emailTrabajador
    ) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'La asignación no pertenece al contratista o trabajador proporcionados', 403);
    }

    let tituloTrabajo = 'Trabajo';
    if (asignacion.tipo_trabajo && asignacion.id_trabajo) {
      const tablaTrabajo = asignacion.tipo_trabajo === 'corto'
        ? 'trabajos_corto_plazo'
        : 'trabajos_largo_plazo';
      const campoId = asignacion.tipo_trabajo === 'corto'
        ? 'id_trabajo_corto'
        : 'id_trabajo_largo';
      const trabajoTituloResult = await client.query(
        `SELECT titulo FROM ${tablaTrabajo} WHERE ${campoId} = $1`,
        [asignacion.id_trabajo]
      );
      const tituloEncontrado = trabajoTituloResult.rows[0]?.titulo;
      if (tituloEncontrado && tituloEncontrado.trim().length > 0) {
        tituloTrabajo = tituloEncontrado.trim();
      }
    }

    const insertResult = await client.query(
      `INSERT INTO calificaciones_trabajadores (
         email_contratista,
         email_trabajador,
         id_asignacion,
         estrellas,
         resena
       )
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id_calificacion, fecha_calificacion`,
      [
        emailContratista,
        emailTrabajador,
        idAsignacionNumber,
        estrellasNumber,
        resena,
      ]
    );

    const promedioResult = await client.query(
      `SELECT AVG(estrellas)::numeric(4,2) AS promedio
       FROM calificaciones_trabajadores
       WHERE email_trabajador = $1`,
      [emailTrabajador]
    );

    const promedio =
      promedioResult.rows[0]?.promedio !== null
        ? Number(promedioResult.rows[0].promedio)
        : estrellasNumber;

    await client.query(
      `UPDATE trabajadores
       SET calificacion_promedio = $1
       WHERE email = $2`,
      [promedio, emailTrabajador]
    );

    await client.query('COMMIT');

    // Eliminar notificaciones de calificación pendientes para esta asignación
    try {
      await query(
        `DELETE FROM notificaciones_usuario
         WHERE email_destino = $1
           AND tipo = 'solicitud_cancelada'
           AND data_json->>'idAsignacion' = $2`,
        [emailContratista, String(idAsignacionNumber)]
      );
    } catch (cleanupError) {
      // Error silencioso al limpiar notificaciones
    }

    await notificarCalificacionTrabajador({
      emailTrabajador,
      nombreContratista,
      emailContratista,
      estrellas: estrellasNumber,
      tituloTrabajo,
      contexto: asignacion.estado === 'cancelado' ? 'cancelado' : 'finalizado',
    });

    return res.status(200).json({
      success: true,
      message: 'Calificación registrada correctamente',
      data: {
        idCalificacion: insertResult.rows[0].id_calificacion,
        fechaCalificacion: insertResult.rows[0].fecha_calificacion,
        promedioActualizado: promedio,
      },
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});

    if (error.code === '23505') {
      return handleValidationError(res, 'Esta asignación ya fue calificada previamente', 409);
    }

    handleDatabaseError(error, res, 'Error al registrar calificación');
  } finally {
    client.release();
  }
};

export const obtenerCalificacionesTrabajador = async (req, res) => {
  try {
    const { emailTrabajador } = req.query;

    if (!emailTrabajador) {
      return handleValidationError(res, 'El email del trabajador es requerido');
    }

    const result = await query(
      `SELECT 
         ct.id_calificacion,
         ct.estrellas,
         ct.resena,
         ct.fecha_calificacion,
         ct.email_contratista,
         c.nombre AS nombre_contratista,
         c.apellido AS apellido_contratista,
         c.foto_perfil AS foto_contratista
       FROM calificaciones_trabajadores ct
       INNER JOIN contratistas c ON ct.email_contratista = c.email
       WHERE ct.email_trabajador = $1
       ORDER BY ct.fecha_calificacion DESC
       LIMIT 5`,
      [emailTrabajador]
    );

    return res.status(200).json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener calificaciones del trabajador');
  }
};

