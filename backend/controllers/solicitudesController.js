import { getClient, query } from '../config/db.js';
import {
  expirarSolicitudesPendientes,
  obtenerSolicitudPendienteTrabajador,
  marcarSolicitudesComoRechazadas,
} from '../services/solicitudesService.js';
import {
  crearNotificacion,
  obtenerTokensUsuario,
} from '../services/notificationService.js';
import { sendPushNotification } from '../services/firebaseService.js';
import { handleDatabaseError, handleValidationError, handleError } from '../services/errorHandler.js';

const TIPOS_TRABAJO_VALIDOS = ['corto', 'largo'];
const MINUTOS_EXPIRACION_SOLICITUD =
  Number(process.env.SOLICITUD_EXPIRACION_MINUTOS || 10);

export const aplicarATrabajo = async (req, res) => {
  const { emailTrabajador, tipoTrabajo, idTrabajo } = req.body;

  if (!emailTrabajador || !tipoTrabajo || !idTrabajo) {
    return handleValidationError(res, 'emailTrabajador, tipoTrabajo e idTrabajo son requeridos');
  }

  if (!TIPOS_TRABAJO_VALIDOS.includes(tipoTrabajo)) {
    return handleValidationError(res, 'Tipo de trabajo inválido');
  }

  await expirarSolicitudesPendientes();

  const client = await getClient();

  try {
    await client.query('BEGIN');

    const trabajadorResult = await client.query(
      `SELECT nombre, apellido, disponible, telefono, categoria, experiencia
         FROM trabajadores
        WHERE email = $1
        FOR UPDATE`,
      [emailTrabajador]
    );

    if (trabajadorResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Trabajador no encontrado', 404);
    }

    const trabajador = trabajadorResult.rows[0];

    const asignacionActivaResult = await client.query(
      `SELECT 1
         FROM asignaciones_trabajo
        WHERE email_trabajador = $1
          AND estado = 'activo'
        LIMIT 1`,
      [emailTrabajador]
    );

    if (asignacionActivaResult.rows.length > 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'El trabajador ya tiene un trabajo asignado');
    }

    // Contar solicitudes pendientes activas (hasta 3 permitidas)
    const solicitudesPendientes = await client.query(
      `SELECT COUNT(*) as total
         FROM solicitudes_trabajo
        WHERE email_trabajador = $1
          AND estado = 'pendiente'`,
      [emailTrabajador]
    );

    const totalSolicitudes = parseInt(solicitudesPendientes.rows[0].total || '0', 10);

    if (totalSolicitudes >= 3) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Ya has alcanzado el límite de 3 solicitudes activas');
    }

    const tablaTrabajo =
      tipoTrabajo === 'corto' ? 'trabajos_corto_plazo' : 'trabajos_largo_plazo';
    const campoId =
      tipoTrabajo === 'corto' ? 'id_trabajo_corto' : 'id_trabajo_largo';

    const trabajoResult = await client.query(
      `SELECT email_contratista, titulo, estado, vacantes_disponibles
         FROM ${tablaTrabajo}
        WHERE ${campoId} = $1`,
      [idTrabajo]
    );

    if (trabajoResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Trabajo no encontrado', 404);
    }

    const trabajo = trabajoResult.rows[0];

    if (
      Number(trabajo.vacantes_disponibles) <= 0 ||
      trabajo.estado !== 'activo'
    ) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'El trabajo no está disponible');
    }

    // Verificar si ya existe una solicitud pendiente para este trabajo específico
    const solicitudExistente = await client.query(
      `SELECT id_solicitud
         FROM solicitudes_trabajo
        WHERE email_trabajador = $1
          AND tipo_trabajo = $2
          AND id_trabajo = $3
          AND estado = 'pendiente'
        LIMIT 1`,
      [emailTrabajador, tipoTrabajo, idTrabajo]
    );

    if (solicitudExistente.rows.length > 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Ya has aplicado a este trabajo. Espera la respuesta del contratista.');
    }

    const solicitudInsert = await client.query(
      `INSERT INTO solicitudes_trabajo (
          email_trabajador,
          email_contratista,
          tipo_trabajo,
          id_trabajo,
          expira_en
        )
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP + ($5 || ' minutes')::interval)
        RETURNING id_solicitud, expira_en`,
      [
        emailTrabajador,
        trabajo.email_contratista,
        tipoTrabajo,
        idTrabajo,
        String(MINUTOS_EXPIRACION_SOLICITUD),
      ]
    );

    const solicitud = solicitudInsert.rows[0];

    // Actualizar estado del trabajador solo si tiene 3 solicitudes pendientes
    // o si ya tiene una asignación activa
    const nuevasSolicitudes = totalSolicitudes + 1;
    
    if (nuevasSolicitudes >= 3) {
      await client.query(
        `UPDATE trabajadores
            SET disponible = FALSE
          WHERE email = $1`,
        [emailTrabajador]
      );
    }

    await client.query('COMMIT');

    // Eliminar notificaciones de calificación pendientes para este trabajador y contratista
    // cuando el trabajador aplica a un nuevo trabajo
    try {
      await query(
        `DELETE FROM notificaciones_usuario
         WHERE email_destino = $1
           AND tipo = 'solicitud_cancelada'
           AND data_json->>'emailTrabajador' = $2`,
        [trabajo.email_contratista, emailTrabajador]
      );
    } catch (cleanupError) {
      // Error silencioso al limpiar notificaciones
    }

    const nombreTrabajador = `${trabajador.nombre ?? ''} ${
      trabajador.apellido ?? ''
    }`.trim();

    const cuerpoNotificacion = nombreTrabajador
      ? `${nombreTrabajador} se interesó en el proyecto "${trabajo.titulo}". Recuerda que puedes contactarlo por WhatsApp en caso de aceptarlo.`
      : `Un trabajador se interesó en el proyecto "${trabajo.titulo}". Recuerda que puedes contactarlo por WhatsApp en caso de aceptarlo.`;

    const registroNotificacion = await crearNotificacion({
      emailDestino: trabajo.email_contratista,
      titulo: nombreTrabajador
        ? `Trabajador: ${nombreTrabajador}`
        : 'Solicitud de trabajador',
      cuerpo: cuerpoNotificacion,
      tipo: 'solicitud_trabajo',
      data: {
        solicitudId: solicitud.id_solicitud,
        tipoTrabajo,
        idTrabajo,
        tituloTrabajo: trabajo.titulo,
        emailTrabajador,
        nombreTrabajador,
        telefonoTrabajador: trabajador.telefono,
        categoriaTrabajador: trabajador.categoria,
        experienciaTrabajador: trabajador.experiencia,
      },
      expiraEnMinutos: MINUTOS_EXPIRACION_SOLICITUD,
    });

    const tokens = await obtenerTokensUsuario(trabajo.email_contratista);
    await sendPushNotification({
      tokens,
      title: nombreTrabajador
        ? `Trabajador: ${nombreTrabajador}`
        : 'Solicitud de trabajador',
      body: cuerpoNotificacion,
      data: {
        tipo: 'solicitud_trabajo',
        notificacionId: registroNotificacion?.id_notificacion
          ? String(registroNotificacion.id_notificacion)
          : '',
        solicitudId: String(solicitud.id_solicitud),
        tipoTrabajo,
        idTrabajo: String(idTrabajo),
        emailTrabajador,
        telefonoTrabajador: trabajador.telefono ?? '',
        categoriaTrabajador: trabajador.categoria,
        experienciaTrabajador: trabajador.experiencia != null
          ? String(trabajador.experiencia)
          : null,
      },
    });

    return res.status(200).json({
      success: true,
      message: 'Solicitud enviada correctamente',
      data: {
        solicitudId: solicitud.id_solicitud,
        expiraEn: solicitud.expira_en,
      },
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    handleDatabaseError(error, res, 'Error al registrar solicitud');
  } finally {
    client.release();
  }
};

export const obtenerNumeroSolicitudesActivas = async (req, res) => {
  try {
    const { emailTrabajador } = req.query;

    if (!emailTrabajador) {
      return handleValidationError(res, 'emailTrabajador es requerido');
    }

    await expirarSolicitudesPendientes();

    const result = await query(
      `SELECT COUNT(*) as total
         FROM solicitudes_trabajo
        WHERE email_trabajador = $1
          AND estado = 'pendiente'`,
      [emailTrabajador]
    );

    const totalSolicitudes = parseInt(result.rows[0].total || '0', 10);

    res.json({
      success: true,
      totalSolicitudes,
      puedeAplicar: totalSolicitudes < 3,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener número de solicitudes');
  }
};

export const obtenerSolicitudesActivasTrabajador = async (req, res) => {
  try {
    const { emailTrabajador } = req.query;

    if (!emailTrabajador) {
      return handleValidationError(res, 'emailTrabajador es requerido');
    }

    await expirarSolicitudesPendientes();

    const result = await query(
      `SELECT tipo_trabajo, id_trabajo
         FROM solicitudes_trabajo
        WHERE email_trabajador = $1
          AND estado = 'pendiente'`,
      [emailTrabajador]
    );

    // Crear un mapa de trabajos a los que ya aplicó
    const trabajosAplicados = result.rows.map((row) => ({
      tipoTrabajo: row.tipo_trabajo,
      idTrabajo: row.id_trabajo,
    }));

    res.json({
      success: true,
      trabajosAplicados,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener solicitudes activas');
  }
};

export const obtenerSolicitudPendiente = async (req, res) => {
  const { emailTrabajador } = req.query;

  if (!emailTrabajador) {
    return handleValidationError(res, 'emailTrabajador es requerido');
  }

  await expirarSolicitudesPendientes();

  const solicitud = await obtenerSolicitudPendienteTrabajador(emailTrabajador);

  return res.status(200).json({
    success: true,
    data: solicitud,
  });
};


