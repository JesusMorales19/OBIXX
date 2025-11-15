import { getClient, query } from '../config/db.js';
import {
  obtenerTokensUsuario,
  crearNotificacion,
  notificarCalificacionTrabajador,
  notificarInteresContratista,
  notificarCancelacionTrabajador,
} from '../services/notificationService.js';
import { sendPushNotification } from '../services/firebaseService.js';
import { handleDatabaseError, handleError, handleValidationError } from '../services/errorHandler.js';

const ESTADOS_VALIDOS = {
  trabajo: ['corto', 'largo'],
};

export const asignarTrabajo = async (req, res) => {
  const { emailContratista, emailTrabajador, tipoTrabajo, idTrabajo, idSolicitud } = req.body;

  if (!emailContratista || !emailTrabajador || !tipoTrabajo || !idTrabajo) {
    return handleValidationError(res, 'Faltan campos requeridos');
  }

  if (!ESTADOS_VALIDOS.trabajo.includes(tipoTrabajo)) {
    return handleValidationError(res, 'Tipo de trabajo inválido');
  }

  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Verificar trabajador
    const trabajadorResult = await client.query(
      'SELECT nombre, apellido, disponible FROM trabajadores WHERE email = $1 FOR UPDATE',
      [emailTrabajador]
    );

    if (trabajadorResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Trabajador no encontrado', 404);
    }

    if (!idSolicitud && !trabajadorResult.rows[0].disponible) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'El trabajador ya está asignado');
    }

    let solicitudPendiente = null;
    if (idSolicitud) {
      const solicitudResult = await client.query(
        `SELECT id_solicitud, email_contratista, tipo_trabajo, id_trabajo, estado
           FROM solicitudes_trabajo
          WHERE id_solicitud = $1
            AND email_trabajador = $2
          FOR UPDATE`,
        [idSolicitud, emailTrabajador]
      );

      if (solicitudResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'La solicitud asociada no existe', 404);
      }

      solicitudPendiente = solicitudResult.rows[0];

      if (solicitudPendiente.estado !== 'pendiente') {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'La solicitud ya fue procesada');
      }

      if (
        solicitudPendiente.email_contratista !== emailContratista ||
        solicitudPendiente.tipo_trabajo !== tipoTrabajo ||
        Number(solicitudPendiente.id_trabajo) !== Number(idTrabajo)
      ) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'La solicitud no corresponde a este trabajo');
      }
    }

    // Verificar si ya tiene una asignación activa
    const asignacionExistente = await client.query(
      `SELECT id_asignacion FROM asignaciones_trabajo
       WHERE email_trabajador = $1 AND estado = 'activo'
       FOR UPDATE`,
      [emailTrabajador]
    );

    if (asignacionExistente.rows.length > 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'El trabajador ya tiene un trabajo asignado');
    }

    // Verificar trabajo
    const tablaTrabajo = tipoTrabajo === 'corto' ? 'trabajos_corto_plazo' : 'trabajos_largo_plazo';
    const campoId = tipoTrabajo === 'corto' ? 'id_trabajo_corto' : 'id_trabajo_largo';

    const trabajoResult = await client.query(
      `SELECT email_contratista, vacantes_disponibles, estado, titulo
       FROM ${tablaTrabajo}
       WHERE ${campoId} = $1
       FOR UPDATE`,
      [idTrabajo]
    );

    if (trabajoResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Trabajo no encontrado', 404);
    }

    const trabajo = trabajoResult.rows[0];
    if (trabajo.email_contratista !== emailContratista) {
      await client.query('ROLLBACK');
      return res.status(403).json({ success: false, error: 'El trabajo no pertenece al contratista' });
    }

    if (Number(trabajo.vacantes_disponibles) <= 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'El trabajo no tiene vacantes disponibles');
    }

    const contratistaInfo = await client.query(
      'SELECT nombre, apellido FROM contratistas WHERE email = $1',
      [emailContratista]
    );

    const nombreContratista = `${contratistaInfo.rows[0]?.nombre ?? ''} ${contratistaInfo.rows[0]?.apellido ?? ''}`.trim();

    // Insertar asignación
    const asignacionResult = await client.query(
      `INSERT INTO asignaciones_trabajo (email_contratista, email_trabajador, tipo_trabajo, id_trabajo)
       VALUES ($1, $2, $3, $4)
       RETURNING id_asignacion, fecha_asignacion` ,
      [emailContratista, emailTrabajador, tipoTrabajo, idTrabajo]
    );

    // Actualizar vacantes
    const updateTrabajoResult = await client.query(
      `UPDATE ${tablaTrabajo}
       SET vacantes_disponibles = vacantes_disponibles - 1,
           estado = CASE WHEN vacantes_disponibles - 1 <= 0 THEN 'pausado' ELSE estado END
       WHERE ${campoId} = $1
       RETURNING vacantes_disponibles, estado`,
      [idTrabajo]
    );

    const vacantesRestantes = updateTrabajoResult.rows[0].vacantes_disponibles;
    const estadoTrabajo = updateTrabajoResult.rows[0].estado;

    // Actualizar trabajador a no disponible
    await client.query(
      'UPDATE trabajadores SET disponible = false WHERE email = $1',
      [emailTrabajador]
    );

    if (idSolicitud) {
      await client.query(
        `UPDATE solicitudes_trabajo
            SET estado = 'aceptada',
                respondido_en = CURRENT_TIMESTAMP
          WHERE id_solicitud = $1`,
        [idSolicitud]
      );
    }

    await client.query('COMMIT');

    if (idSolicitud) {
      try {
        await query(
          `DELETE FROM notificaciones_usuario
              WHERE data_json->>'solicitudId' = $1`,
          [String(idSolicitud)]
        );
      } catch (cleanupError) {
        console.error('Error al limpiar notificación de solicitud aceptada:', cleanupError);
      }
    }

    if (idSolicitud) {
      try {
        const nombreContratistaUpper = nombreContratista
          ? nombreContratista.toUpperCase()
          : 'TU CONTRATISTA';
        const tituloNotificacion = `Contratista: ${nombreContratistaUpper}`;
        const cuerpoNotificacion =
          `Aceptó tu solicitud para el proyecto "${trabajo.titulo}". ` +
          'Mantente al tanto de tu WhatsApp, por ahí te contactará.';

        const registro = await crearNotificacion({
          emailDestino: emailTrabajador,
          titulo: tituloNotificacion,
          cuerpo: cuerpoNotificacion,
          tipo: 'solicitud_aceptada',
          data: {
            tipo: 'solicitud_aceptada',
            tipoTrabajo,
            idTrabajo,
            tituloTrabajo: trabajo.titulo,
            idAsignacion: asignacionResult.rows[0].id_asignacion,
            nombreContratista,
          },
        });

        const tokens = await obtenerTokensUsuario(emailTrabajador);
        await sendPushNotification({
          tokens,
          title: tituloNotificacion,
          body: cuerpoNotificacion,
          data: {
            tipo: 'solicitud_aceptada',
            notificacionId: registro?.id_notificacion ? String(registro.id_notificacion) : '',
            tipoTrabajo,
            idTrabajo: String(idTrabajo),
          },
        });
      } catch (notifyError) {
        console.error('Error al generar la notificación de asignación:', notifyError);
      }
    } else {
      try {
        const datosTrabajador = trabajadorResult.rows[0] || {};
        await notificarInteresContratista({
          emailTrabajador,
          nombreTrabajador: `${datosTrabajador.nombre ?? ''} ${datosTrabajador.apellido ?? ''}`.trim(),
          emailContratista,
          nombreContratista,
          tituloTrabajo: trabajo.titulo,
        });
      } catch (notifyError) {
        console.error('Error al generar la notificación de interés tras contratación directa:', notifyError);
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Trabajador asignado exitosamente',
      data: {
        idAsignacion: asignacionResult.rows[0].id_asignacion,
        fechaAsignacion: asignacionResult.rows[0].fecha_asignacion,
        vacantesRestantes,
        estadoTrabajo,
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    handleError(error, res, 'Error interno del servidor');
  } finally {
    client.release();
  }
};

export const cancelarAsignacion = async (req, res) => {
  const {
    emailContratista,
    emailTrabajador,
    iniciadoPorTrabajador,
    skipDefaultNotification = false,
  } = req.body;

  if (!emailContratista || !emailTrabajador) {
    return handleValidationError(res, 'Faltan campos requeridos');
  }

  const client = await getClient();

  let datosNotificacion = null;
  let responsePayload = null;
  let datosTrabajador = null;
  const canceladoPorTrabajador =
    iniciadoPorTrabajador === true ||
    iniciadoPorTrabajador === 1 ||
    iniciadoPorTrabajador === '1' ||
    (typeof iniciadoPorTrabajador === 'string' &&
      iniciadoPorTrabajador.toLowerCase() === 'true');

  try {
    await client.query('BEGIN');

    const trabajadorResult = await client.query(
      'SELECT nombre, apellido FROM trabajadores WHERE email = $1 FOR UPDATE',
      [emailTrabajador]
    );

    if (trabajadorResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Trabajador no encontrado', 404);
    }

    datosTrabajador = trabajadorResult.rows[0];

    const contratistaResult = await client.query(
      'SELECT nombre, apellido FROM contratistas WHERE email = $1',
      [emailContratista]
    );
    const nombreContratista = `${contratistaResult.rows[0]?.nombre ?? ''} ${contratistaResult.rows[0]?.apellido ?? ''}`.trim();

    const asignacionResult = await client.query(
      `SELECT id_asignacion, tipo_trabajo, id_trabajo
       FROM asignaciones_trabajo
       WHERE email_contratista = $1 AND email_trabajador = $2 AND estado = 'activo'
       FOR UPDATE`,
      [emailContratista, emailTrabajador]
    );

    if (asignacionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'No existe una asignación activa para este trabajador', 404);
    }

    const asignacion = asignacionResult.rows[0];
    const tablaTrabajo = asignacion.tipo_trabajo === 'corto' ? 'trabajos_corto_plazo' : 'trabajos_largo_plazo';
    const campoId = asignacion.tipo_trabajo === 'corto' ? 'id_trabajo_corto' : 'id_trabajo_largo';

    const trabajoInfoResult = await client.query(
      `SELECT titulo
         FROM ${tablaTrabajo}
        WHERE ${campoId} = $1`,
      [asignacion.id_trabajo]
    );

    const tituloTrabajo = trabajoInfoResult.rows[0]?.titulo || 'Trabajo';

    await client.query(
      `UPDATE asignaciones_trabajo
       SET estado = 'cancelado', fecha_cancelacion = CURRENT_TIMESTAMP
       WHERE id_asignacion = $1`,
      [asignacion.id_asignacion]
    );

    const updateTrabajoResult = await client.query(
      `UPDATE ${tablaTrabajo}
       SET vacantes_disponibles = vacantes_disponibles + 1,
           estado = CASE WHEN vacantes_disponibles + 1 > 0 THEN 'activo' ELSE estado END
       WHERE ${campoId} = $1
       RETURNING vacantes_disponibles, estado`,
      [asignacion.id_trabajo]
    );

    await client.query(
      'UPDATE trabajadores SET disponible = true WHERE email = $1',
      [emailTrabajador]
    );

    await client.query('COMMIT');

    datosNotificacion = {
      emailTrabajador,
      nombreTrabajador: `${datosTrabajador.nombre ?? ''} ${datosTrabajador.apellido ?? ''}`.trim(),
      nombreContratista,
      tituloTrabajo,
      idAsignacion: asignacion.id_asignacion,
      tipoTrabajo: asignacion.tipo_trabajo,
    };

    responsePayload = {
      success: true,
      message: 'Asignación cancelada correctamente',
      data: {
        vacantesRestantes: updateTrabajoResult.rows[0].vacantes_disponibles,
        estadoTrabajo: updateTrabajoResult.rows[0].estado,
        tipoTrabajo: asignacion.tipo_trabajo,
        idTrabajo: asignacion.id_trabajo,
      },
    };
  } catch (error) {
    await client.query('ROLLBACK');
    handleError(error, res, 'Error interno del servidor');
  } finally {
    client.release();
  }

  if (datosNotificacion && !skipDefaultNotification) {
    if (canceladoPorTrabajador) {
      try {
        const nombreContratistaUpper = datosNotificacion.nombreContratista
          ? datosNotificacion.nombreContratista.toUpperCase()
          : 'CONTRATISTA';
        const titulo = `Contratista: ${nombreContratistaUpper}`;
        const nombreContratistaTexto =
          datosNotificacion.nombreContratista && datosNotificacion.nombreContratista.trim().length > 0
            ? datosNotificacion.nombreContratista
            : 'El contratista';
        const mensajeBase =
          `${nombreContratistaTexto} ha cancelado la contratación. ` +
          'Ahora estás disponible hacia más proyectos y distintos contratistas.';

        const registro = await crearNotificacion({
          emailDestino: datosNotificacion.emailTrabajador,
          titulo,
          cuerpo: mensajeBase,
          tipo: 'desvinculacion',
          data: {
            tipo: 'desvinculacion',
            tituloTrabajo: datosNotificacion.tituloTrabajo,
            nombreContratista: datosNotificacion.nombreContratista,
          },
          imagen: process.env.NOTIFICATIONS_IMAGE_URL || null,
          expiraEnMinutos: Number(process.env.NOTIFICATION_EXPIRATION_MINUTES || 60),
        });

        const tokens = await obtenerTokensUsuario(datosNotificacion.emailTrabajador);
        if (Array.isArray(tokens) && tokens.length > 0) {
          await sendPushNotification({
            tokens,
            title: titulo,
            body: mensajeBase,
            data: {
              tipo: 'desvinculacion',
              notificacionId: registro?.id_notificacion ? String(registro.id_notificacion) : '',
              tituloTrabajo: datosNotificacion.tituloTrabajo,
              nombreContratista: datosNotificacion.nombreContratista,
            },
            image: process.env.NOTIFICATIONS_IMAGE_URL || undefined,
          });
        }
      } catch (error) {
        console.error('Error al enviar notificación de desvinculación:', error);
      }
    }
  }

  if (datosNotificacion && canceladoPorTrabajador) {
    try {
      await notificarCancelacionTrabajador({
        emailContratista,
        emailTrabajador: datosNotificacion.emailTrabajador,
        nombreTrabajador: datosNotificacion.nombreTrabajador,
        tituloTrabajo: datosNotificacion.tituloTrabajo,
        idAsignacion: datosNotificacion.idAsignacion,
        tipoTrabajo: datosNotificacion.tipoTrabajo,
      });
    } catch (error) {
      console.error('Error al notificar cancelación del trabajador con skipDefaultNotification:', error);
    }
  }

  if (responsePayload) {
    return res.status(200).json(responsePayload);
  }

  return handleError(new Error('Error al procesar cancelación'), res, 'No se pudo procesar la cancelación de la asignación');
};

export const obtenerTrabajadoresPorTrabajo = async (req, res) => {
  try {
    const { emailContratista, tipoTrabajo, idTrabajo } = req.query;

    if (!emailContratista || !tipoTrabajo || !idTrabajo) {
      return handleValidationError(res, 'Faltan parámetros requeridos');
    }

    if (!ESTADOS_VALIDOS.trabajo.includes(tipoTrabajo)) {
      return handleValidationError(res, 'Tipo de trabajo inválido');
    }

    const idTrabajoNumber = Number(idTrabajo);
    if (Number.isNaN(idTrabajoNumber)) {
      return handleValidationError(res, 'El id del trabajo no es válido');
    }

    const tablaTrabajo =
      tipoTrabajo === 'corto' ? 'trabajos_corto_plazo' : 'trabajos_largo_plazo';
    const campoId =
      tipoTrabajo === 'corto' ? 'id_trabajo_corto' : 'id_trabajo_largo';

    const trabajoResult = await query(
      `SELECT email_contratista
       FROM ${tablaTrabajo}
       WHERE ${campoId} = $1`,
      [idTrabajoNumber]
    );

    if (trabajoResult.rows.length === 0) {
      return handleValidationError(res, 'Trabajo no encontrado', 404);
    }

    if (trabajoResult.rows[0].email_contratista !== emailContratista) {
      return res.status(403).json({
        success: false,
        error: 'El trabajo no pertenece al contratista indicado',
      });
    }

    const asignacionesResult = await query(
      `SELECT 
         at.id_asignacion,
         at.email_trabajador,
         at.fecha_asignacion,
         at.estado,
         t.nombre,
         t.apellido,
         t.telefono,
         t.disponible,
         t.experiencia,
         t.calificacion_promedio,
         t.foto_perfil,
         c.nombre AS categoria,
         CASE WHEN f.email_trabajador IS NOT NULL THEN TRUE ELSE FALSE END AS es_favorito
       FROM asignaciones_trabajo at
       INNER JOIN trabajadores t ON at.email_trabajador = t.email
       LEFT JOIN categorias c ON t.categoria = c.id_categoria
       LEFT JOIN favoritos f 
         ON f.email_trabajador = t.email 
        AND f.email_contratista = $3
       WHERE at.tipo_trabajo = $1
         AND at.id_trabajo = $2
         AND at.estado = 'activo'
       ORDER BY at.fecha_asignacion DESC`,
      [tipoTrabajo, idTrabajoNumber, emailContratista]
    );

    return res.status(200).json({
      success: true,
      total: asignacionesResult.rows.length,
      trabajadores: asignacionesResult.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error interno del servidor');
  }
};

export const obtenerTrabajoActualTrabajador = async (req, res) => {
  try {
    const { emailTrabajador } = req.query;

    if (!emailTrabajador) {
      return handleValidationError(res, 'Falta el email del trabajador');
    }

    const asignacionResult = await query(
      `SELECT 
         id_asignacion,
         email_contratista,
         tipo_trabajo,
         id_trabajo,
         fecha_asignacion
       FROM asignaciones_trabajo
       WHERE email_trabajador = $1
         AND estado = 'activo'
       ORDER BY fecha_asignacion DESC
       LIMIT 1`,
      [emailTrabajador]
    );

    if (asignacionResult.rows.length === 0) {
      return res.status(200).json({
        success: true,
        data: null,
      });
    }

    const asignacion = asignacionResult.rows[0];
    const tipoTrabajo = asignacion.tipo_trabajo;
    const idTrabajo = Number(asignacion.id_trabajo);

    let trabajo = null;

    if (tipoTrabajo === 'corto') {
      const trabajoResult = await query(
        `SELECT 
           tcp.id_trabajo_corto,
           tcp.titulo,
           tcp.descripcion,
           tcp.rango_pago,
           tcp.disponibilidad,
           tcp.especialidad,
           tcp.latitud,
           tcp.longitud,
           tcp.direccion,
           tcp.created_at,
           c.nombre AS nombre_contratista,
           c.apellido AS apellido_contratista,
           c.email AS email_contratista,
           c.telefono AS telefono_contratista,
           c.foto_perfil AS foto_contratista
         FROM trabajos_corto_plazo tcp
         INNER JOIN contratistas c ON tcp.email_contratista = c.email
         WHERE tcp.id_trabajo_corto = $1`,
        [idTrabajo]
      );

      if (trabajoResult.rows.length === 0) {
        return handleValidationError(res, 'Trabajo corto plazo no encontrado', 404);
      }

      const row = trabajoResult.rows[0];
      trabajo = {
        idTrabajo: row.id_trabajo_corto,
        titulo: row.titulo,
        descripcion: row.descripcion,
        rangoPago: row.rango_pago,
        disponibilidad: row.disponibilidad,
        especialidad: row.especialidad,
        latitud: row.latitud,
        longitud: row.longitud,
        direccion: row.direccion,
        contratista: {
          nombre: row.nombre_contratista,
          apellido: row.apellido_contratista,
          nombreCompleto: `${row.nombre_contratista ?? ''} ${row.apellido_contratista ?? ''}`.trim(),
          email: row.email_contratista,
          telefono: row.telefono_contratista,
          fotoPerfil: row.foto_contratista,
        },
      };
    } else if (tipoTrabajo === 'largo') {
      const trabajoResult = await query(
        `SELECT 
           tlp.id_trabajo_largo,
           tlp.titulo,
           tlp.descripcion,
           tlp.frecuencia,
           tlp.tipo_obra,
           tlp.fecha_fin,
           tlp.latitud,
           tlp.longitud,
           tlp.direccion,
           c.nombre AS nombre_contratista,
           c.apellido AS apellido_contratista,
           c.email AS email_contratista,
           c.telefono AS telefono_contratista,
           c.foto_perfil AS foto_contratista
         FROM trabajos_largo_plazo tlp
         INNER JOIN contratistas c ON tlp.email_contratista = c.email
         WHERE tlp.id_trabajo_largo = $1`,
        [idTrabajo]
      );

      if (trabajoResult.rows.length === 0) {
        return handleValidationError(res, 'Trabajo largo plazo no encontrado', 404);
      }

      const row = trabajoResult.rows[0];
      trabajo = {
        idTrabajo: row.id_trabajo_largo,
        titulo: row.titulo,
        descripcion: row.descripcion,
        frecuencia: row.frecuencia,
        tipoObra: row.tipo_obra,
        fechaFin: row.fecha_fin,
        latitud: row.latitud,
        longitud: row.longitud,
        direccion: row.direccion,
        contratista: {
          nombre: row.nombre_contratista,
          apellido: row.apellido_contratista,
          nombreCompleto: `${row.nombre_contratista ?? ''} ${row.apellido_contratista ?? ''}`.trim(),
          email: row.email_contratista,
          telefono: row.telefono_contratista,
          fotoPerfil: row.foto_contratista,
        },
      };
    } else {
      return handleValidationError(res, 'Tipo de trabajo desconocido');
    }

    const trabajadorResult = await query(
      `SELECT 
         nombre,
         apellido,
         calificacion_promedio,
         foto_perfil
       FROM trabajadores
       WHERE email = $1`,
      [emailTrabajador]
    );

    const datosTrabajador = trabajadorResult.rows[0] || {};

    return res.status(200).json({
      success: true,
      data: {
        idAsignacion: asignacion.id_asignacion,
        tipoTrabajo,
        idTrabajo,
        fechaAsignacion: asignacion.fecha_asignacion,
        trabajo,
        contratista: trabajo?.contratista ?? null,
        trabajador: {
          email: emailTrabajador,
          nombre: datosTrabajador.nombre,
          apellido: datosTrabajador.apellido,
          nombreCompleto: `${datosTrabajador.nombre ?? ''} ${datosTrabajador.apellido ?? ''}`.trim(),
          calificacionPromedio: datosTrabajador.calificacion_promedio,
          fotoPerfil: datosTrabajador.foto_perfil,
        },
      },
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error interno del servidor');
  }
};

export const finalizarTrabajo = async (req, res) => {
  const { emailContratista, tipoTrabajo, idTrabajo, calificaciones } = req.body;

  if (
    !emailContratista ||
    !tipoTrabajo ||
    !idTrabajo ||
    !Array.isArray(calificaciones) ||
    calificaciones.length === 0
  ) {
    return handleValidationError(res, 'Faltan parámetros requeridos o no hay calificaciones proporcionadas');
  }

  if (!ESTADOS_VALIDOS.trabajo.includes(tipoTrabajo)) {
    return handleValidationError(res, 'Tipo de trabajo inválido');
  }

  const idTrabajoNumber = Number(idTrabajo);
  if (Number.isNaN(idTrabajoNumber) || idTrabajoNumber <= 0) {
    return handleValidationError(res, 'El id del trabajo no es válido');
  }

  const tablaTrabajo =
    tipoTrabajo === 'corto' ? 'trabajos_corto_plazo' : 'trabajos_largo_plazo';
  const campoId =
    tipoTrabajo === 'corto' ? 'id_trabajo_corto' : 'id_trabajo_largo';

  const client = await getClient();
  let nombreContratista = '';
  let tituloTrabajo = 'Trabajo';

  try {
    await client.query('BEGIN');

    const trabajoResult = await client.query(
      `SELECT email_contratista, titulo
       FROM ${tablaTrabajo}
       WHERE ${campoId} = $1
       FOR UPDATE`,
      [idTrabajoNumber]
    );

    if (trabajoResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Trabajo no encontrado', 404);
    }

    if (trabajoResult.rows[0].email_contratista !== emailContratista) {
      await client.query('ROLLBACK');
      return res.status(403).json({
        success: false,
        error: 'El trabajo no pertenece al contratista indicado',
      });
    }

    const tituloEncontrado = trabajoResult.rows[0]?.titulo;
    if (tituloEncontrado && tituloEncontrado.trim().length > 0) {
      tituloTrabajo = tituloEncontrado.trim();
    }

    const contratistaInfo = await client.query(
      'SELECT nombre, apellido FROM contratistas WHERE email = $1',
      [emailContratista]
    );
    nombreContratista = `${contratistaInfo.rows[0]?.nombre ?? ''} ${contratistaInfo.rows[0]?.apellido ?? ''}`.trim();

    const trabajadoresActualizados = [];

    for (const rawItem of calificaciones) {
      const {
        idAsignacion,
        emailTrabajador,
        estrellas,
        resena = null,
      } = rawItem || {};

      if (!idAsignacion || !emailTrabajador || estrellas === undefined) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'Cada calificación debe incluir idAsignacion, emailTrabajador y estrellas');
      }

      const idAsignacionNumber = Number(idAsignacion);
      const estrellasNumber = Number(estrellas);

      if (
        Number.isNaN(idAsignacionNumber) ||
        idAsignacionNumber <= 0 ||
        Number.isNaN(estrellasNumber) ||
        estrellasNumber < 1 ||
        estrellasNumber > 5
      ) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'Los datos de la calificación no son válidos');
      }

      const asignacionResult = await client.query(
        `SELECT email_contratista, email_trabajador
         FROM asignaciones_trabajo
         WHERE id_asignacion = $1
           AND tipo_trabajo = $2
           AND id_trabajo = $3`,
        [idAsignacionNumber, tipoTrabajo, idTrabajoNumber]
      );

      if (asignacionResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'La asignación indicada no existe para este trabajo', 404);
      }

      const asignacion = asignacionResult.rows[0];
      if (
        asignacion.email_contratista !== emailContratista ||
        asignacion.email_trabajador !== emailTrabajador
      ) {
        await client.query('ROLLBACK');
        return res.status(403).json({
          success: false,
          error: 'Los datos de la asignación no coinciden con el contratista o trabajador indicados',
        });
      }

      await client.query(
        `INSERT INTO calificaciones_trabajadores (
           email_contratista,
           email_trabajador,
           id_asignacion,
           estrellas,
           resena
         )
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id_asignacion)
         DO UPDATE
           SET estrellas = EXCLUDED.estrellas,
               resena = EXCLUDED.resena,
               fecha_calificacion = CURRENT_TIMESTAMP`,
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

      const promedioRow = promedioResult.rows[0];
      const promedioCalculado =
        promedioRow && promedioRow.promedio !== null
          ? Number(promedioRow.promedio)
          : estrellasNumber;

      await client.query(
        `UPDATE trabajadores
         SET calificacion_promedio = $1,
             disponible = true
         WHERE email = $2`,
        [promedioCalculado, emailTrabajador]
      );

      await client.query(
        `UPDATE asignaciones_trabajo
         SET estado = 'finalizado',
             fecha_cancelacion = CURRENT_TIMESTAMP
         WHERE id_asignacion = $1`,
        [idAsignacionNumber]
      );

      trabajadoresActualizados.push({
        emailTrabajador,
        promedio: promedioCalculado,
        estrellas: estrellasNumber,
      });
    }

    await client.query(
      `UPDATE ${tablaTrabajo}
       SET estado = 'completado',
           vacantes_disponibles = 0
       WHERE ${campoId} = $1`,
      [idTrabajoNumber]
    );

    await client.query('COMMIT');

    await Promise.all(
      trabajadoresActualizados.map(({ emailTrabajador, estrellas }) =>
        notificarCalificacionTrabajador({
          emailTrabajador,
          nombreContratista,
          emailContratista,
          estrellas,
          tituloTrabajo,
          contexto: 'finalizado',
        })
      )
    );

    return res.status(200).json({
      success: true,
      message: 'Trabajo finalizado correctamente',
      data: {
        trabajadoresActualizados,
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    handleError(error, res, 'Error interno del servidor');
  } finally {
    client.release();
  }
};

export const obtenerAsignacionesContratista = async (req, res) => {
  try {
    const { emailContratista } = req.query;
    if (!emailContratista) {
      return handleValidationError(res, 'Email del contratista es requerido');
    }

    const result = await query(
      `SELECT id_asignacion, email_trabajador, tipo_trabajo, id_trabajo, estado, fecha_asignacion
       FROM asignaciones_trabajo
       WHERE email_contratista = $1`,
      [emailContratista]
    );

    return res.status(200).json({
      success: true,
      asignaciones: result.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error interno del servidor');
  }
};
