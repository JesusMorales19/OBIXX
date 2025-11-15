import { query } from '../config/db.js';
import { crearNotificacion, obtenerTokensUsuario } from './notificationService.js';
import { sendPushNotification } from './firebaseService.js';

const ESTADO_PENDIENTE = 'pendiente';
const ESTADO_RECHAZADA = 'rechazada';
const ESTADO_EXPIRADA = 'expirada';

const limpiarNotificacionesPorSolicitudes = async (ids) => {
  if (!Array.isArray(ids) || ids.length === 0) {
    return;
  }

  await query(
    `DELETE FROM notificaciones_usuario
      WHERE data_json->>'solicitudId' = ANY($1::text[])`,
    [ids.map((id) => String(id))]
  );
};

const obtenerInfoTrabajo = async ({ tipoTrabajo, idTrabajo }) => {
  if (!tipoTrabajo || !idTrabajo) {
    return null;
  }

  if (tipoTrabajo === 'corto') {
    const result = await query(
      `SELECT titulo, email_contratista
         FROM trabajos_corto_plazo
        WHERE id_trabajo_corto = $1`,
      [idTrabajo]
    );
    return result.rows[0] ?? null;
  }

  const result = await query(
    `SELECT titulo, email_contratista
       FROM trabajos_largo_plazo
      WHERE id_trabajo_largo = $1`,
    [idTrabajo]
  );
  return result.rows[0] ?? null;
};

const obtenerNombreContratista = async (emailContratista) => {
  if (!emailContratista) return '';
  const result = await query(
    `SELECT nombre, apellido
       FROM contratistas
      WHERE email = $1`,
    [emailContratista]
  );

  if (result.rows.length === 0) return '';
  const { nombre, apellido } = result.rows[0];
  return [nombre, apellido]
    .map((parte) => (parte || '').trim())
    .filter((parte) => parte.length > 0)
    .join(' ');
};

const enviarNotificacionRechazo = async ({
  emailTrabajador,
  solicitudId,
  tipoTrabajo,
  idTrabajo,
}) => {
  const infoTrabajo = await obtenerInfoTrabajo({ tipoTrabajo, idTrabajo });
  if (!infoTrabajo) return;

  const nombreContratista = await obtenerNombreContratista(infoTrabajo.email_contratista);
  const titulo = nombreContratista
    ? `Contratista: ${nombreContratista.toUpperCase()}`
    : 'Contratista';
  const cuerpo =
    `Ha rechazado/cancelado la solicitud hacia el proyecto "${infoTrabajo.titulo}". ` +
    'Ahora estás disponible para más proyectos y distintos contratistas.';

  const registro = await crearNotificacion({
    emailDestino: emailTrabajador,
    titulo,
    cuerpo,
    tipo: 'solicitud_actualizada',
    data: {
      tipo: 'solicitud_actualizada',
      solicitudId,
      tituloTrabajo: infoTrabajo.titulo,
      nombreContratista,
    },
  });

  const tokens = await obtenerTokensUsuario(emailTrabajador);
  if (!tokens || tokens.length === 0) return;

  await sendPushNotification({
    tokens,
    title: titulo,
    body: cuerpo,
    data: {
      tipo: 'solicitud_actualizada',
      notificacionId: registro?.id_notificacion ? String(registro.id_notificacion) : '',
      solicitudId: String(solicitudId),
      tipoTrabajo,
      idTrabajo: String(idTrabajo),
    },
  });
};

export const expirarSolicitudesPendientes = async () => {
  const expirarResult = await query(
    `UPDATE solicitudes_trabajo
        SET estado = $1,
            respondido_en = CURRENT_TIMESTAMP
      WHERE estado = $2
        AND expira_en <= CURRENT_TIMESTAMP
      RETURNING id_solicitud,
                email_trabajador,
                tipo_trabajo,
                id_trabajo`,
    [ESTADO_EXPIRADA, ESTADO_PENDIENTE]
  );

  if (expirarResult.rows.length === 0) {
    return;
  }

  const trabajadores = expirarResult.rows.map((row) => row.email_trabajador);
  const solicitudesIds = expirarResult.rows.map((row) => row.id_solicitud);

  // Actualizar disponibilidad: solo si tienen menos de 3 solicitudes pendientes
  for (const emailTrabajador of trabajadores) {
    const solicitudesActivas = await query(
      `SELECT COUNT(*) as total
         FROM solicitudes_trabajo
        WHERE email_trabajador = $1
          AND estado = 'pendiente'`,
      [emailTrabajador]
    );
    
    const totalSolicitudes = parseInt(solicitudesActivas.rows[0].total || '0', 10);
    
    // Solo marcar como disponible si tiene menos de 3 solicitudes activas
    // y no tiene una asignación activa
    const asignacionActiva = await query(
      `SELECT 1
         FROM asignaciones_trabajo
        WHERE email_trabajador = $1
          AND estado = 'activo'
        LIMIT 1`,
      [emailTrabajador]
    );
    
    if (totalSolicitudes < 3 && asignacionActiva.rows.length === 0) {
      await query(
        `UPDATE trabajadores
            SET disponible = TRUE
          WHERE email = $1`,
        [emailTrabajador]
      );
    }
  }

  await limpiarNotificacionesPorSolicitudes(solicitudesIds);

  await Promise.all(
    expirarResult.rows.map((row) =>
      enviarNotificacionRechazo({
        emailTrabajador: row.email_trabajador,
        solicitudId: row.id_solicitud,
        tipoTrabajo: row.tipo_trabajo,
        idTrabajo: row.id_trabajo,
      })
    )
  );
};

export const obtenerSolicitudPendienteTrabajador = async (emailTrabajador) => {
  const result = await query(
    `SELECT id_solicitud,
            email_contratista,
            tipo_trabajo,
            id_trabajo,
            expira_en
       FROM solicitudes_trabajo
      WHERE email_trabajador = $1
        AND estado = $2`,
    [emailTrabajador, ESTADO_PENDIENTE]
  );

  return result.rows[0] ?? null;
};

export const marcarSolicitudesComoRechazadas = async ({ ids }) => {
  if (!Array.isArray(ids) || ids.length === 0) {
    return [];
  }

  const result = await query(
    `UPDATE solicitudes_trabajo
        SET estado = $1,
            respondido_en = CURRENT_TIMESTAMP
      WHERE id_solicitud = ANY($2::int[])
        AND estado = $3
      RETURNING id_solicitud,
                email_trabajador,
                tipo_trabajo,
                id_trabajo`,
    [ESTADO_RECHAZADA, ids, ESTADO_PENDIENTE]
  );

  if (result.rows.length === 0) {
    return [];
  }

  await limpiarNotificacionesPorSolicitudes(result.rows.map((row) => row.id_solicitud));

  const trabajadores = result.rows.map((row) => row.email_trabajador);

  // Actualizar disponibilidad: solo si tienen menos de 3 solicitudes pendientes
  for (const emailTrabajador of trabajadores) {
    const solicitudesActivas = await query(
      `SELECT COUNT(*) as total
         FROM solicitudes_trabajo
        WHERE email_trabajador = $1
          AND estado = 'pendiente'`,
      [emailTrabajador]
    );
    
    const totalSolicitudes = parseInt(solicitudesActivas.rows[0].total || '0', 10);
    
    // Solo marcar como disponible si tiene menos de 3 solicitudes activas
    // y no tiene una asignación activa
    const asignacionActiva = await query(
      `SELECT 1
         FROM asignaciones_trabajo
        WHERE email_trabajador = $1
          AND estado = 'activo'
        LIMIT 1`,
      [emailTrabajador]
    );
    
    if (totalSolicitudes < 3 && asignacionActiva.rows.length === 0) {
      await query(
        `UPDATE trabajadores
            SET disponible = TRUE
          WHERE email = $1`,
        [emailTrabajador]
      );
    }
  }

  await Promise.all(
    result.rows.map((row) =>
      enviarNotificacionRechazo({
        emailTrabajador: row.email_trabajador,
        solicitudId: row.id_solicitud,
        tipoTrabajo: row.tipo_trabajo,
        idTrabajo: row.id_trabajo,
      })
    )
  );

  return result.rows;
};

